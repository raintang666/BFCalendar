import 'dart:ui';

import 'package:flutter/material.dart';

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

  /// 当前聚焦月份变化回调。
  final ValueChanged<DateTime>? onFocusedMonthChanged;

  @override
  State<CalendarMonthListView> createState() => _CalendarMonthListViewState();
}

class _CalendarMonthListViewState extends State<CalendarMonthListView> {
  final GlobalKey _centerMonthKey = GlobalKey();
  static const double _inlineMonthLabelHeight = 28;
  late DateTime _rangeStartMonth;
  late DateTime _rangeEndMonth;
  late DateTime _focusedMonth;

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
    _focusedMonth = DateTime(
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
      _focusedMonth = DateTime(
        widget.controller.focusedDay.year,
        widget.controller.focusedDay.month,
        1,
      );
      _initMonthRange();
    }
  }

  void _initMonthRange() {
    final minDate = widget.controller.minDate ?? DateTime(1, 1, 1);
    final maxDate = widget.controller.maxDate ?? DateTime(9999, 12, 31);
    _rangeStartMonth = DateTime(minDate.year, minDate.month, 1);
    _rangeEndMonth = DateTime(maxDate.year, maxDate.month, 1);
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
    const textColor = Color(0xFF333333);
    final resolvedPadding = _resolvedComponentBuilder.contentPadding.resolve(
      Directionality.of(context),
    );
    return SizedBox(
      height: _inlineMonthLabelHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: resolvedPadding.left,
          right: resolvedPadding.right,
        ),
        child: Row(
          children: List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: index == firstDayColumn
                    ? Text(
                        '${month.month}月',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ),
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
    final previousCount = _monthDelta(_rangeStartMonth, _focusedMonth);
    final nextCount = _monthDelta(_focusedMonth, _rangeEndMonth);
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
                child: _buildMonthListItem(_focusedMonth),
              ),
              SliverList.builder(
                itemCount: nextCount,
                itemBuilder: (context, index) {
                  final month = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + index + 1,
                    1,
                  );
                  return _buildMonthListItem(month);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarViewState extends State<CalendarView> {
  static const int _verticalInitialPage = 10000;

  late PageController _pageController;
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
    _createHorizontalPageController(initialPage: _horizontalCurrentPageIndex);
    _verticalReferenceDate = widget.controller.focusedDay;
    _verticalPageController = PageController(initialPage: _verticalCurrentPage)
      ..addListener(_handleVerticalPageScroll);
    _schedulePageWarmUp();
  }

  void _createHorizontalPageController({required int initialPage}) {
    _pageController = PageController(initialPage: initialPage)
      ..addListener(_handlePageScroll);
  }

  void _resetHorizontalPageController({required int initialPage}) {
    final oldController = _pageController;
    oldController.removeListener(_handlePageScroll);
    _createHorizontalPageController(initialPage: initialPage);
    oldController.dispose();
  }

  @override
  void dispose() {
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
    if (oldWidget.pageOrientation != widget.pageOrientation) {
      _syncPagerStateForOrientationChange();
    }
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
        _schedulePageWarmUp();
        final collapseProgress =
            widget.collapsePreviewProgress ??
            (widget.controller.displayMode == CalendarDisplayMode.week
                ? 1.0
                : 0.0);
        final useVerticalPaging = _useVerticalPaging(collapseProgress);
        final activeBaseDate = _activeBaseDate(useVerticalPaging);
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
              _resolvedComponentBuilder.buildMonthHeader(
                context,
                activeBaseDate,
                widget.monthHeaderHeight,
              ),
              _resolvedComponentBuilder.buildWeekBar(
                context,
                CalendarWeekBarData(
                  firstWeekday: widget.controller.firstWeekday,
                  height: widget.weekBarHeight,
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
    if (widget.pageOrientation != CalendarPageOrientation.horizontal) {
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
    _resetHorizontalPageController(
      initialPage: _horizontalCurrentPageIndexForBase(
        widget.controller.focusedDay,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _transitionAnchorDate = null;
      _pendingHorizontalPageJump = null;
      _pageOffset = 0;
      _isResettingPage = false;
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
                    child: _MonthGrid(
                      days: monthDays,
                      lineCount: monthLineCount,
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
                child: _WeekGrid(
                  days: weekDays,
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.days,
    required this.lineCount,
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
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(lineCount, (rowIndex) {
        final rowDays = days.skip(rowIndex * 7).take(7).toList();
        return SizedBox(
          height: rowHeight,
          child: Row(
            children: List.generate(7, (columnIndex) {
              final date = rowDays[columnIndex];
              final shouldHide =
                  controller.monthViewShowMode ==
                      MonthViewShowMode.onlyCurrentMonth &&
                  !CalendarDateUtils.isSameMonth(date, focusedMonth);
              return Expanded(
                child: shouldHide
                    ? const SizedBox.expand()
                    : _CalendarDayCell(
                        date: date,
                        focusedMonth: focusedMonth,
                        markers: controller.markers[date] ?? const [],
                        lunarText: LunarService.metadataForDate(date).lunarText,
                        isToday: CalendarDateUtils.isSameDay(
                          date,
                          CalendarDateUtils.stripTime(DateTime.now()),
                        ),
                        isSelected: controller.isSelected(date),
                        isRangeStart: controller.isRangeStart(date),
                        isRangeEnd: controller.isRangeEnd(date),
                        isSelectedPrevious: _isSelectedAdjacent(
                          date,
                          const Duration(days: -1),
                        ),
                        isSelectedNext: _isSelectedAdjacent(
                          date,
                          const Duration(days: 1),
                        ),
                        isOutOfSelectableRange:
                            controller.rangeSelectionLimitViolation(date) !=
                            null,
                        isDisabled: controller.isDisabled(date),
                        componentBuilder: componentBuilder,
                        showBottomDivider: rowIndex < lineCount - 1,
                        onTap: () => _handleDayTap(date),
                      ),
              );
            }),
          ),
        );
      }),
    );
  }

  bool _isSelectedAdjacent(DateTime date, Duration offset) {
    if (controller.selectionMode == CalendarSelectionMode.range &&
        controller.rangeSelection.end == null) {
      return false;
    }
    return controller.isSelected(date.add(offset));
  }

  void _handleDayTap(DateTime date) {
    if (handleDaySelection) {
      if (controller.selectionMode == CalendarSelectionMode.multi &&
          controller.isMultiSelectOutOfSize(date)) {
        onMultiSelectOutOfSize?.call(date, controller.maxMultiSelectSize);
        return;
      }
      final violation = controller.rangeSelectionLimitViolation(date);
      if (violation != null) {
        onSelectOutOfRange?.call(date, violation);
        return;
      }
      final selected = controller.selectDay(date);
      if (!selected) {
        return;
      }
      if (controller.selectionMode == CalendarSelectionMode.range) {
        onRangeSelected?.call(controller.rangeSelection);
      } else if (controller.selectionMode == CalendarSelectionMode.multi) {
        onMultiSelected?.call(
          date,
          controller.selectedMultiDates.length,
          controller.maxMultiSelectSize,
        );
      }
    }
    onDaySelected(date);
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: days.map((date) {
          return Expanded(
            child: _CalendarDayCell(
              date: date,
              focusedMonth: focusedMonth,
              markers: controller.markers[date] ?? const [],
              lunarText: LunarService.metadataForDate(date).lunarText,
              isToday: CalendarDateUtils.isSameDay(
                date,
                CalendarDateUtils.stripTime(DateTime.now()),
              ),
              isSelected: controller.isSelected(date),
              isRangeStart: controller.isRangeStart(date),
              isRangeEnd: controller.isRangeEnd(date),
              isSelectedPrevious: _isSelectedAdjacent(
                date,
                const Duration(days: -1),
              ),
              isSelectedNext: _isSelectedAdjacent(
                date,
                const Duration(days: 1),
              ),
              isOutOfSelectableRange:
                  controller.rangeSelectionLimitViolation(date) != null,
              isDisabled: controller.isDisabled(date),
              componentBuilder: componentBuilder,
              showBottomDivider: false,
              onTap: () => _handleDayTap(date),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isSelectedAdjacent(DateTime date, Duration offset) {
    if (controller.selectionMode == CalendarSelectionMode.range &&
        controller.rangeSelection.end == null) {
      return false;
    }
    return controller.isSelected(date.add(offset));
  }

  void _handleDayTap(DateTime date) {
    if (handleDaySelection) {
      if (controller.selectionMode == CalendarSelectionMode.multi &&
          controller.isMultiSelectOutOfSize(date)) {
        onMultiSelectOutOfSize?.call(date, controller.maxMultiSelectSize);
        return;
      }
      final violation = controller.rangeSelectionLimitViolation(date);
      if (violation != null) {
        onSelectOutOfRange?.call(date, violation);
        return;
      }
      final selected = controller.selectDay(date);
      if (!selected) {
        return;
      }
      if (controller.selectionMode == CalendarSelectionMode.range) {
        onRangeSelected?.call(controller.rangeSelection);
      } else if (controller.selectionMode == CalendarSelectionMode.multi) {
        onMultiSelected?.call(
          date,
          controller.selectedMultiDates.length,
          controller.maxMultiSelectSize,
        );
      }
    }
    onDaySelected(date);
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.focusedMonth,
    required this.markers,
    required this.lunarText,
    required this.isToday,
    required this.isSelected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isSelectedPrevious,
    required this.isSelectedNext,
    required this.isOutOfSelectableRange,
    required this.isDisabled,
    required this.componentBuilder,
    required this.showBottomDivider,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isSelectedPrevious;
  final bool isSelectedNext;
  final bool isOutOfSelectableRange;
  final bool isDisabled;
  final CalendarComponentBuilder componentBuilder;
  final bool showBottomDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = componentBuilder.buildDayCell(
      context,
      CalendarDayCellData(
        date: date,
        focusedMonth: focusedMonth,
        markers: markers,
        lunarText: lunarText,
        isToday: isToday,
        isSelected: isSelected,
        isDisabled: isDisabled,
        showBottomDivider: showBottomDivider,
        isRangeStart: isRangeStart,
        isRangeEnd: isRangeEnd,
        isSelectedPrevious: isSelectedPrevious,
        isSelectedNext: isSelectedNext,
        isOutOfSelectableRange: isOutOfSelectableRange,
      ),
    );
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(child: child),
    );
  }
}
