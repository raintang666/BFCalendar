import 'dart:ui';

import 'package:flutter/rendering.dart'
    show RenderSliverMultiBoxAdaptor, RenderSliverToBoxAdapter, RenderViewport;
import 'package:flutter/widgets.dart';

import 'calendar_canvas_grid.dart';
import 'calendar_canvas_labels.dart';
import 'calendar_components.dart';
import 'calendar_controller.dart';
import 'calendar_models.dart';
import 'date_utils_ext.dart';
import 'lunar_service.dart';

class _DirectionalPagePhysics extends ScrollPhysics {
  const _DirectionalPagePhysics({
    required this.lockedPage,
    required this.allowPrevious,
    required this.allowNext,
    super.parent,
  });

  final double lockedPage;
  final bool allowPrevious;
  final bool allowNext;

  static const double _pixelTolerance = 0.5;

  double _lockedPixels(ScrollMetrics position) {
    return lockedPage * position.viewportDimension;
  }

  @override
  _DirectionalPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _DirectionalPagePhysics(
      lockedPage: lockedPage,
      allowPrevious: allowPrevious,
      allowNext: allowNext,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (!allowPrevious && !allowNext) {
      return false;
    }
    return super.shouldAcceptUserOffset(position);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final lockedPixels = _lockedPixels(position);
    final pixels = position.pixels;
    final isDraggingTowardPrevious =
        offset < 0 && pixels <= lockedPixels + _pixelTolerance;
    final isDraggingTowardNext =
        offset > 0 && pixels >= lockedPixels - _pixelTolerance;
    if (!allowPrevious && isDraggingTowardPrevious) {
      return 0;
    }
    if (!allowNext && isDraggingTowardNext) {
      return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final lockedPixels = _lockedPixels(position);
    if (!allowPrevious && value < lockedPixels) {
      return value - lockedPixels;
    }
    if (!allowNext && value > lockedPixels) {
      return value - lockedPixels;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final lockedPixels = _lockedPixels(position);
    final pixels = position.pixels;
    final blockedPrevious =
        !allowPrevious &&
        (velocity < 0 || pixels < lockedPixels - _pixelTolerance);
    final blockedNext =
        !allowNext && (velocity > 0 || pixels > lockedPixels + _pixelTolerance);
    if (blockedPrevious || blockedNext) {
      if ((pixels - lockedPixels).abs() <= _pixelTolerance &&
          velocity.abs() <= toleranceFor(position).velocity) {
        return null;
      }
      return ScrollSpringSimulation(
        spring,
        pixels,
        lockedPixels,
        velocity,
        tolerance: toleranceFor(position),
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

/// 核心月/周日历视图。
class CalendarView extends StatefulWidget {
  /// 创建核心日历视图。
  const CalendarView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    required this.pageOrientation,
    this.componentBuilder,
    this.onPageChanged,
    this.onDisplayedHeightChanged,
    this.collapsePreviewProgress,
    this.previewExpandFromWeek = false,
    this.monthBodyHeightOverride,
    this.calendarHeight = 62,
    this.weekBarHeight = 46,
    this.monthHeaderHeight = 60,
    this.handleDaySelection = false,
    this.onRangeSelected,
    this.onSelectOutOfRange,
    this.onMultiSelected,
    this.onMultiSelectOutOfSize,
  });

  /// 日历状态控制器。
  final CalendarController controller;

  /// 日期点击回调。
  final ValueChanged<DateTime> onDaySelected;

  /// 页面滑动方向。
  final CalendarPageOrientation pageOrientation;

  /// 自定义日历样式构建器。
  final CalendarComponentBuilder? componentBuilder;

  /// 页面切换完成后的回调。
  final ValueChanged<DateTime>? onPageChanged;

  /// 当前显示高度变化回调。
  final ValueChanged<double>? onDisplayedHeightChanged;

  /// 折叠预览进度。
  final double? collapsePreviewProgress;

  /// 是否从周视图预览展开。
  final bool previewExpandFromWeek;

  /// 月视图主体高度覆盖值。
  final double? monthBodyHeightOverride;

  /// 单行日期高度。
  final double calendarHeight;

  /// 星期栏高度。
  final double weekBarHeight;

  /// 月份头高度。
  final double monthHeaderHeight;

  /// 是否由视图内部处理选择逻辑。
  final bool handleDaySelection;

  /// 范围选择回调。
  final CalendarRangeSelectedCallback? onRangeSelected;

  /// 范围选择超限回调。
  final CalendarRangeLimitViolationCallback? onSelectOutOfRange;

  /// 多选成功回调。
  final CalendarMultiSelectedCallback? onMultiSelected;

  /// 多选超出数量限制回调。
  final CalendarMultiSelectOutOfSizeCallback? onMultiSelectOutOfSize;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

/// 按月份连续滚动的日历列表。
class CalendarMonthListView extends StatefulWidget {
  /// 创建月份列表视图。
  const CalendarMonthListView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    required this.calendarHeight,
    required this.weekBarHeight,
    this.componentBuilder,
    this.onFocusedMonthChanged,
  });

  /// 日历状态控制器。
  final CalendarController controller;

  /// 日期点击回调。
  final ValueChanged<DateTime> onDaySelected;

  /// 单行日期高度。
  final double calendarHeight;

  /// 星期栏高度。
  final double weekBarHeight;

  /// 自定义日历样式构建器。
  final CalendarComponentBuilder? componentBuilder;

  /// 列表顶部的月份变化时回调，参数为该月第一天。
  final ValueChanged<DateTime>? onFocusedMonthChanged;

  @override
  State<CalendarMonthListView> createState() => _CalendarMonthListViewState();
}

class _CalendarMonthListViewState extends State<CalendarMonthListView> {
  final GlobalKey _centerMonthKey = GlobalKey();
  static const double _inlineMonthLabelHeight = 28;
  late DateTime _rangeStartMonth;
  late DateTime _rangeEndMonth;
  late DateTime _anchorMonth;
  late DateTime _lastReportedMonth;
  bool _monthCheckScheduled = false;

  CalendarComponentBuilder get _resolvedComponentBuilder {
    final override = widget.componentBuilder;
    if (override != null) {
      return override;
    }
    return const DefaultCalendarComponentBuilder();
  }

  @override
  void initState() {
    super.initState();
    _anchorMonth = DateTime(
      widget.controller.focusedDay.year,
      widget.controller.focusedDay.month,
      1,
    );
    _initMonthRange();
  }

  @override
  void didUpdateWidget(covariant CalendarMonthListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _anchorMonth = DateTime(
        widget.controller.focusedDay.year,
        widget.controller.focusedDay.month,
        1,
      );
      _initMonthRange();
    }
  }

  void _initMonthRange() {
    _lastReportedMonth = _anchorMonth;
    final minDate = widget.controller.minDate ?? DateTime(1, 1, 1);
    final maxDate = widget.controller.maxDate ?? DateTime(9999, 12, 31);
    _rangeStartMonth = DateTime(minDate.year, minDate.month, 1);
    _rangeEndMonth = DateTime(maxDate.year, maxDate.month, 1);
  }

  // The center sliver is the scroll origin. The lists on either side have
  // opposite index directions and their months can have different heights.
  DateTime? _monthAtViewportStart() {
    final center = _centerMonthKey.currentContext?.findRenderObject();
    if (center is! RenderSliverToBoxAdapter) return null;
    final viewport = center.parent! as RenderViewport;
    final pixels = viewport.offset.pixels;
    final beforeCenter = pixels < 0;
    if (!beforeCenter && pixels < center.geometry!.scrollExtent) {
      return _anchorMonth;
    }
    final list = beforeCenter
        ? viewport.childBefore(center)
        : viewport.childAfter(center);
    if (list is! RenderSliverMultiBoxAdaptor) return null;
    for (
      var child = list.firstChild;
      child != null;
      child = list.childAfter(child)
    ) {
      final top = child.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (top <= 0 && top + child.size.height > 0) {
        final distance = list.indexOf(child) + 1;
        return DateTime(
          _anchorMonth.year,
          _anchorMonth.month + (beforeCenter ? -distance : distance),
        );
      }
    }
    return null;
  }

  bool _onListNotification(ViewportNotificationMixin notification) {
    if (notification.depth == 0 &&
        widget.onFocusedMonthChanged != null &&
        !_monthCheckScheduled) {
      _monthCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monthCheckScheduled = false;
        if (!mounted) return;
        final month = _monthAtViewportStart();
        if (month != null && month != _lastReportedMonth) {
          _lastReportedMonth = month;
          widget.onFocusedMonthChanged?.call(month);
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    return false;
  }

  DateTime _monthForIndex(int index) {
    return DateTime(_rangeStartMonth.year, _rangeStartMonth.month + index, 1);
  }

  int _monthDelta(DateTime start, DateTime end) {
    return ((end.year - start.year) * 12) + (end.month - start.month);
  }

  double _bodyHeightForMonth(DateTime month) {
    final rowCount = CalendarDateUtils.visibleMonthRowCount(
      month,
      firstWeekday: widget.controller.firstWeekday,
      monthViewShowMode: widget.controller.monthViewShowMode,
    );
    return rowCount * widget.calendarHeight;
  }

  int _firstDayColumnForMonth(DateTime month) {
    final monthDays = CalendarDateUtils.visibleMonthDays(
      month,
      firstWeekday: widget.controller.firstWeekday,
      monthViewShowMode: widget.controller.monthViewShowMode,
    );
    final firstDayIndex = monthDays.indexWhere(
      (day) => CalendarDateUtils.isSameDay(day, month),
    );
    if (firstDayIndex < 0) {
      return 0;
    }
    return firstDayIndex % 7;
  }

  Widget _buildInlineMonthLabel(DateTime month) {
    final firstDayColumn = _firstDayColumnForMonth(month);
    final resolvedPadding = _resolvedComponentBuilder.contentPadding.resolve(
      Directionality.of(context),
    );
    return SizedBox(
      height: _inlineMonthLabelHeight,
      child: CalendarCanvasLabels(
        padding: resolvedPadding.copyWith(top: 0, bottom: 0),
        labels: List.generate(7, (index) {
          if (index != firstDayColumn) return null;
          return CalendarCanvasLabel(
            '${month.month}月',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthListItem(DateTime month) {
    final bodyHeight = _bodyHeightForMonth(month);
    return SizedBox(
      height: bodyHeight + _inlineMonthLabelHeight,
      child: Column(
        children: [
          _buildInlineMonthLabel(month),
          Expanded(
            child: _CalendarPage(
              anchorDate: month,
              controller: widget.controller,
              onDaySelected: widget.onDaySelected,
              componentBuilder: _resolvedComponentBuilder,
              collapseProgress: 0,
              showMonthBody: true,
              rowHeight: widget.calendarHeight,
              bodyHeight: bodyHeight,
              monthBodyHeightOverride: null,
              handleDaySelection: false,
              onRangeSelected: null,
              onSelectOutOfRange: null,
              onMultiSelected: null,
              onMultiSelectOutOfSize: null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previousCount = _monthDelta(_rangeStartMonth, _anchorMonth);
    final nextCount = _monthDelta(_anchorMonth, _rangeEndMonth);
    return Column(
      key: const ValueKey('calendar-vertical-fullscreen-list'),
      children: [
        _resolvedComponentBuilder.buildWeekBar(
          context,
          CalendarWeekBarData(
            firstWeekday: widget.controller.firstWeekday,
            height: widget.weekBarHeight,
          ),
        ),
        Expanded(
          child: NotificationListener<ViewportNotificationMixin>(
            onNotification: _onListNotification,
            child: CustomScrollView(
              center: _centerMonthKey,
              slivers: [
                SliverList.builder(
                  itemCount: previousCount,
                  itemBuilder: (context, index) {
                    final month = _monthForIndex(previousCount - index - 1);
                    return _buildMonthListItem(month);
                  },
                ),
                SliverToBoxAdapter(
                  key: _centerMonthKey,
                  child: _buildMonthListItem(_anchorMonth),
                ),
                SliverList.builder(
                  itemCount: nextCount,
                  itemBuilder: (context, index) {
                    final month = DateTime(
                      _anchorMonth.year,
                      _anchorMonth.month + index + 1,
                      1,
                    );
                    return _buildMonthListItem(month);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarViewState extends State<CalendarView> {
  static const int _verticalInitialPage = 10000;

  late final PageController _pageController;
  late final PageController _verticalPageController;
  double _pageOffset = 0;
  double _verticalPageOffset = 0;
  double? _lastReportedHeight;
  DateTime? _transitionAnchorDate;
  String? _lastHorizontalPagerSignature;
  String? _lastWarmUpSignature;
  int? _pendingHorizontalPageJump;
  late DateTime _verticalReferenceDate;
  int _verticalCurrentPage = _verticalInitialPage;
  bool _isResettingPage = false;
  Widget? _monthHeader;
  Widget? _weekBar;
  DateTime? _headerDate;

  void _invalidateChrome() {
    _monthHeader = null;
    _weekBar = null;
  }

  void _handleControllerChanged() {
    _invalidateChrome();
    _schedulePageWarmUp();
  }

  CalendarComponentBuilder get _resolvedComponentBuilder {
    final override = widget.componentBuilder;
    if (override != null) {
      return override;
    }
    return const DefaultCalendarComponentBuilder();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _pageController = PageController(initialPage: _horizontalCurrentPageIndex)
      ..addListener(_handlePageScroll);
    _verticalReferenceDate = widget.controller.focusedDay;
    _verticalPageController = PageController(initialPage: _verticalCurrentPage)
      ..addListener(_handleVerticalPageScroll);
    _schedulePageWarmUp();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    _verticalPageController
      ..removeListener(_handleVerticalPageScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _lastWarmUpSignature = null;
      _schedulePageWarmUp();
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.componentBuilder != widget.componentBuilder ||
        oldWidget.monthHeaderHeight != widget.monthHeaderHeight ||
        oldWidget.weekBarHeight != widget.weekBarHeight) {
      _invalidateChrome();
    }
    if (oldWidget.pageOrientation != widget.pageOrientation) {
      _syncPagerStateForOrientationChange();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invalidateChrome();
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients || _isResettingPage) {
      return;
    }
    final page = _pageController.page;
    if (page == null) {
      return;
    }
    final nextOffset = (page - _horizontalCurrentPageIndex).clamp(-1.0, 1.0);
    if ((nextOffset - _pageOffset).abs() < 0.0001) {
      return;
    }
    setState(() {
      _pageOffset = nextOffset;
    });
  }

  void _handleVerticalPageScroll() {
    if (!_verticalPageController.hasClients) {
      return;
    }
    final page = _verticalPageController.page;
    if (page == null) {
      return;
    }
    final nextOffset = (page - _verticalCurrentPage).clamp(-1.0, 1.0);
    if ((nextOffset - _verticalPageOffset).abs() < 0.0001) {
      return;
    }
    setState(() {
      _verticalPageOffset = nextOffset;
    });
  }

  void _syncPagerStateForOrientationChange() {
    _lastReportedHeight = null;
    final currentDate = widget.controller.focusedDay;
    if (widget.pageOrientation == CalendarPageOrientation.horizontal) {
      _transitionAnchorDate = null;
      _pageOffset = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_horizontalCurrentPageIndex);
      }
      return;
    }
    _verticalReferenceDate = currentDate;
    _verticalCurrentPage = _verticalInitialPage;
    _verticalPageOffset = 0;
    if (_verticalPageController.hasClients) {
      _verticalPageController.jumpToPage(_verticalCurrentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        _syncPagerAnchorFromController();
        _syncHorizontalPagerIndexIfNeeded();
        final collapseProgress =
            widget.collapsePreviewProgress ??
            (widget.controller.displayMode == CalendarDisplayMode.week
                ? 1.0
                : 0.0);
        final useVerticalPaging = _useVerticalPaging(collapseProgress);
        final activeBaseDate = _activeBaseDate(useVerticalPaging);
        if (_headerDate != activeBaseDate) {
          _headerDate = activeBaseDate;
          _monthHeader = null;
        }
        final bodyHeight = useVerticalPaging
            ? _buildVerticalBodyHeight(collapseProgress)
            : _buildHorizontalBodyHeight(collapseProgress);
        final totalHeight =
            widget.monthHeaderHeight + widget.weekBarHeight + bodyHeight;
        _reportDisplayedHeight(totalHeight);
        final shouldShowMonthBody =
            widget.controller.displayMode == CalendarDisplayMode.month ||
            widget.previewExpandFromWeek ||
            collapseProgress < 1;

        return SizedBox(
          height: totalHeight,
          child: Column(
            children: [
              _monthHeader ??= Builder(
                builder: (context) =>
                    _resolvedComponentBuilder.buildMonthHeader(
                      context,
                      activeBaseDate,
                      widget.monthHeaderHeight,
                    ),
              ),
              _weekBar ??= Builder(
                builder: (context) => _resolvedComponentBuilder.buildWeekBar(
                  context,
                  CalendarWeekBarData(
                    firstWeekday: widget.controller.firstWeekday,
                    height: widget.weekBarHeight,
                  ),
                ),
              ),
              SizedBox(
                height: bodyHeight,
                child: useVerticalPaging
                    ? _buildVerticalPager(
                        collapseProgress: collapseProgress,
                        shouldShowMonthBody: shouldShowMonthBody,
                        bodyHeight: bodyHeight,
                      )
                    : _buildHorizontalPager(
                        collapseProgress: collapseProgress,
                        shouldShowMonthBody: shouldShowMonthBody,
                        bodyHeight: bodyHeight,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalPager({
    required double collapseProgress,
    required bool shouldShowMonthBody,
    required double bodyHeight,
  }) {
    final relativePages = _horizontalRelativePages;
    final currentPageIndex = _horizontalCurrentPageIndex;
    final pageDates = relativePages.map(_pageDateForRelative).toList();
    final pageChildren = pageDates
        .map(
          (pageDate) => _buildCalendarPage(
            pageDate: pageDate,
            collapseProgress: collapseProgress,
            shouldShowMonthBody: shouldShowMonthBody,
            bodyHeight: bodyHeight,
          ),
        )
        .toList(growable: false);
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        _handlePageScrollEnd();
        return false;
      },
      child: PageView(
        key: ValueKey(
          'calendar-horizontal-pager-${relativePages.join(",")}-$currentPageIndex',
        ),
        controller: _pageController,
        allowImplicitScrolling: true,
        physics: const PageScrollPhysics(),
        children: pageChildren,
      ),
    );
  }

  Widget _buildVerticalPager({
    required double collapseProgress,
    required bool shouldShowMonthBody,
    required double bodyHeight,
  }) {
    final visibleDate = _verticalPageDateForIndex(_verticalCurrentPage);
    final canGoPrevious = widget.controller.canNavigateToPreviousPage(
      referenceDay: visibleDate,
      displayMode: CalendarDisplayMode.month,
    );
    final canGoNext = widget.controller.canNavigateToNextPage(
      referenceDay: visibleDate,
      displayMode: CalendarDisplayMode.month,
    );
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        _handleVerticalPageScrollEnd();
        return false;
      },
      child: Stack(
        children: [
          PageView.builder(
            key: const ValueKey('calendar-vertical-pager'),
            controller: _verticalPageController,
            allowImplicitScrolling: true,
            scrollDirection: Axis.vertical,
            physics: _DirectionalPagePhysics(
              lockedPage: _verticalCurrentPage.toDouble(),
              allowPrevious: canGoPrevious,
              allowNext: canGoNext,
              parent: const PageScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              final pageDate = _verticalPageDateForIndex(index);
              return _buildCalendarPage(
                pageDate: pageDate,
                collapseProgress: collapseProgress,
                shouldShowMonthBody: shouldShowMonthBody,
                bodyHeight: bodyHeight,
              );
            },
          ),
          const IgnorePointer(
            child: Opacity(
              key: ValueKey('calendar-vertical-pinned-month-label-opacity'),
              opacity: 0,
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPage({
    required DateTime pageDate,
    required double collapseProgress,
    required bool shouldShowMonthBody,
    required double bodyHeight,
  }) {
    return _CalendarPage(
      key: ValueKey(
        '${widget.controller.displayMode.name}-${CalendarDateUtils.formatIsoDate(pageDate)}',
      ),
      anchorDate: pageDate,
      controller: widget.controller,
      onDaySelected: widget.onDaySelected,
      componentBuilder: _resolvedComponentBuilder,
      collapseProgress: collapseProgress,
      showMonthBody: shouldShowMonthBody,
      rowHeight: widget.calendarHeight,
      bodyHeight: bodyHeight,
      monthBodyHeightOverride: widget.monthBodyHeightOverride,
      handleDaySelection: widget.handleDaySelection,
      onRangeSelected: widget.onRangeSelected,
      onSelectOutOfRange: widget.onSelectOutOfRange,
      onMultiSelected: widget.onMultiSelected,
      onMultiSelectOutOfSize: widget.onMultiSelectOutOfSize,
    );
  }

  DateTime _pageDateForRelative(int relative) {
    return widget.controller.resolvedPageAnchorForRelative(
          relative,
          referenceDay: _horizontalBaseDate,
          displayMode: widget.controller.displayMode,
        ) ??
        _horizontalBaseDate;
  }

  double _pageBodyHeight(DateTime date, double collapseProgress) {
    final monthBodyHeightOverride = widget.monthBodyHeightOverride;
    if (monthBodyHeightOverride != null &&
        widget.controller.displayMode == CalendarDisplayMode.month) {
      return lerpDouble(
        monthBodyHeightOverride,
        widget.calendarHeight,
        collapseProgress,
      )!;
    }
    final monthLineCount = CalendarDateUtils.visibleMonthRowCount(
      DateTime(date.year, date.month, 1),
      firstWeekday: widget.controller.firstWeekday,
      monthViewShowMode: widget.controller.monthViewShowMode,
    );
    final monthBodyHeight = monthLineCount * widget.calendarHeight;
    return lerpDouble(
      monthBodyHeight,
      widget.calendarHeight,
      collapseProgress,
    )!;
  }

  double _buildHorizontalBodyHeight(double collapseProgress) {
    final pageDates = _horizontalRelativePages
        .map(_pageDateForRelative)
        .toList();
    final pageBodyHeights = pageDates
        .map((date) => _pageBodyHeight(date, collapseProgress))
        .toList();
    return _interpolatedBodyHeight(
      pageBodyHeights,
      currentPageIndex: _horizontalCurrentPageIndex,
    );
  }

  double _buildVerticalBodyHeight(double collapseProgress) {
    final currentHeight = _pageBodyHeight(
      _verticalPageDateForIndex(_verticalCurrentPage),
      collapseProgress,
    );
    final offset = _verticalPageOffset;
    if (offset > 0) {
      final nextHeight = _pageBodyHeight(
        _verticalPageDateForIndex(_verticalCurrentPage + 1),
        collapseProgress,
      );
      return lerpDouble(currentHeight, nextHeight, offset)!;
    }
    if (offset < 0) {
      final previousHeight = _pageBodyHeight(
        _verticalPageDateForIndex(_verticalCurrentPage - 1),
        collapseProgress,
      );
      return lerpDouble(currentHeight, previousHeight, -offset)!;
    }
    return currentHeight;
  }

  double _interpolatedBodyHeight(
    List<double> pageBodyHeights, {
    required int currentPageIndex,
  }) {
    final offset = _pageOffset;
    if (offset > 0) {
      final nextIndex = (currentPageIndex + 1).clamp(
        0,
        pageBodyHeights.length - 1,
      );
      return lerpDouble(
        pageBodyHeights[currentPageIndex],
        pageBodyHeights[nextIndex],
        offset,
      )!;
    }
    if (offset < 0) {
      final previousIndex = (currentPageIndex - 1).clamp(
        0,
        pageBodyHeights.length - 1,
      );
      return lerpDouble(
        pageBodyHeights[currentPageIndex],
        pageBodyHeights[previousIndex],
        -offset,
      )!;
    }
    return pageBodyHeights[currentPageIndex];
  }

  bool _useVerticalPaging(double collapseProgress) {
    return widget.pageOrientation == CalendarPageOrientation.vertical &&
        widget.controller.displayMode == CalendarDisplayMode.month &&
        collapseProgress <= 0.0001;
  }

  DateTime get _horizontalBaseDate =>
      _transitionAnchorDate ?? widget.controller.focusedDay;

  List<int> get _horizontalRelativePages {
    return _horizontalRelativePagesForBase(_horizontalBaseDate);
  }

  List<int> _horizontalRelativePagesForBase(DateTime baseDate) {
    final canGoPrevious = widget.controller.canNavigateToPreviousPage(
      referenceDay: baseDate,
      displayMode: widget.controller.displayMode,
    );
    final canGoNext = widget.controller.canNavigateToNextPage(
      referenceDay: baseDate,
      displayMode: widget.controller.displayMode,
    );
    if (canGoPrevious && canGoNext) {
      return const [-1, 0, 1];
    }
    if (canGoPrevious) {
      return const [-1, 0];
    }
    if (canGoNext) {
      return const [0, 1];
    }
    return const [0];
  }

  int get _horizontalCurrentPageIndex {
    final relativePages = _horizontalRelativePages;
    return relativePages.indexOf(0);
  }

  int _horizontalCurrentPageIndexForBase(DateTime baseDate) {
    final relativePages = _horizontalRelativePagesForBase(baseDate);
    return relativePages.indexOf(0);
  }

  String get _horizontalPagerSignature {
    return '${_horizontalRelativePages.join(",")}|$_horizontalCurrentPageIndex';
  }

  DateTime _activeBaseDate(bool useVerticalPaging) {
    return useVerticalPaging
        ? _verticalPageDateForIndex(_verticalCurrentPage)
        : _horizontalBaseDate;
  }

  DateTime _verticalPageDateForIndex(int index) {
    final relative = index - _verticalInitialPage;
    final base = _verticalReferenceDate;
    if (relative == 0) {
      return base;
    }
    return widget.controller.resolvedPageAnchorForRelative(
          relative,
          referenceDay: base,
          displayMode: widget.controller.displayMode,
        ) ??
        base;
  }

  void _syncPagerAnchorFromController() {
    if (widget.pageOrientation != CalendarPageOrientation.vertical) {
      return;
    }
    if (_verticalPageOffset.abs() > 0.0001) {
      return;
    }
    final controllerDate = widget.controller.focusedDay;
    final visibleDate = _verticalPageDateForIndex(_verticalCurrentPage);
    if (CalendarDateUtils.isSameDay(visibleDate, controllerDate)) {
      return;
    }
    if (widget.controller.displayMode == CalendarDisplayMode.month &&
        CalendarDateUtils.isSameMonth(visibleDate, controllerDate)) {
      final relative = _verticalCurrentPage - _verticalInitialPage;
      _verticalReferenceDate = CalendarDateUtils.addMonths(
        controllerDate,
        -relative,
      );
      return;
    }
    _verticalReferenceDate = controllerDate;
    _verticalCurrentPage = _verticalInitialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_verticalPageController.hasClients) {
        return;
      }
      _verticalPageController.jumpToPage(_verticalCurrentPage);
    });
  }

  void _syncHorizontalPagerIndexIfNeeded() {
    final collapseProgress =
        widget.collapsePreviewProgress ??
        (widget.controller.displayMode == CalendarDisplayMode.week ? 1.0 : 0.0);
    if (_useVerticalPaging(collapseProgress)) {
      return;
    }
    if (!_pageController.hasClients) {
      return;
    }
    final pendingPage = _pendingHorizontalPageJump;
    if (pendingPage != null) {
      _pendingHorizontalPageJump = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(pendingPage);
        if (!mounted) {
          return;
        }
        setState(() {
          _pageOffset = 0;
          _isResettingPage = false;
        });
      });
      return;
    }
    final signature = _horizontalPagerSignature;
    final structureChanged = _lastHorizontalPagerSignature != signature;
    _lastHorizontalPagerSignature = signature;
    if (!structureChanged && _pageOffset.abs() > 0.0001) {
      return;
    }
    final desiredPage = _horizontalCurrentPageIndex;
    final currentPage =
        _pageController.page?.round() ?? _pageController.initialPage;
    if (currentPage == desiredPage) {
      if (structureChanged && (_pageOffset != 0 || _isResettingPage)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _pageOffset = 0;
            _isResettingPage = false;
          });
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      if (_pageOffset != 0 || _isResettingPage) {
        setState(() {
          _pageOffset = 0;
          _isResettingPage = false;
        });
      }
      _pageController.jumpToPage(desiredPage);
    });
  }

  void _reportDisplayedHeight(double height) {
    if (widget.onDisplayedHeightChanged == null) {
      return;
    }
    if (_lastReportedHeight != null &&
        (_lastReportedHeight! - height).abs() < 0.0001) {
      return;
    }
    _lastReportedHeight = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onDisplayedHeightChanged?.call(height);
    });
  }

  void _handlePageScrollEnd() {
    if (!_pageController.hasClients || _isResettingPage) {
      return;
    }
    final page = _pageController.page;
    if (page == null) {
      return;
    }
    final currentPageIndex = _horizontalCurrentPageIndex;
    final index = page.round().clamp(0, _horizontalRelativePages.length - 1);
    if (index == currentPageIndex) {
      if (_pageOffset == 0) {
        return;
      }
      setState(() {
        _pageOffset = 0;
      });
      return;
    }
    final relative = _horizontalRelativePages[index];
    final targetDate = _pageDateForRelative(relative);
    final targetPageIndex = _horizontalCurrentPageIndexForBase(targetDate);
    setState(() {
      _isResettingPage = true;
      _transitionAnchorDate = targetDate;
      _pageOffset = 0;
      _pendingHorizontalPageJump = targetPageIndex;
    });
    _pageController.jumpToPage(_horizontalCurrentPageIndex);
    if (relative < 0) {
      widget.controller.previousPage();
    } else if (relative > 0) {
      widget.controller.nextPage();
    }
    widget.onPageChanged?.call(widget.controller.focusedDay);
    if (!mounted) {
      return;
    }
    setState(() {
      _transitionAnchorDate = null;
      _pageOffset = 0;
      // Keep the reset guard until the pending jump runs after layout. At a
      // date boundary the rebuilt pager first attaches at the initial page.
    });
  }

  void _handleVerticalPageScrollEnd() {
    if (!_verticalPageController.hasClients) {
      return;
    }
    final page = _verticalPageController.page;
    if (page == null) {
      return;
    }
    final targetPage = page.round();
    if (targetPage == _verticalCurrentPage) {
      if (_verticalPageOffset == 0) {
        return;
      }
      setState(() {
        _verticalPageOffset = 0;
      });
      return;
    }
    final targetDate = _normalizePageTargetDate(
      _verticalPageDateForIndex(targetPage),
    );
    final relative = targetPage - _verticalInitialPage;
    setState(() {
      _verticalReferenceDate = CalendarDateUtils.addMonths(
        targetDate,
        -relative,
      );
      _verticalCurrentPage = targetPage;
      _verticalPageOffset = 0;
    });
    _syncControllerToDate(targetDate);
    widget.onPageChanged?.call(widget.controller.focusedDay);
  }

  DateTime _normalizePageTargetDate(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    if (widget.controller.displayMode != CalendarDisplayMode.month) {
      return normalized;
    }
    final targetMonth = DateTime(normalized.year, normalized.month, 1);
    final lastDay = CalendarDateUtils.lastDayOfMonth(targetMonth).day;
    final preferredDay = widget.controller.focusedDay.day.clamp(1, lastDay);
    return DateTime(normalized.year, normalized.month, preferredDay);
  }

  void _syncControllerToDate(DateTime date) {
    if (widget.controller.displayMode == CalendarDisplayMode.month) {
      widget.controller.jumpToMonth(date);
      return;
    }
    widget.controller.jumpToDay(date);
  }

  void _schedulePageWarmUp() {
    final displayMode = widget.controller.displayMode;
    final anchorDates = <DateTime>[
      widget.controller.focusedDay,
      if (widget.controller.resolvedPageAnchorForRelative(
            -1,
            referenceDay: widget.controller.focusedDay,
            displayMode: displayMode,
          )
          case final previous?)
        previous,
      if (widget.controller.resolvedPageAnchorForRelative(
            1,
            referenceDay: widget.controller.focusedDay,
            displayMode: displayMode,
          )
          case final next?)
        next,
    ];
    final signature =
        '$displayMode|${widget.controller.firstWeekday}|${widget.controller.monthViewShowMode}|'
        '${anchorDates.map(CalendarDateUtils.formatIsoDate).join(",")}';
    if (_lastWarmUpSignature == signature) {
      return;
    }
    _lastWarmUpSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (displayMode == CalendarDisplayMode.month) {
        for (final anchorDate in anchorDates) {
          LunarService.prefetchDates(
            CalendarDateUtils.visibleMonthDays(
              DateTime(anchorDate.year, anchorDate.month, 1),
              firstWeekday: widget.controller.firstWeekday,
              monthViewShowMode: widget.controller.monthViewShowMode,
            ),
          );
        }
        return;
      }
      for (final anchorDate in anchorDates) {
        LunarService.prefetchDates(
          CalendarDateUtils.visibleWeekDays(
            anchorDate,
            firstWeekday: widget.controller.firstWeekday,
          ),
        );
      }
    });
  }
}

class _CalendarPage extends StatelessWidget {
  const _CalendarPage({
    super.key,
    required this.anchorDate,
    required this.controller,
    required this.onDaySelected,
    required this.componentBuilder,
    required this.collapseProgress,
    required this.showMonthBody,
    required this.rowHeight,
    required this.bodyHeight,
    required this.monthBodyHeightOverride,
    required this.handleDaySelection,
    required this.onRangeSelected,
    required this.onSelectOutOfRange,
    required this.onMultiSelected,
    required this.onMultiSelectOutOfSize,
  });

  final DateTime anchorDate;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final CalendarComponentBuilder componentBuilder;
  final double collapseProgress;
  final bool showMonthBody;
  final double rowHeight;
  final double bodyHeight;
  final double? monthBodyHeightOverride;
  final bool handleDaySelection;
  final CalendarRangeSelectedCallback? onRangeSelected;
  final CalendarRangeLimitViolationCallback? onSelectOutOfRange;
  final CalendarMultiSelectedCallback? onMultiSelected;
  final CalendarMultiSelectOutOfSizeCallback? onMultiSelectOutOfSize;

  @override
  Widget build(BuildContext context) {
    final focusedMonth = DateTime(anchorDate.year, anchorDate.month, 1);
    final monthDays = CalendarDateUtils.visibleMonthDays(
      focusedMonth,
      firstWeekday: controller.firstWeekday,
      monthViewShowMode: controller.monthViewShowMode,
    );
    final weekDays = CalendarDateUtils.visibleWeekDays(
      anchorDate,
      firstWeekday: controller.firstWeekday,
    );
    final monthLineCount = CalendarDateUtils.visibleMonthRowCount(
      focusedMonth,
      firstWeekday: controller.firstWeekday,
      monthViewShowMode: controller.monthViewShowMode,
    );
    final monthBodyHeight =
        monthBodyHeightOverride ?? (monthLineCount * rowHeight);
    final monthRowHeight = monthBodyHeight / monthLineCount;
    final selectedLine = CalendarDateUtils.weekIndexInMonth(
      anchorDate,
      firstWeekday: controller.firstWeekday,
    ).clamp(0, monthLineCount - 1);
    final monthTranslation = selectedLine * monthRowHeight * collapseProgress;

    return ClipRect(
      child: showMonthBody
          ? OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: monthBodyHeight,
              maxHeight: monthBodyHeight,
              child: Transform.translate(
                offset: Offset(0, -monthTranslation),
                child: SizedBox(
                  height: monthBodyHeight,
                  child: Padding(
                    padding: componentBuilder.contentPadding,
                    child: _CalendarGrid(
                      days: monthDays,
                      lineCount: monthLineCount,
                      hideOutsideMonth: controller.onlyCurrentMonth,
                      focusedMonth: focusedMonth,
                      controller: controller,
                      onDaySelected: onDaySelected,
                      componentBuilder: componentBuilder,
                      rowHeight: monthRowHeight,
                      handleDaySelection: handleDaySelection,
                      onRangeSelected: onRangeSelected,
                      onSelectOutOfRange: onSelectOutOfRange,
                      onMultiSelected: onMultiSelected,
                      onMultiSelectOutOfSize: onMultiSelectOutOfSize,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              height: bodyHeight,
              child: Padding(
                padding: componentBuilder.contentPadding,
                child: _CalendarGrid(
                  days: weekDays,
                  lineCount: 1,
                  hideOutsideMonth: false,
                  focusedMonth: focusedMonth,
                  controller: controller,
                  onDaySelected: onDaySelected,
                  componentBuilder: componentBuilder,
                  rowHeight: rowHeight,
                  handleDaySelection: handleDaySelection,
                  onRangeSelected: onRangeSelected,
                  onSelectOutOfRange: onSelectOutOfRange,
                  onMultiSelected: onMultiSelected,
                  onMultiSelectOutOfSize: onMultiSelectOutOfSize,
                ),
              ),
            ),
    );
  }
}

class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({
    required this.days,
    required this.lineCount,
    required this.hideOutsideMonth,
    required this.focusedMonth,
    required this.controller,
    required this.onDaySelected,
    required this.componentBuilder,
    required this.rowHeight,
    required this.handleDaySelection,
    required this.onRangeSelected,
    required this.onSelectOutOfRange,
    required this.onMultiSelected,
    required this.onMultiSelectOutOfSize,
  });

  final List<DateTime> days;
  final int lineCount;
  final bool hideOutsideMonth;
  final DateTime focusedMonth;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final CalendarComponentBuilder componentBuilder;
  final double rowHeight;
  final bool handleDaySelection;
  final CalendarRangeSelectedCallback? onRangeSelected;
  final CalendarRangeLimitViolationCallback? onSelectOutOfRange;
  final CalendarMultiSelectedCallback? onMultiSelected;
  final CalendarMultiSelectOutOfSizeCallback? onMultiSelectOutOfSize;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  List<CalendarDayCellData?> _cells = const [];
  Map<int, int> _markerTotals = const {};
  List<Widget?> _dayWidgets = const [];
  List<CustomPainter?> _painters = const [];
  bool _needsCellUpdate = true;
  DateTime? _today;
  Widget? _grid;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_invalidateCells);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _needsCellUpdate = true;
  }

  @override
  void didUpdateWidget(covariant _CalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowHeight != widget.rowHeight) _grid = null;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_invalidateCells);
      widget.controller.addListener(_invalidateCells);
      _needsCellUpdate = true;
    }
    if (oldWidget.focusedMonth != widget.focusedMonth ||
        oldWidget.lineCount != widget.lineCount ||
        oldWidget.hideOutsideMonth != widget.hideOutsideMonth ||
        oldWidget.componentBuilder != widget.componentBuilder ||
        oldWidget.days.length != widget.days.length ||
        oldWidget.days.first != widget.days.first ||
        oldWidget.days.last != widget.days.last) {
      _needsCellUpdate = true;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_invalidateCells);
    super.dispose();
  }

  void _invalidateCells() {
    setState(() => _needsCellUpdate = true);
  }

  void _updateCells() {
    final controller = widget.controller;
    final today = CalendarDateUtils.stripTime(DateTime.now());
    if (!_needsCellUpdate && _today == today) {
      return;
    }
    _today = today;
    _needsCellUpdate = false;
    _grid = null;
    final markerMap = controller.markers;
    final indexedMarkers = markerMap is CalendarMarkerIndex;
    // The exact default builder only needs markers for Canvas semantics.
    // For a plain map, custom overrides get a complete list snapshot.
    final summarizeMarkers =
        !indexedMarkers &&
        widget.componentBuilder.runtimeType == DefaultCalendarComponentBuilder;
    Map<int, int>? markerTotals;
    _cells = List.generate(widget.days.length, (index) {
      final date = widget.days[index];
      if (widget.hideOutsideMonth &&
          !CalendarDateUtils.isSameMonth(date, widget.focusedMonth)) {
        return null;
      }
      final markers = markerMap[date] ?? const <CalendarMarker>[];
      Iterable<CalendarMarker> snapshot = markers;
      if (summarizeMarkers &&
          markers.length > CalendarCanvasGrid.maxAnnouncedMarkers) {
        (markerTotals ??= {})[index] = markers.length;
        snapshot = markers.take(CalendarCanvasGrid.maxAnnouncedMarkers);
      }
      return CalendarDayCellData(
        date: date,
        focusedMonth: widget.focusedMonth,
        markers: switch (markers) {
          _ when markers.isEmpty => const [],
          _ when indexedMarkers => markers,
          _ => List.unmodifiable(snapshot),
        },
        lunarText: LunarService.metadataForDate(date).lunarText,
        isToday: date == today,
        isSelected: controller.isSelected(date),
        isRangeStart: controller.isRangeStart(date),
        isRangeEnd: controller.isRangeEnd(date),
        isSelectedPrevious: _isSelectedAdjacent(date, -1),
        isSelectedNext: _isSelectedAdjacent(date, 1),
        isOutOfSelectableRange:
            controller.rangeSelectionLimitViolation(date) != null,
        isDisabled: controller.isDisabled(date),
        showBottomDivider: index ~/ 7 < widget.lineCount - 1,
      );
    });
    _markerTotals = markerTotals ?? const {};
    _updateDayWidgets();
  }

  void _updateDayWidgets() {
    _dayWidgets = List.filled(_cells.length, null);
    _painters = List.filled(_cells.length, null);
    for (var index = 0; index < _cells.length; index++) {
      final cell = _cells[index];
      if (cell == null) continue;
      final child = widget.componentBuilder.buildDayCell(context, cell);
      // Preserve custom layout, keys, children, layers and semantics in place.
      if (child is CustomPaint &&
          child.key == null &&
          child.child == null &&
          child.painter != null &&
          child.foregroundPainter == null &&
          !child.isComplex &&
          !child.willChange &&
          child.painter!.semanticsBuilder == null) {
        _painters[index] = child.painter;
      } else {
        _dayWidgets[index] = child;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateCells();
    return _grid ??= SizedBox(
      height: widget.lineCount * widget.rowHeight,
      child: CalendarCanvasGrid(
        cells: _cells,
        painters: _painters,
        dayWidgets: _dayWidgets,
        rowHeight: widget.rowHeight,
        onDaySelected: _handleDayTap,
        markerTotals: _markerTotals,
      ),
    );
  }

  bool _isSelectedAdjacent(DateTime date, int dayOffset) {
    if (widget.controller.selectionMode == CalendarSelectionMode.range &&
        widget.controller.rangeSelection.end == null) {
      return false;
    }
    return widget.controller.isSelected(
      CalendarDateUtils.addDays(date, dayOffset),
    );
  }

  void _handleDayTap(DateTime date) {
    if (widget.controller.isDisabled(date)) return;
    if (widget.handleDaySelection) {
      if (widget.controller.selectionMode == CalendarSelectionMode.multi &&
          widget.controller.isMultiSelectOutOfSize(date)) {
        widget.onMultiSelectOutOfSize?.call(
          date,
          widget.controller.maxMultiSelectSize,
        );
        return;
      }
      final violation = widget.controller.rangeSelectionLimitViolation(date);
      if (violation != null) {
        widget.onSelectOutOfRange?.call(date, violation);
        return;
      }
      final selected = widget.controller.selectDay(date);
      if (!selected) {
        return;
      }
      if (widget.controller.selectionMode == CalendarSelectionMode.range) {
        widget.onRangeSelected?.call(widget.controller.rangeSelection);
      } else if (widget.controller.selectionMode ==
          CalendarSelectionMode.multi) {
        widget.onMultiSelected?.call(
          date,
          widget.controller.selectedMultiDates.length,
          widget.controller.maxMultiSelectSize,
        );
      }
    }
    widget.onDaySelected(date);
  }
}
