import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../calendar/calendar_controller.dart';
import '../../calendar/calendar_models.dart';
import '../../calendar/calendar_view.dart';
import '../../calendar/date_utils_ext.dart';
import '../range/range_page.dart';
import 'demo_entries.dart';

class CalendarDemoPage extends StatefulWidget {
  const CalendarDemoPage({super.key});

  @override
  State<CalendarDemoPage> createState() => _CalendarDemoPageState();
}

class _CalendarDemoPageState extends State<CalendarDemoPage>
    with TickerProviderStateMixin {
  static const double _calendarRowHeight = 62;
  static const double _weekBarHeight = 46;
  static const double _monthHeaderHeight = 60;
  static const _settleSpring = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 24,
  );

  late final CalendarController _controller;
  late final AnimationController _settleController;
  late final AnimationController _fullScreenController;
  final ScrollController _listController = ScrollController();
  bool _yearMode = false;
  int _yearPanelYear = DateTime.now().year;
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
  CalendarPageOrientation _pageOrientation =
      CalendarPageOrientation.horizontal;

  static const _moreActions = <String>[
    '周日为周起始',
    '周一为周起始',
    '周六为周起始',
    '更换选择模式：单选/默认',
    '热插拔更换周月视图',
    '月视图模式：全部显示',
    '月视图模式：仅当前月份',
    '月视图模式：自动填充',
  ];

  static const _funcActions = <String>[
    '展开日历布局',
    '收缩日历布局',
    '上一页',
    '下一页',
    '返回今天',
    '限制日期范围',
    '显示日期范围',
  ];

  @override
  void initState() {
    super.initState();
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
    final now = CalendarDateUtils.stripTime(DateTime.now());
    _controller = CalendarController(
      focusedDay: now,
      minDate: DateTime(1, 1, 1),
      maxDate: DateTime(9999, 12, 31),
      markers: _buildMarkers(now.year, now.month),
    );
    _controller.setWeekStart(DateTime.sunday);
    _yearPanelYear = now.year;
    _syncPreviewToMode();
  }

  Map<DateTime, List<CalendarMarker>> _buildMarkers(int year, int month) {
    final specs = <(int, int, String)>[
      (1, 0xFF40DB25, '假'),
      (19, 0xFF40DB25, '码'),
      (26, 0xFF40DB25, '议'),
      (28, 0xFF40DB25, '码'),
    ];

    return {
      for (final spec in specs)
        DateTime(year, month, spec.$1): [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
        ],
    };
  }

  void _rebuildMarkersForFocusedMonth() {
    _controller.setMarkers(
      _buildMarkers(_controller.focusedDay.year, _controller.focusedDay.month),
    );
  }

  void _syncPreviewToMode() {
    _collapsePreviewProgress =
        _controller.displayMode == CalendarDisplayMode.week ? 1 : 0;
    if (!_canGestureToFullScreen) {
      _monthBodyHeightOverride = null;
    }
    _settleController.value = _collapsePreviewProgress;
  }

  double get _collapseTravel {
    final rowCount = CalendarDateUtils.visibleMonthRowCount(
      _controller.focusedDay,
      firstWeekday: _controller.firstWeekday,
      monthViewShowMode: _controller.monthViewShowMode,
    );
    return _calendarRowHeight * (rowCount - 1);
  }

  int get _monthRowCount {
    return CalendarDateUtils.visibleMonthRowCount(
      _controller.focusedDay,
      firstWeekday: _controller.firstWeekday,
      monthViewShowMode: _controller.monthViewShowMode,
    );
  }

  double get _expandedCalendarHeight {
    return _monthHeaderHeight +
        _weekBarHeight +
        _effectiveMonthBodyHeight;
  }

  double get _collapsedCalendarHeight {
    return _monthHeaderHeight + _weekBarHeight + _calendarRowHeight;
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
    if (_yearMode ||
        _controller.displayMode == CalendarDisplayMode.month ||
        _collapsePreviewProgress < 1) {
      return const NeverScrollableScrollPhysics();
    }
    return const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());
  }

  bool get _isHorizontalCalendarPaging =>
      _pageOrientation == CalendarPageOrientation.horizontal;

  bool get _canGestureToFullScreen =>
      _isHorizontalCalendarPaging &&
      _controller.displayMode == CalendarDisplayMode.month &&
      _collapsePreviewProgress <= 0.0001;

  double get _normalMonthBodyHeight => _calendarRowHeight * _monthRowCount;

  double get _effectiveMonthBodyHeight =>
      (_canGestureToFullScreen && _monthBodyHeightOverride != null)
      ? _monthBodyHeightOverride!
      : _normalMonthBodyHeight;

  double get _maxMonthBodyHeight {
    final viewportBodyHeight =
        _calendarViewportHeight - _monthHeaderHeight - _weekBarHeight;
    if (viewportBodyHeight <= _normalMonthBodyHeight) {
      return _normalMonthBodyHeight;
    }
    return viewportBodyHeight;
  }

  bool get _isFullScreenExpanded =>
      _effectiveMonthBodyHeight > _normalMonthBodyHeight + 0.1;

  @override
  void dispose() {
    _fullScreenController.dispose();
    _settleController.dispose();
    _listController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FE),
      body: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF7F6FE),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              _buildToolbar(),
              Visibility(
                visible: _yearMode,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Text(
                    '${_controller.focusedDay.year}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
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
                                    onVerticalDragStart:
                                        _isHorizontalCalendarPaging
                                        ? (_) {
                                            _stopSettleAnimation();
                                            _stopFullScreenAnimation();
                                            _dragAccumulated = 0;
                                            _isCalendarAreaDragging = true;
                                            _dragSourceMode =
                                                _controller.displayMode;
                                            _fullScreenDragStartBodyHeight =
                                                _effectiveMonthBodyHeight;
                                            _isCalendarFullScreenDragging =
                                                _canGestureToFullScreen &&
                                                _isFullScreenExpanded;
                                          }
                                        : null,
                                    onVerticalDragUpdate:
                                        _isHorizontalCalendarPaging
                                        ? (details) {
                                            _dragAccumulated += details.delta.dy;
                                            if (_isCalendarFullScreenDragging) {
                                              _updateFullScreenDrag(
                                                _dragAccumulated,
                                              );
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
                                    onVerticalDragCancel:
                                        _isHorizontalCalendarPaging
                                        ? () {
                                            if (_isCalendarFullScreenDragging) {
                                              _finishFullScreenDrag(0);
                                              return;
                                            }
                                            _resetDragState();
                                          }
                                        : null,
                                    child: CalendarView(
                                      controller: _controller,
                                      onDaySelected: (day) {
                                        if (_controller.isDisabled(day)) {
                                          _showMessage(
                                            '${_formatDate(day)}拦截不可点击',
                                          );
                                          return;
                                        }
                                        _controller.selectDay(day);
                                        _showMessage(_calendarToastText(day));
                                      },
                                      onPageChanged: (_) {
                                        _rebuildMarkersForFocusedMonth();
                                        setState(() {
                                          _yearPanelYear =
                                              _controller.focusedDay.year;
                                        });
                                      },
                                      onDisplayedHeightChanged: (height) {
                                        if (_displayedCalendarHeight != null &&
                                            (_displayedCalendarHeight! - height)
                                                    .abs() <
                                                0.0001) {
                                          return;
                                        }
                                        setState(() {
                                          _displayedCalendarHeight = height;
                                        });
                                      },
                                      pageOrientation: _pageOrientation,
                                      monthBodyHeightOverride:
                                          _canGestureToFullScreen
                                          ? _monthBodyHeightOverride
                                          : null,
                                      collapsePreviewProgress:
                                          _collapsePreviewProgress,
                                      previewExpandFromWeek:
                                          _dragSourceMode ==
                                              CalendarDisplayMode.week &&
                                          _controller.displayMode ==
                                              CalendarDisplayMode.week &&
                                          _collapsePreviewProgress < 1,
                                      calendarHeight: _calendarRowHeight,
                                      weekBarHeight: _weekBarHeight,
                                      monthHeaderHeight: _monthHeaderHeight,
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
                                        child: ListView.separated(
                                          controller: _listController,
                                          physics: _listPhysics,
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          itemCount: demoEntries.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final entry = demoEntries[index];
                                            return _DemoCard(
                                              entry: entry,
                                              onTap: () => _handleDemoTap(entry),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_yearMode)
                          _YearOverlay(
                            year: _yearPanelYear,
                            selectedMonth: _controller.focusedDay.month,
                            onPrevYear: () {
                              setState(() {
                                _yearPanelYear -= 1;
                              });
                            },
                            onNextYear: () {
                              setState(() {
                                _yearPanelYear += 1;
                              });
                            },
                            onMonthTap: (month) {
                              _controller.jumpToMonth(
                                DateTime(_yearPanelYear, month, 1),
                              );
                              _rebuildMarkersForFocusedMonth();
                              setState(() {
                                _yearMode = false;
                                _yearPanelYear = _controller.focusedDay.year;
                                _syncPreviewToMode();
                              });
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final orientationAsset =
        _isHorizontalCalendarPaging
        ? 'assets/icons/ic_horizontal.png'
        : 'assets/icons/ic_vertical.png';
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 22),
          _SwitchView(
            checked: _yearMode,
            onChanged: (value) {
              setState(() {
                _yearMode = value;
                _yearPanelYear = _controller.focusedDay.year;
                _syncPreviewToMode();
              });
            },
          ),
          const Spacer(),
          _ToolbarIconButton(
            asset: orientationAsset,
            onTap: () {
              if (_yearMode) {
                return;
              }
              setState(() {
                _pageOrientation =
                    _isHorizontalCalendarPaging
                    ? CalendarPageOrientation.vertical
                    : CalendarPageOrientation.horizontal;
                _resetDragState();
              });
            },
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_expand_list.png',
            onTap: () {
              if (_yearMode) {
                return;
              }
              setState(() {
                _controller.setDisplayMode(
                  _controller.displayMode == CalendarDisplayMode.month
                      ? CalendarDisplayMode.week
                      : CalendarDisplayMode.month,
                );
                _syncPreviewToMode();
              });
            },
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_func.png',
            onTap: _showFuncDialog,
          ),
          const SizedBox(width: 12),
          _ToolbarIconButton(
            asset: 'assets/icons/ic_more.png',
            onTap: _showMoreDialog,
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  void _showMoreDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('动态更新'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 280,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _moreActions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_moreActions[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleMoreAction(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFuncDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('功能支持'),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: SizedBox(
            width: 280,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _funcActions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_funcActions[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleFuncAction(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleMoreAction(int which) {
    setState(() {
      switch (which) {
        case 0:
          _controller.setWeekStart(DateTime.sunday);
          break;
        case 1:
          _controller.setWeekStart(DateTime.monday);
          break;
        case 2:
          _controller.setWeekStart(DateTime.saturday);
          break;
        case 3:
          _controller.setSelectionMode(
            _controller.selectionMode == CalendarSelectionMode.single
                ? CalendarSelectionMode.range
                : CalendarSelectionMode.single,
          );
          break;
        case 4:
          _showMessage('热插拔更换周月视图待继续还原');
          break;
        case 5:
          _controller.setMonthViewShowMode(MonthViewShowMode.allMonth);
          break;
        case 6:
          _controller.setMonthViewShowMode(
            MonthViewShowMode.onlyCurrentMonth,
          );
          break;
        case 7:
          _controller.setMonthViewShowMode(MonthViewShowMode.fitMonth);
          break;
      }
    });
  }

  void _handleFuncAction(int which) {
    setState(() {
      switch (which) {
        case 0:
          _controller.setDisplayMode(CalendarDisplayMode.month);
          _syncPreviewToMode();
          break;
        case 1:
          _controller.setDisplayMode(CalendarDisplayMode.week);
          _syncPreviewToMode();
          break;
        case 2:
          _controller.previousPage();
          _rebuildMarkersForFocusedMonth();
          break;
        case 3:
          _controller.nextPage();
          _rebuildMarkersForFocusedMonth();
          break;
        case 4:
          _controller.jumpToDay(CalendarDateUtils.stripTime(DateTime.now()));
          _rebuildMarkersForFocusedMonth();
          _syncPreviewToMode();
          break;
        case 5:
          _showMessage('限制日期范围已在控制器中启用 0001-9999');
          break;
        case 6:
          _showMessage('Calendar Range: 0001-01-01 —— 9999-12-31');
          break;
      }
    });
  }

  void _updateCollapsePreview() {
    if (_dragSourceMode == null || _yearMode || !_isHorizontalCalendarPaging) {
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
    if (_yearMode) {
      return;
    }
    if (_dragSourceMode == null) {
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

  String _calendarToastText(DateTime day) {
    return '新历${day.month}月${day.day}日';
  }

  String _formatDate(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
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
    if (_controller.displayMode == CalendarDisplayMode.month) {
      _dragSourceMode = CalendarDisplayMode.month;
      return;
    }
    if (_controller.displayMode == CalendarDisplayMode.week && _isListAtTop()) {
      _dragSourceMode = CalendarDisplayMode.week;
    }
  }

  void _handleListPointerMove(PointerMoveEvent event) {
    if (_yearMode || _listPointerId != event.pointer) {
      return;
    }

    final deltaY = event.position.dy - _listPointerStartY;
    if (_controller.displayMode == CalendarDisplayMode.month) {
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

    if (_controller.displayMode != CalendarDisplayMode.week) {
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
      if (_controller.displayMode == CalendarDisplayMode.week ||
          _controller.displayMode == CalendarDisplayMode.month) {
        _resetDragState();
      }
      return;
    }
    final velocity =
        _isListCollapseDragging ? -520.0 : 520.0;
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

  void _animateFullScreenCalendar(double targetHeight) {
    _stopFullScreenAnimation();
    final begin = _effectiveMonthBodyHeight;
    if ((begin - targetHeight).abs() < 0.0001) {
      setState(() {
        _monthBodyHeightOverride = targetHeight > _normalMonthBodyHeight
            ? targetHeight
            : null;
        _resetDragState();
      });
      return;
    }
    final animation = Tween<double>(
      begin: begin,
      end: targetHeight,
    ).animate(CurvedAnimation(parent: _fullScreenController, curve: Curves.easeOutCubic));
    _fullScreenController
      ..stop()
      ..reset();
    void listener() {
      if (!mounted) {
        return;
      }
      setState(() {
        final value = animation.value;
        _monthBodyHeightOverride = value;
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
        _controller.setDisplayMode(targetMode);
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

    _settleController
        .animateWith(simulation)
        .whenCompleteOrCancel(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _controller.setDisplayMode(targetMode);
            _collapsePreviewProgress = targetProgress;
            _settleController.value = targetProgress;
            _resetDragState();
          });
        });
  }

  void _handleDemoTap(DemoEntry entry) {
    switch (entry.indexType) {
      case 8:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RangePage()));
        break;
      default:
        _showMessage('Demo ${entry.title} 待继续还原');
        break;
    }
  }
}

class _SwitchView extends StatelessWidget {
  const _SwitchView({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        width: 56,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '月',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '年',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFD4D4D4), width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Image.asset(asset, color: const Color(0xFF333333)),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.entry, required this.onTap});

  final DemoEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 78,
            child: Row(
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(entry.iconAsset),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YearOverlay extends StatelessWidget {
  const _YearOverlay({
    required this.year,
    required this.selectedMonth,
    required this.onPrevYear,
    required this.onNextYear,
    required this.onMonthTap,
  });

  final int year;
  final int selectedMonth;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onMonthTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F6FE),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 22),
                _YearHeaderButton(text: '${year - 1}', onTap: onPrevYear),
                Expanded(
                  child: Center(
                    child: Text(
                      '$year',
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _YearHeaderButton(text: '${year + 1}', onTap: onNextYear),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected = month == selectedMonth;
                return GestureDetector(
                  onTap: () => onMonthTap(month),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: const Color(0xFF128C4B),
                              width: 1.2,
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month月',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                  mainAxisSpacing: 1,
                                  crossAxisSpacing: 1,
                                ),
                            itemCount: 14,
                            itemBuilder: (context, i) {
                              return Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearHeaderButton extends StatelessWidget {
  const _YearHeaderButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
      ),
    );
  }
}
