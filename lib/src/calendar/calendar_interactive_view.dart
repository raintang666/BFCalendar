import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'calendar_components.dart';
import 'calendar_controller.dart';
import 'calendar_models.dart';
import 'calendar_retained_day_painter.dart';
import 'calendar_view.dart';
import 'date_utils_ext.dart';

/// 构建与日历联动滚动的内容区域。
typedef CalendarInteractiveContentBuilder =
    Widget Function(
      BuildContext context,
      ScrollController scrollController,
      ScrollPhysics physics,
    );

/// 日历交互控制器。
class CalendarInteractiveController extends ChangeNotifier {
  /// 创建交互控制器。
  CalendarInteractiveController({
    CalendarPageOrientation pageOrientation =
        CalendarPageOrientation.horizontal,
  }) : _pageOrientation = pageOrientation;

  _CalendarInteractiveActions? _actions;
  CalendarPageOrientation _pageOrientation;
  CalendarDisplayMode _displayMode = CalendarDisplayMode.month;
  double _collapseProgress = 0;
  bool _isFullScreenExpanded = false;

  /// 当前分页方向。
  CalendarPageOrientation get pageOrientation => _pageOrientation;

  /// 当前月/周显示模式。
  CalendarDisplayMode get displayMode => _displayMode;

  /// 当前折叠进度。
  double get collapseProgress => _collapseProgress;

  /// 是否处于全屏展开状态。
  bool get isFullScreenExpanded => _isFullScreenExpanded;

  /// 是否已折叠为周视图。
  bool get isCollapsed =>
      _displayMode == CalendarDisplayMode.week || _collapseProgress >= 0.9999;

  /// 是否处于展开状态。
  bool get isExpanded => !isCollapsed;

  /// 设置分页方向。
  void setPageOrientation(CalendarPageOrientation orientation) {
    if (_pageOrientation == orientation) {
      return;
    }
    _pageOrientation = orientation;
    notifyListeners();
  }

  /// 切换分页方向。
  void togglePageOrientation() {
    setPageOrientation(
      _pageOrientation == CalendarPageOrientation.horizontal
          ? CalendarPageOrientation.vertical
          : CalendarPageOrientation.horizontal,
    );
  }

  /// 展开日历。
  void expand() {
    _actions?.expand.call();
  }

  /// 收起日历。
  void collapse() {
    _actions?.collapse.call();
  }

  /// 收起日历，等同于 [collapse]。
  void shrink() {
    collapse();
  }

  /// 切换全屏展开状态。
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

/// 日历与内容列表联动的交互视图。
class CalendarInteractiveView extends StatefulWidget {
  /// 创建日历交互视图。
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
    this.componentBuilder,
    this.contentVerticalDragLocked = false,
  });

  /// 日历状态控制器。
  final CalendarController controller;

  /// 日期点击回调。
  final ValueChanged<DateTime> onDaySelected;

  /// 聚焦日期变化回调。
  final ValueChanged<DateTime>? onFocusedDayChanged;

  /// 内容区域构建器。
  final CalendarInteractiveContentBuilder contentBuilder;

  /// 外部交互控制器。
  final CalendarInteractiveController? interactionController;

  /// 分页方向覆盖值。
  final CalendarPageOrientation? pageOrientation;

  /// 是否处于年视图模式。
  final bool yearMode;

  /// 单行日期高度。
  final double calendarHeight;

  /// 星期栏高度。
  final double weekBarHeight;

  /// 月份头高度。
  final double monthHeaderHeight;

  /// 自定义日历样式构建器。
  final CalendarComponentBuilder? componentBuilder;

  /// 是否锁定内容区域分发给日历的纵向拖拽。
  final bool contentVerticalDragLocked;

  @override
  State<CalendarInteractiveView> createState() =>
      _CalendarInteractiveViewState();
}

class _CalendarInteractiveViewState extends State<CalendarInteractiveView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _stretchImages = CalendarStretchImageCache();
  static const _snapFlingVelocity = 450.0;
  static const _settleSpring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 24,
  );

  late final AnimationController _settleController;
  late final AnimationController _fullScreenController;
  final ScrollController _listController = ScrollController();
  late CalendarDisplayMode _lastKnownDisplayMode;
  late CalendarPageOrientation _lastKnownOrientation;
  bool _isApplyingDisplayModeInternally = false;

  Drag? _contentDrag;
  double _dragBodyHeight = 0;
  double _collapsePreviewProgress = 0;
  CalendarDisplayMode? _dragSourceMode;
  bool _isCalendarAreaDragging = false;
  int? _listPointerId;
  double _listPointerStartX = 0;
  double _listPointerStartY = 0;
  VelocityTracker? _listVelocity;
  bool _isListDragging = false;
  bool _isVerticalFullScreenExpanded = false;
  double? _monthBodyHeightOverride;
  double _calendarViewportHeight = 0;
  Widget? _content;
  ScrollPhysics? _contentPhysics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastKnownOrientation = _effectivePageOrientation;
    widget.interactionController?.addListener(_handleInteractionChanged);
    _lastKnownDisplayMode = widget.controller.displayMode;
    widget.controller.addListener(_handleCalendarControllerChanged);
    _settleController =
        AnimationController(
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
    _content = null;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleCalendarControllerChanged);
      _lastKnownDisplayMode = widget.controller.displayMode;
      widget.controller.addListener(_handleCalendarControllerChanged);
    }
    _syncExternalOrientationToController();
    if (oldWidget.interactionController != widget.interactionController) {
      oldWidget.interactionController?.removeListener(
        _handleInteractionChanged,
      );
      widget.interactionController?.addListener(_handleInteractionChanged);
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
    if (!oldWidget.contentVerticalDragLocked &&
        widget.contentVerticalDragLocked) {
      _resetDragState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _content = null;
  }

  Widget _buildContent() {
    final physics = _listPhysics;
    if (_content == null || _contentPhysics != physics) {
      _contentPhysics = physics;
      _content = ClipRect(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handleListPointerDown,
          onPointerMove: _handleListPointerMove,
          onPointerUp: _handleListPointerEnd,
          onPointerCancel: _handleListPointerEnd,
          child: Builder(
            builder: (context) =>
                widget.contentBuilder(context, _listController, physics),
          ),
        ),
      );
    }
    return _content!;
  }

  @override
  void didHaveMemoryPressure() => _stretchImages.clear();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stretchImages.clear();
    widget.interactionController?.removeListener(_handleInteractionChanged);
    widget.interactionController?._detach();
    widget.controller.removeListener(_handleCalendarControllerChanged);
    _fullScreenController.dispose();
    _settleController.dispose();
    _contentDrag?.cancel();
    _listController.dispose();
    super.dispose();
  }

  CalendarPageOrientation get _effectivePageOrientation =>
      widget.interactionController?.pageOrientation ??
      widget.pageOrientation ??
      CalendarPageOrientation.horizontal;

  void _handleInteractionChanged() {
    final orientation = _effectivePageOrientation;
    if (_lastKnownOrientation == orientation) return;
    setState(() {
      _lastKnownOrientation = orientation;
      _content = null;
    });
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

  bool get _isVerticalCalendarPaging =>
      _effectivePageOrientation == CalendarPageOrientation.vertical;

  // Keep the week as the committed mode until the user releases the drag.
  bool get _previewExpandFromWeek =>
      _dragSourceMode == CalendarDisplayMode.week &&
      widget.controller.displayMode == CalendarDisplayMode.week &&
      _collapsePreviewProgress < 1;

  bool get _canGestureToFullScreen =>
      _isHorizontalCalendarPaging &&
      (widget.controller.displayMode == CalendarDisplayMode.month ||
          _previewExpandFromWeek) &&
      _collapsePreviewProgress <= 0.0001;

  double get _normalMonthBodyHeight => widget.calendarHeight * _monthRowCount;

  double get _effectiveMonthBodyHeight =>
      (_canGestureToFullScreen && _monthBodyHeightOverride != null)
      ? _monthBodyHeightOverride!
      : _normalMonthBodyHeight;

  double get _maxMonthBodyHeight {
    final viewportBodyHeight =
        _calendarViewportHeight -
        widget.monthHeaderHeight -
        widget.weekBarHeight;
    if (viewportBodyHeight <= _normalMonthBodyHeight) {
      return _normalMonthBodyHeight;
    }
    return viewportBodyHeight;
  }

  bool get _isFullScreenExpanded =>
      _isVerticalFullScreenExpanded ||
      _effectiveMonthBodyHeight > _normalMonthBodyHeight + 0.1;

  bool _isDominantVerticalGesture({
    required double deltaX,
    required double deltaY,
  }) {
    const minVerticalDistance = 8.0;
    final absX = deltaX.abs();
    final absY = deltaY.abs();
    return absY >= minVerticalDistance && absY > absX;
  }

  void _syncPreviewToMode() {
    _collapsePreviewProgress =
        widget.controller.displayMode == CalendarDisplayMode.week ? 1 : 0;
    _clearFullScreenIfUnavailable();
    _settleController.value = _collapsePreviewProgress;
  }

  void _clearFullScreenIfUnavailable() {
    if (!_isVerticalCalendarPaging && _isVerticalFullScreenExpanded) {
      _isVerticalFullScreenExpanded = false;
    }
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
    _content = null;
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

  void _handleListMonthChanged(DateTime month) {
    final controller = widget.controller;
    if (!CalendarDateUtils.isSameMonth(month, controller.focusedDay)) {
      final min = controller.minDate;
      controller.jumpToDay(min != null && month.isBefore(min) ? min : month);
    }
    widget.onFocusedDayChanged?.call(controller.focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    _clearFullScreenIfUnavailable();
    final canDragCalendar = _isHorizontalCalendarPaging && !widget.yearMode;
    return AnimatedBuilder(
      animation: widget.controller,
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
            if (_isVerticalFullScreenExpanded) {
              return CalendarMonthListView(
                controller: widget.controller,
                onDaySelected: widget.onDaySelected,
                calendarHeight: widget.calendarHeight,
                weekBarHeight: widget.weekBarHeight,
                componentBuilder: widget.componentBuilder,
                onFocusedMonthChanged: _handleListMonthChanged,
              );
            }
            return CustomMultiChildLayout(
              delegate: _CalendarContentLayoutDelegate(),
              children: [
                LayoutId(
                  id: _CalendarSlot.calendar,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onVerticalDragStart: canDragCalendar
                        ? (_) => _startVerticalDrag(fromCalendar: true)
                        : null,
                    onVerticalDragUpdate: canDragCalendar
                        ? _updateVerticalDrag
                        : null,
                    onVerticalDragEnd: canDragCalendar
                        ? _endVerticalDrag
                        : null,
                    onVerticalDragCancel: canDragCalendar
                        ? () {
                            if (_isCalendarAreaDragging) {
                              _endVerticalDrag(
                                DragEndDetails(primaryVelocity: 0),
                              );
                            }
                          }
                        : null,
                    child: CalendarStretchMotion(
                      images: _stretchImages,
                      active:
                          (_dragSourceMode != null &&
                              _monthBodyHeightOverride != null) ||
                          _fullScreenController.isAnimating,
                      child: CalendarView(
                        controller: widget.controller,
                        onDaySelected: widget.onDaySelected,
                        componentBuilder: widget.componentBuilder,
                        onPageChanged: (_) {
                          widget.onFocusedDayChanged?.call(
                            widget.controller.focusedDay,
                          );
                        },
                        pageOrientation: _effectivePageOrientation,
                        monthBodyHeightOverride: _canGestureToFullScreen
                            ? _monthBodyHeightOverride
                            : null,
                        collapsePreviewProgress: _collapsePreviewProgress,
                        previewExpandFromWeek: _previewExpandFromWeek,
                        calendarHeight: widget.calendarHeight,
                        weekBarHeight: widget.weekBarHeight,
                        monthHeaderHeight: widget.monthHeaderHeight,
                      ),
                    ),
                  ),
                ),
                LayoutId(id: _CalendarSlot.content, child: _buildContent()),
              ],
            );
          },
        );
      },
    );
  }

  void _startVerticalDrag({required bool fromCalendar}) {
    _stopSettleAnimation();
    _stopFullScreenAnimation();
    _isCalendarAreaDragging = fromCalendar;
    _dragSourceMode = widget.controller.displayMode;
    _dragBodyHeight =
        _monthBodyHeightOverride ??
        _normalMonthBodyHeight - _collapseTravel * _collapsePreviewProgress;
  }

  void _updateVerticalDrag(DragUpdateDetails details) {
    if (_dragSourceMode == null) return;
    var delta = details.delta.dy;
    // On reversal, unwind the list portion of this drag before opening the week.
    if (delta > 0 && _contentDrag != null) {
      delta -= _dragContentBy(delta, details);
      if (delta == 0) return;
      _contentDrag?.cancel();
    }
    final weekHeight = widget.calendarHeight;
    final desiredHeight = _dragBodyHeight + delta;
    _dragBodyHeight = desiredHeight < weekHeight ? weekHeight : desiredHeight;
    _updateDragBodyHeight(_dragBodyHeight);
    if (desiredHeight < weekHeight) {
      _dragContentBy(desiredHeight - weekHeight, details);
    }
  }

  double _dragContentBy(double delta, DragUpdateDetails details) {
    final position = _listController.positions.singleOrNull;
    if (position == null ||
        !position.hasContentDimensions ||
        position.axis != Axis.vertical) {
      return 0;
    }
    final reversed = position.axisDirection == AxisDirection.up;
    final distance = reversed
        ? delta.clamp(-position.extentBefore, position.extentAfter)
        : delta.clamp(-position.extentAfter, position.extentBefore);
    if (distance == 0) return 0;
    _contentDrag ??= position.drag(
      DragStartDetails(globalPosition: details.globalPosition),
      () => _contentDrag = null,
    );
    _contentDrag!.update(
      DragUpdateDetails(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        delta: Offset(0, distance),
        primaryDelta: distance,
      ),
    );
    return distance;
  }

  void _endVerticalDrag(DragEndDetails details) {
    if (widget.yearMode || _dragSourceMode == null) return;
    if (_contentDrag != null) {
      _contentDrag!.end(details);
      _animateCollapseSettle(
        targetProgress: 1,
        targetMode: CalendarDisplayMode.week,
        velocity: 0,
      );
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final fromWeek = _dragSourceMode == CalendarDisplayMode.week;
    final stretched = _monthBodyHeightOverride != null;
    final bool expand;
    if (velocity.abs() >= _snapFlingVelocity) {
      expand = velocity > 0;
    } else if (stretched) {
      expand =
          _effectiveMonthBodyHeight >=
          (_normalMonthBodyHeight + _maxMonthBodyHeight) / 2;
    } else {
      expand = fromWeek
          ? _collapsePreviewProgress < 0.55
          : _collapsePreviewProgress <= 0.45;
    }

    if (fromWeek &&
        (expand || stretched) &&
        _listController.hasClients &&
        _listController.offset != 0) {
      _listController.jumpTo(0);
    }
    if (stretched) {
      _applyDisplayMode(CalendarDisplayMode.month);
      _animateFullScreenCalendar(
        expand ? _maxMonthBodyHeight : _normalMonthBodyHeight,
      );
      return;
    }
    _animateCollapseSettle(
      targetProgress: expand ? 0 : 1,
      targetMode: expand ? CalendarDisplayMode.month : CalendarDisplayMode.week,
      velocity: velocity,
    );
  }

  bool _isListAtTop() {
    if (!_listController.hasClients) {
      return true;
    }
    return _listController.position.pixels <= 0;
  }

  void _handleListPointerDown(PointerDownEvent event) {
    if (widget.yearMode ||
        widget.contentVerticalDragLocked ||
        _listPointerId != null) {
      return;
    }
    _listPointerId = event.pointer;
    _listPointerStartX = event.position.dx;
    _listPointerStartY = event.position.dy;
    _listVelocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _isListDragging = false;
  }

  void _handleListPointerMove(PointerMoveEvent event) {
    if (_listPointerId != event.pointer ||
        widget.yearMode ||
        widget.contentVerticalDragLocked) {
      return;
    }
    _listVelocity?.addPosition(event.timeStamp, event.position);
    var delta = event.delta.dy;
    if (!_isListDragging) {
      final deltaX = event.position.dx - _listPointerStartX;
      delta = event.position.dy - _listPointerStartY;
      if (!_isDominantVerticalGesture(deltaX: deltaX, deltaY: delta)) return;
      // A week-mode list owns its native drag until it is pulled from the top.
      final fromWeek =
          widget.controller.displayMode == CalendarDisplayMode.week;
      if (fromWeek && (!_isListAtTop() || delta <= 0)) return;
      _isListDragging = true;
      _startVerticalDrag(fromCalendar: false);
      if (fromWeek) return;
    }
    _updateVerticalDrag(
      DragUpdateDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        delta: Offset(0, delta),
        primaryDelta: delta,
      ),
    );
  }

  void _handleListPointerEnd(PointerEvent event) {
    if (_listPointerId != event.pointer) return;
    _listPointerId = null;
    var velocity = 0.0;
    if (_isListDragging && event is PointerUpEvent) {
      final measured = _listVelocity!.getVelocity().pixelsPerSecond.dy;
      final physics = _contentDrag == null
          ? null
          : _listController.positions.singleOrNull?.physics;
      if (measured.abs() >= (physics?.minFlingVelocity ?? kMinFlingVelocity)) {
        final limit = physics?.maxFlingVelocity ?? kMaxFlingVelocity;
        velocity = measured.clamp(-limit, limit);
      }
    }
    _listVelocity = null;
    if (_isListDragging) {
      _isListDragging = false;
      _endVerticalDrag(
        DragEndDetails(
          velocity: Velocity(pixelsPerSecond: Offset(0, velocity)),
          primaryVelocity: velocity,
        ),
      );
    }
  }

  void _resetDragState() {
    _contentDrag?.cancel();
    _dragSourceMode = null;
    _isCalendarAreaDragging = false;
    _listPointerId = null;
    _listVelocity = null;
    _isListDragging = false;
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
    if (_isVerticalCalendarPaging) {
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
      setState(() {
        _isVerticalFullScreenExpanded = !_isVerticalFullScreenExpanded;
      });
      return;
    }
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
    if (_isVerticalCalendarPaging) {
      if (_isVerticalFullScreenExpanded) {
        return;
      }
      if (widget.controller.displayMode != CalendarDisplayMode.month ||
          _collapsePreviewProgress > 0.0001) {
        setState(() {
          _applyDisplayMode(CalendarDisplayMode.month);
          _collapsePreviewProgress = 0;
          _settleController.value = 0;
          _resetDragState();
        });
      }
      setState(() {
        _isVerticalFullScreenExpanded = true;
      });
      return;
    }
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
    if (_isVerticalCalendarPaging) {
      if (!_isVerticalFullScreenExpanded) {
        return;
      }
      setState(() {
        _isVerticalFullScreenExpanded = false;
      });
      return;
    }
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

  void _updateDragBodyHeight(double desiredHeight) {
    final normalHeight = _normalMonthBodyHeight;
    final collapseTravel = normalHeight - widget.calendarHeight;
    final stretchedHeight =
        desiredHeight > normalHeight && _isHorizontalCalendarPaging
        ? desiredHeight.clamp(normalHeight, _maxMonthBodyHeight)
        : null;
    final collapse = desiredHeight < normalHeight
        ? ((normalHeight - desiredHeight) / collapseTravel).clamp(0.0, 1.0)
        : 0.0;
    if (stretchedHeight == _monthBodyHeightOverride &&
        collapse == _collapsePreviewProgress) {
      return;
    }
    setState(() {
      _monthBodyHeightOverride = stretchedHeight;
      _collapsePreviewProgress = collapse;
    });
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
    final animation = Tween<double>(begin: begin, end: targetHeight).animate(
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
    final motion = _fullScreenController.forward();
    motion.whenCompleteOrCancel(
      () => _fullScreenController.removeListener(listener),
    );
    motion.then<void>((_) {
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

    _settleController.animateWith(simulation).then<void>((_) {
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

// Measure both areas together so the feed follows the calendar in the same
// frame, including months with different row counts during a page swipe.
enum _CalendarSlot { calendar, content }

class _CalendarContentLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final calendarSize = layoutChild(
      _CalendarSlot.calendar,
      BoxConstraints.loose(size),
    );
    positionChild(_CalendarSlot.calendar, Offset.zero);
    layoutChild(
      _CalendarSlot.content,
      BoxConstraints.tight(
        Size(
          size.width,
          (size.height - calendarSize.height).clamp(0.0, size.height),
        ),
      ),
    );
    positionChild(_CalendarSlot.content, Offset(0, calendarSize.height));
  }

  @override
  bool shouldRelayout(_CalendarContentLayoutDelegate oldDelegate) => false;
}
