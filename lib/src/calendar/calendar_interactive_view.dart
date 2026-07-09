import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'calendar_controller.dart';
import 'calendar_models.dart';
import 'calendar_view.dart';
import 'date_utils_ext.dart';

typedef CalendarInteractiveContentBuilder =
    Widget Function(
      BuildContext context,
      ScrollController scrollController,
      ScrollPhysics physics,
    );

class CalendarInteractiveController extends ChangeNotifier {
  CalendarInteractiveController({
    CalendarPageOrientation pageOrientation =
        CalendarPageOrientation.horizontal,
  }) : _pageOrientation = pageOrientation;

  _CalendarInteractiveActions? _actions;
  CalendarPageOrientation _pageOrientation;
  CalendarDisplayMode _displayMode = CalendarDisplayMode.month;
  double _collapseProgress = 0;
  bool _isFullScreenExpanded = false;

  CalendarPageOrientation get pageOrientation => _pageOrientation;
  CalendarDisplayMode get displayMode => _displayMode;
  double get collapseProgress => _collapseProgress;
  bool get isFullScreenExpanded => _isFullScreenExpanded;
  bool get isCollapsed =>
      _displayMode == CalendarDisplayMode.week || _collapseProgress >= 0.9999;
  bool get isExpanded => !isCollapsed;

  void setPageOrientation(CalendarPageOrientation orientation) {
    if (_pageOrientation == orientation) {
      return;
    }
    _pageOrientation = orientation;
    notifyListeners();
  }

  void togglePageOrientation() {
    setPageOrientation(
      _pageOrientation == CalendarPageOrientation.horizontal
          ? CalendarPageOrientation.vertical
          : CalendarPageOrientation.horizontal,
    );
  }

  void expand() {
    _actions?.expand.call();
  }

  void collapse() {
    _actions?.collapse.call();
  }

  void shrink() {
    collapse();
  }

  void toggleFullScreen() {
    _actions?.toggleFullScreen.call();
  }

  void _attach(_CalendarInteractiveActions actions) {
    _actions = actions;
  }

  void _detach() {
    _actions = null;
  }

  void _syncState({
    required CalendarPageOrientation pageOrientation,
    required CalendarDisplayMode displayMode,
    required double collapseProgress,
    required bool isFullScreenExpanded,
  }) {
    var changed = false;
    if (_pageOrientation != pageOrientation) {
      _pageOrientation = pageOrientation;
      changed = true;
    }
    if (_displayMode != displayMode) {
      _displayMode = displayMode;
      changed = true;
    }
    if ((_collapseProgress - collapseProgress).abs() >= 0.0001) {
      _collapseProgress = collapseProgress;
      changed = true;
    }
    if (_isFullScreenExpanded != isFullScreenExpanded) {
      _isFullScreenExpanded = isFullScreenExpanded;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}

class _CalendarInteractiveActions {
  const _CalendarInteractiveActions({
    required this.toggleFullScreen,
    required this.expand,
    required this.collapse,
  });

  final VoidCallback toggleFullScreen;
  final VoidCallback expand;
  final VoidCallback collapse;
}

class CalendarInteractiveView extends StatefulWidget {
  const CalendarInteractiveView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    required this.contentBuilder,
    this.onFocusedDayChanged,
    this.interactionController,
    this.pageOrientation,
    this.yearMode = false,
    this.calendarHeight = 62,
    this.weekBarHeight = 46,
    this.monthHeaderHeight = 60,
  });

  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onFocusedDayChanged;
  final CalendarInteractiveContentBuilder contentBuilder;
  final CalendarInteractiveController? interactionController;
  final CalendarPageOrientation? pageOrientation;
  final bool yearMode;
  final double calendarHeight;
  final double weekBarHeight;
  final double monthHeaderHeight;

  @override
  State<CalendarInteractiveView> createState() =>
      _CalendarInteractiveViewState();
}

class _CalendarInteractiveViewState extends State<CalendarInteractiveView>
    with TickerProviderStateMixin {
  static const _settleSpring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 24,
  );

  late final AnimationController _settleController;
  late final AnimationController _fullScreenController;
  final ScrollController _listController = ScrollController();
  late CalendarDisplayMode _lastKnownDisplayMode;
  bool _isApplyingDisplayModeInternally = false;

  double _dragAccumulated = 0;
  double _collapsePreviewProgress = 0;
  CalendarDisplayMode? _dragSourceMode;
  bool _isCalendarAreaDragging = false;
  int? _listPointerId;
  double _listPointerStartY = 0;
  bool _isListCollapseDragging = false;
  bool _isListPullExpanding = false;
  bool _isListFullScreenDragging = false;
  bool _isCalendarFullScreenDragging = false;
  double? _displayedCalendarHeight;
  double? _monthBodyHeightOverride;
  double _fullScreenDragStartBodyHeight = 0;
  double _calendarViewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _lastKnownDisplayMode = widget.controller.displayMode;
    widget.controller.addListener(_handleCalendarControllerChanged);
    _settleController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: _collapsePreviewProgress,
    )..addListener(() {
      if (!mounted) {
        return;
      }
      final next = _settleController.value.clamp(0.0, 1.0);
      if (next == _collapsePreviewProgress) {
        return;
      }
      setState(() {
        _collapsePreviewProgress = next;
      });
    });
    _fullScreenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _syncExternalOrientationToController();
    _syncPreviewToMode();
    widget.interactionController?._attach(
      _CalendarInteractiveActions(
        toggleFullScreen: _toggleFullScreenByButton,
        expand: _expandByController,
        collapse: _collapseByController,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CalendarInteractiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleCalendarControllerChanged);
      _lastKnownDisplayMode = widget.controller.displayMode;
      widget.controller.addListener(_handleCalendarControllerChanged);
    }
    _syncExternalOrientationToController();
    if (oldWidget.interactionController != widget.interactionController) {
      oldWidget.interactionController?._detach();
      widget.interactionController?._attach(
        _CalendarInteractiveActions(
          toggleFullScreen: _toggleFullScreenByButton,
          expand: _expandByController,
          collapse: _collapseByController,
        ),
      );
    }
    if (oldWidget.pageOrientation != widget.pageOrientation ||
        oldWidget.yearMode != widget.yearMode) {
      _clearFullScreenIfUnavailable();
    }
  }

  @override
  void dispose() {
    widget.interactionController?._detach();
    widget.controller.removeListener(_handleCalendarControllerChanged);
    _fullScreenController.dispose();
    _settleController.dispose();
    _listController.dispose();
    super.dispose();
  }

  CalendarPageOrientation get _effectivePageOrientation =>
      widget.interactionController?.pageOrientation ??
      widget.pageOrientation ??
      CalendarPageOrientation.horizontal;

  Listenable get _animationListenable {
    final interactionController = widget.interactionController;
    if (interactionController == null) {
      return widget.controller;
    }
    return Listenable.merge([widget.controller, interactionController]);
  }

  double get _collapseTravel {
    final rowCount = CalendarDateUtils.visibleMonthRowCount(
      widget.controller.focusedDay,
      firstWeekday: widget.controller.firstWeekday,
      monthViewShowMode: widget.controller.monthViewShowMode,
    );
    return widget.calendarHeight * (rowCount - 1);
  }

  int get _monthRowCount {
    return CalendarDateUtils.visibleMonthRowCount(
      widget.controller.focusedDay,
      firstWeekday: widget.controller.firstWeekday,
      monthViewShowMode: widget.controller.monthViewShowMode,
    );
  }

  double get _expandedCalendarHeight {
    return widget.monthHeaderHeight +
        widget.weekBarHeight +
        _effectiveMonthBodyHeight;
  }

  double get _collapsedCalendarHeight {
    return widget.monthHeaderHeight + widget.weekBarHeight + widget.calendarHeight;
  }

  double get _listTopOffset {
    return _displayedCalendarHeight ??
        lerpDouble(
          _expandedCalendarHeight,
          _collapsedCalendarHeight,
          _collapsePreviewProgress,
        )!;
  }

  ScrollPhysics get _listPhysics {
    if (widget.yearMode ||
        widget.controller.displayMode == CalendarDisplayMode.month ||
        _collapsePreviewProgress < 1) {
      return const NeverScrollableScrollPhysics();
    }
    return const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());
  }

  bool get _isHorizontalCalendarPaging =>
      _effectivePageOrientation == CalendarPageOrientation.horizontal;

  bool get _canGestureToFullScreen =>
      _isHorizontalCalendarPaging &&
      widget.controller.displayMode == CalendarDisplayMode.month &&
      _collapsePreviewProgress <= 0.0001;

  double get _normalMonthBodyHeight => widget.calendarHeight * _monthRowCount;

  double get _effectiveMonthBodyHeight =>
      (_canGestureToFullScreen && _monthBodyHeightOverride != null)
      ? _monthBodyHeightOverride!
      : _normalMonthBodyHeight;

  double get _maxMonthBodyHeight {
    final viewportBodyHeight =
        _calendarViewportHeight - widget.monthHeaderHeight - widget.weekBarHeight;
    if (viewportBodyHeight <= _normalMonthBodyHeight) {
      return _normalMonthBodyHeight;
    }
    return viewportBodyHeight;
  }

  bool get _isFullScreenExpanded =>
      _effectiveMonthBodyHeight > _normalMonthBodyHeight + 0.1;

  void _syncPreviewToMode() {
    _collapsePreviewProgress =
        widget.controller.displayMode == CalendarDisplayMode.week ? 1 : 0;
    _clearFullScreenIfUnavailable();
    _settleController.value = _collapsePreviewProgress;
  }

  void _clearFullScreenIfUnavailable() {
    if (_canGestureToFullScreen || _monthBodyHeightOverride == null) {
      return;
    }
    _monthBodyHeightOverride = null;
  }

  void _syncExternalOrientationToController() {
    final interactionController = widget.interactionController;
    final explicitOrientation = widget.pageOrientation;
    if (interactionController == null || explicitOrientation == null) {
      return;
    }
    if (interactionController.pageOrientation == explicitOrientation) {
      return;
    }
    interactionController.setPageOrientation(explicitOrientation);
  }

  void _handleCalendarControllerChanged() {
    final nextMode = widget.controller.displayMode;
    if (_isApplyingDisplayModeInternally) {
      _lastKnownDisplayMode = nextMode;
      return;
    }
    if (_lastKnownDisplayMode == nextMode) {
      return;
    }
    _lastKnownDisplayMode = nextMode;
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    if (!mounted) {
      return;
    }
    setState(() {
      _syncPreviewToMode();
      _resetDragState();
    });
  }

  void _scheduleInteractionStateSync() {
    final interactionController = widget.interactionController;
    if (interactionController == null) {
      return;
    }
    final pageOrientation = _effectivePageOrientation;
    final displayMode = widget.controller.displayMode;
    final collapseProgress = _collapsePreviewProgress.clamp(0.0, 1.0);
    final isFullScreenExpanded = _isFullScreenExpanded;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.interactionController != interactionController) {
        return;
      }
      interactionController._syncState(
        pageOrientation: pageOrientation,
        displayMode: displayMode,
        collapseProgress: collapseProgress,
        isFullScreenExpanded: isFullScreenExpanded,
      );
    });
  }

  void _applyDisplayMode(CalendarDisplayMode mode) {
    if (widget.controller.displayMode == mode) {
      _lastKnownDisplayMode = mode;
      return;
    }
    _isApplyingDisplayModeInternally = true;
    _lastKnownDisplayMode = mode;
    try {
      widget.controller.setDisplayMode(mode);
    } finally {
      _isApplyingDisplayModeInternally = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _clearFullScreenIfUnavailable();
    return AnimatedBuilder(
      animation: _animationListenable,
      builder: (context, _) {
        _scheduleInteractionStateSync();
        if (!_canGestureToFullScreen && _monthBodyHeightOverride != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _canGestureToFullScreen) {
              return;
            }
            setState(() {
              _monthBodyHeightOverride = null;
            });
          });
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            _calendarViewportHeight = constraints.maxHeight;
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: _isHorizontalCalendarPaging
                                ? (_) {
                                    _stopSettleAnimation();
                                    _stopFullScreenAnimation();
                                    _dragAccumulated = 0;
                                    _isCalendarAreaDragging = true;
                                    _dragSourceMode = widget.controller.displayMode;
                                    _fullScreenDragStartBodyHeight =
                                        _effectiveMonthBodyHeight;
                                    _isCalendarFullScreenDragging =
                                        _canGestureToFullScreen &&
                                        _isFullScreenExpanded;
                                  }
                                : null,
                            onVerticalDragUpdate: _isHorizontalCalendarPaging
                                ? (details) {
                                    _dragAccumulated += details.delta.dy;
                                    if (_isCalendarFullScreenDragging) {
                                      _updateFullScreenDrag(_dragAccumulated);
                                      return;
                                    }
                                    _updateCollapsePreview();
                                  }
                                : null,
                            onVerticalDragEnd: _isHorizontalCalendarPaging
                                ? (details) {
                                    if (_isCalendarFullScreenDragging) {
                                      _finishFullScreenDrag(
                                        details.primaryVelocity ?? 0,
                                      );
                                      return;
                                    }
                                    _commitVerticalDrag(
                                      details.primaryVelocity ?? 0,
                                    );
                                  }
                                : null,
                            onVerticalDragCancel: _isHorizontalCalendarPaging
                                ? () {
                                    if (_isCalendarFullScreenDragging) {
                                      _finishFullScreenDrag(0);
                                      return;
                                    }
                                    _resetDragState();
                                  }
                                : null,
                            child: CalendarView(
                              controller: widget.controller,
                              onDaySelected: widget.onDaySelected,
                              onPageChanged: (_) {
                                widget.onFocusedDayChanged?.call(
                                  widget.controller.focusedDay,
                                );
                              },
                              onDisplayedHeightChanged: (height) {
                                if (_displayedCalendarHeight != null &&
                                    (_displayedCalendarHeight! - height).abs() <
                                        0.0001) {
                                  return;
                                }
                                setState(() {
                                  _displayedCalendarHeight = height;
                                });
                              },
                              pageOrientation: _effectivePageOrientation,
                              monthBodyHeightOverride: _canGestureToFullScreen
                                  ? _monthBodyHeightOverride
                                  : null,
                              collapsePreviewProgress: _collapsePreviewProgress,
                              previewExpandFromWeek:
                                  _dragSourceMode == CalendarDisplayMode.week &&
                                  widget.controller.displayMode ==
                                      CalendarDisplayMode.week &&
                                  _collapsePreviewProgress < 1,
                              calendarHeight: widget.calendarHeight,
                              weekBarHeight: widget.weekBarHeight,
                              monthHeaderHeight: widget.monthHeaderHeight,
                            ),
                          ),
                          Positioned.fill(
                            top: _listTopOffset,
                            child: ClipRect(
                              child: Listener(
                                behavior: HitTestBehavior.translucent,
                                onPointerDown: _handleListPointerDown,
                                onPointerMove: _handleListPointerMove,
                                onPointerUp: _handleListPointerEnd,
                                onPointerCancel: _handleListPointerCancel,
                                child: widget.contentBuilder(
                                  context,
                                  _listController,
                                  _listPhysics,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateCollapsePreview() {
    if (_dragSourceMode == null || widget.yearMode || !_isHorizontalCalendarPaging) {
      return;
    }
    if (_dragSourceMode == CalendarDisplayMode.month) {
      final next = (-_dragAccumulated / _collapseTravel).clamp(0.0, 1.0);
      if (next != _collapsePreviewProgress) {
        setState(() {
          _collapsePreviewProgress = next;
        });
      }
      return;
    }
    if (_dragSourceMode == CalendarDisplayMode.week && _isListAtTop()) {
      final expand = (_dragAccumulated / _collapseTravel).clamp(0.0, 1.0);
      final next = 1 - expand;
      if (next != _collapsePreviewProgress) {
        setState(() {
          _collapsePreviewProgress = next;
        });
      }
      return;
    }
    if (_dragSourceMode == CalendarDisplayMode.week && _isCalendarAreaDragging) {
      final expand = (_dragAccumulated / _collapseTravel).clamp(0.0, 1.0);
      final next = 1 - expand;
      if (next != _collapsePreviewProgress) {
        setState(() {
          _collapsePreviewProgress = next;
        });
      }
    }
  }

  void _commitVerticalDrag(double velocity) {
    if (widget.yearMode || _dragSourceMode == null) {
      return;
    }
    if (_dragSourceMode == CalendarDisplayMode.month) {
      final shouldShrink = _collapsePreviewProgress > 0.45 || velocity < -450;
      _animateCollapseSettle(
        targetProgress: shouldShrink ? 1 : 0,
        targetMode: shouldShrink
            ? CalendarDisplayMode.week
            : CalendarDisplayMode.month,
        velocity: velocity,
      );
    } else if (_dragSourceMode == CalendarDisplayMode.week) {
      final shouldExpand =
          (_collapsePreviewProgress < 0.55 &&
              (_isCalendarAreaDragging || _isListAtTop())) ||
          velocity > 450;
      if (shouldExpand &&
          _listController.hasClients &&
          _listController.position.pixels != 0) {
        _listController.jumpTo(0);
      }
      _animateCollapseSettle(
        targetProgress: shouldExpand ? 0 : 1,
        targetMode: shouldExpand
            ? CalendarDisplayMode.month
            : CalendarDisplayMode.week,
        velocity: velocity,
      );
    }
    _dragAccumulated = 0;
  }

  bool _isListAtTop() {
    if (!_listController.hasClients) {
      return true;
    }
    return _listController.position.pixels <= 0;
  }

  void _handleListPointerDown(PointerDownEvent event) {
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    _listPointerId = event.pointer;
    _listPointerStartY = event.position.dy;
    _fullScreenDragStartBodyHeight = _effectiveMonthBodyHeight;
    _isCalendarAreaDragging = false;
    _isListCollapseDragging = false;
    _isListPullExpanding = false;
    _isListFullScreenDragging = false;
    _isCalendarFullScreenDragging = false;
    if (widget.controller.displayMode == CalendarDisplayMode.month) {
      _dragSourceMode = CalendarDisplayMode.month;
      return;
    }
    if (widget.controller.displayMode == CalendarDisplayMode.week &&
        _isListAtTop()) {
      _dragSourceMode = CalendarDisplayMode.week;
    }
  }

  void _handleListPointerMove(PointerMoveEvent event) {
    if (widget.yearMode || _listPointerId != event.pointer) {
      return;
    }

    final deltaY = event.position.dy - _listPointerStartY;
    if (widget.controller.displayMode == CalendarDisplayMode.month) {
      if (_canGestureToFullScreen && _isListAtTop()) {
        final shouldHandleFullScreen =
            _isListFullScreenDragging || _isFullScreenExpanded || deltaY > 0;
        if (shouldHandleFullScreen) {
          _isListFullScreenDragging = true;
          _updateFullScreenDrag(deltaY);
          return;
        }
      }
      if (!_isListCollapseDragging) {
        if (deltaY >= 0) {
          return;
        }
        _isListCollapseDragging = true;
      }
      final next = (-deltaY / _collapseTravel).clamp(0.0, 1.0);
      if (next != _collapsePreviewProgress) {
        setState(() {
          _dragSourceMode = CalendarDisplayMode.month;
          _collapsePreviewProgress = next;
        });
      }
      return;
    }

    if (widget.controller.displayMode != CalendarDisplayMode.week) {
      return;
    }
    if (!_isListPullExpanding) {
      if (!_isListAtTop() || deltaY <= 0) {
        return;
      }
      _isListPullExpanding = true;
      _dragSourceMode = CalendarDisplayMode.week;
      _listPointerStartY = event.position.dy;
      return;
    }

    final expandDelta = event.position.dy - _listPointerStartY;
    final next = (1 - (expandDelta / _collapseTravel)).clamp(0.0, 1.0);
    if (next != _collapsePreviewProgress) {
      setState(() {
        _dragSourceMode = CalendarDisplayMode.week;
        _collapsePreviewProgress = next;
      });
    }
  }

  void _handleListPointerEnd(PointerEvent event) {
    if (_listPointerId != event.pointer) {
      return;
    }
    _finishListPullExpand();
  }

  void _handleListPointerCancel(PointerCancelEvent event) {
    if (_listPointerId != event.pointer) {
      return;
    }
    _finishListPullExpand();
  }

  void _finishListPullExpand() {
    _listPointerId = null;
    if (_isListFullScreenDragging) {
      _finishFullScreenDrag(0);
      return;
    }
    if (!_isListPullExpanding && !_isListCollapseDragging) {
      if (widget.controller.displayMode == CalendarDisplayMode.week ||
          widget.controller.displayMode == CalendarDisplayMode.month) {
        _resetDragState();
      }
      return;
    }
    final velocity = _isListCollapseDragging ? -520.0 : 520.0;
    _commitVerticalDrag(velocity);
  }

  void _resetDragState() {
    _dragSourceMode = null;
    _isCalendarAreaDragging = false;
    _isListCollapseDragging = false;
    _isListPullExpanding = false;
    _isListFullScreenDragging = false;
    _isCalendarFullScreenDragging = false;
  }

  void _stopSettleAnimation() {
    if (_settleController.isAnimating) {
      _settleController.stop();
    }
    _settleController.value = _collapsePreviewProgress;
  }

  void _stopFullScreenAnimation() {
    if (_fullScreenController.isAnimating) {
      _fullScreenController.stop();
    }
  }

  void _toggleFullScreenByButton() {
    if (!_isHorizontalCalendarPaging) {
      return;
    }
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    if (widget.controller.displayMode != CalendarDisplayMode.month ||
        _collapsePreviewProgress > 0.0001) {
      setState(() {
        _applyDisplayMode(CalendarDisplayMode.month);
        _collapsePreviewProgress = 0;
        _settleController.value = 0;
        _resetDragState();
      });
    }
    final targetHeight = _isFullScreenExpanded
        ? _normalMonthBodyHeight
        : _maxMonthBodyHeight;
    _animateFullScreenCalendar(targetHeight);
  }

  void _expandByController() {
    if (widget.yearMode) {
      return;
    }
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    if (_listController.hasClients && _listController.position.pixels != 0) {
      _listController.jumpTo(0);
    }
    if (_isFullScreenExpanded) {
      _animateFullScreenCalendar(_normalMonthBodyHeight);
      return;
    }
    if (widget.controller.displayMode == CalendarDisplayMode.month &&
        _collapsePreviewProgress <= 0.0001) {
      return;
    }
    _animateCollapseSettle(
      targetProgress: 0,
      targetMode: CalendarDisplayMode.month,
      velocity: _collapseTravel,
    );
  }

  void _collapseByController() {
    if (widget.yearMode) {
      return;
    }
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    if (_isFullScreenExpanded) {
      _animateFullScreenCalendar(
        _normalMonthBodyHeight,
        onCompleted: () {
          if (!mounted) {
            return;
          }
          _animateCollapseSettle(
            targetProgress: 1,
            targetMode: CalendarDisplayMode.week,
            velocity: -_collapseTravel,
          );
        },
      );
      return;
    }
    if (widget.controller.displayMode == CalendarDisplayMode.week &&
        _collapsePreviewProgress >= 0.9999) {
      return;
    }
    _animateCollapseSettle(
      targetProgress: 1,
      targetMode: CalendarDisplayMode.week,
      velocity: -_collapseTravel,
    );
  }

  void _updateFullScreenDrag(double totalDelta) {
    final desiredHeight = _fullScreenDragStartBodyHeight + totalDelta;
    final clampedHeight = desiredHeight.clamp(
      _normalMonthBodyHeight,
      _maxMonthBodyHeight,
    );
    final overflowUp = (_normalMonthBodyHeight - desiredHeight).clamp(
      0.0,
      double.infinity,
    );
    setState(() {
      if (overflowUp > 0) {
        _monthBodyHeightOverride = _normalMonthBodyHeight;
        _collapsePreviewProgress = (overflowUp / _collapseTravel).clamp(
          0.0,
          1.0,
        );
      } else {
        _monthBodyHeightOverride = clampedHeight;
        _collapsePreviewProgress = 0;
      }
    });
  }

  void _finishFullScreenDrag(double velocity) {
    if (_collapsePreviewProgress > 0.0001) {
      _monthBodyHeightOverride = null;
      _isListFullScreenDragging = false;
      _isCalendarFullScreenDragging = false;
      _commitVerticalDrag(velocity);
      return;
    }
    _settleFullScreenCalendar(velocity: velocity);
  }

  void _settleFullScreenCalendar({double velocity = 0}) {
    final currentHeight = _effectiveMonthBodyHeight;
    final midpoint = (_normalMonthBodyHeight + _maxMonthBodyHeight) / 2;
    final targetHeight = velocity > 450
        ? _maxMonthBodyHeight
        : velocity < -450
            ? _normalMonthBodyHeight
            : (currentHeight >= midpoint
                ? _maxMonthBodyHeight
                : _normalMonthBodyHeight);
    _animateFullScreenCalendar(targetHeight);
  }

  void _animateFullScreenCalendar(
    double targetHeight, {
    VoidCallback? onCompleted,
  }) {
    _stopFullScreenAnimation();
    final begin = _effectiveMonthBodyHeight;
    if ((begin - targetHeight).abs() < 0.0001) {
      setState(() {
        _monthBodyHeightOverride = targetHeight > _normalMonthBodyHeight
            ? targetHeight
            : null;
        _resetDragState();
      });
      onCompleted?.call();
      return;
    }
    final animation = Tween<double>(
      begin: begin,
      end: targetHeight,
    ).animate(
      CurvedAnimation(
        parent: _fullScreenController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fullScreenController
      ..stop()
      ..reset();
    void listener() {
      if (!mounted) {
        return;
      }
      setState(() {
        _monthBodyHeightOverride = animation.value;
      });
    }

    _fullScreenController.addListener(listener);
    _fullScreenController.forward().whenCompleteOrCancel(() {
      _fullScreenController.removeListener(listener);
      if (!mounted) {
        return;
      }
      setState(() {
        _monthBodyHeightOverride = targetHeight > _normalMonthBodyHeight
            ? targetHeight
            : null;
        _resetDragState();
      });
      onCompleted?.call();
    });
  }

  void _animateCollapseSettle({
    required double targetProgress,
    required CalendarDisplayMode targetMode,
    required double velocity,
  }) {
    _stopSettleAnimation();
    final currentProgress = _collapsePreviewProgress;
    if ((currentProgress - targetProgress).abs() < 0.0001) {
      setState(() {
        _applyDisplayMode(targetMode);
        _collapsePreviewProgress = targetProgress;
        _settleController.value = targetProgress;
        _resetDragState();
      });
      return;
    }

    final progressVelocity = (-velocity / _collapseTravel).clamp(-8.0, 8.0);
    final simulation = SpringSimulation(
      _settleSpring,
      currentProgress,
      targetProgress,
      progressVelocity,
    );

    _settleController.animateWith(simulation).whenCompleteOrCancel(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _applyDisplayMode(targetMode);
        _collapsePreviewProgress = targetProgress;
        _settleController.value = targetProgress;
        _resetDragState();
      });
    });
  }
}
