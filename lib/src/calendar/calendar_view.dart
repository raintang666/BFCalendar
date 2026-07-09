import 'dart:ui';

import 'package:flutter/material.dart';

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

class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    required this.pageOrientation,
    this.onPageChanged,
    this.onDisplayedHeightChanged,
    this.collapsePreviewProgress,
    this.previewExpandFromWeek = false,
    this.monthBodyHeightOverride,
    this.calendarHeight = 62,
    this.weekBarHeight = 46,
    this.monthHeaderHeight = 60,
  });

  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final CalendarPageOrientation pageOrientation;
  final ValueChanged<DateTime>? onPageChanged;
  final ValueChanged<double>? onDisplayedHeightChanged;
  final double? collapsePreviewProgress;
  final bool previewExpandFromWeek;
  final double? monthBodyHeightOverride;
  final double calendarHeight;
  final double weekBarHeight;
  final double monthHeaderHeight;

  @override
  State<CalendarView> createState() => _CalendarViewState();
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
              _MonthHeader(
                month: activeBaseDate.month,
                height: widget.monthHeaderHeight,
              ),
              _WeekBar(
                firstWeekday: widget.controller.firstWeekday,
                height: widget.weekBarHeight,
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
      child: PageView.builder(
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
      collapseProgress: collapseProgress,
      showMonthBody: shouldShowMonthBody,
      rowHeight: widget.calendarHeight,
      bodyHeight: bodyHeight,
      monthBodyHeightOverride: widget.monthBodyHeightOverride,
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
    setState(() {
      _verticalCurrentPage = targetPage;
      _verticalPageOffset = 0;
    });
    _syncControllerToDate(targetDate);
    widget.onPageChanged?.call(widget.controller.focusedDay);
  }

  DateTime _normalizePageTargetDate(DateTime date) {
    return CalendarDateUtils.stripTime(date);
  }

  void _syncControllerToDate(DateTime date) {
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
    required this.collapseProgress,
    required this.showMonthBody,
    required this.rowHeight,
    required this.bodyHeight,
    required this.monthBodyHeightOverride,
  });

  final DateTime anchorDate;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final double collapseProgress;
  final bool showMonthBody;
  final double rowHeight;
  final double bodyHeight;
  final double? monthBodyHeightOverride;

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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _MonthGrid(
                      days: monthDays,
                      lineCount: monthLineCount,
                      focusedMonth: focusedMonth,
                      controller: controller,
                      visibleAnchorDate: anchorDate,
                      onDaySelected: onDaySelected,
                      rowHeight: monthRowHeight,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              height: bodyHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _WeekGrid(
                  days: weekDays,
                  focusedMonth: focusedMonth,
                  controller: controller,
                  visibleAnchorDate: anchorDate,
                  onDaySelected: onDaySelected,
                  rowHeight: rowHeight,
                ),
              ),
            ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.height});

  final int month;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          '$month月',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
    required this.visibleAnchorDate,
    required this.onDaySelected,
    required this.rowHeight,
  });

  final List<DateTime> days;
  final int lineCount;
  final DateTime focusedMonth;
  final CalendarController controller;
  final DateTime visibleAnchorDate;
  final ValueChanged<DateTime> onDaySelected;
  final double rowHeight;

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
                        isSelected: CalendarDateUtils.isSameDay(
                          date,
                          visibleAnchorDate,
                        ),
                        isDisabled: controller.isDisabled(date),
                        showBottomDivider: rowIndex < lineCount - 1,
                        onTap: () => onDaySelected(date),
                      ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.focusedMonth,
    required this.controller,
    required this.visibleAnchorDate,
    required this.onDaySelected,
    required this.rowHeight,
  });

  final List<DateTime> days;
  final DateTime focusedMonth;
  final CalendarController controller;
  final DateTime visibleAnchorDate;
  final ValueChanged<DateTime> onDaySelected;
  final double rowHeight;

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
              isSelected: CalendarDateUtils.isSameDay(date, visibleAnchorDate),
              isDisabled: controller.isDisabled(date),
              showBottomDivider: false,
              onTap: () => onDaySelected(date),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.firstWeekday, required this.height});

  final int firstWeekday;
  final double height;

  @override
  Widget build(BuildContext context) {
    const labels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final ordered = switch (firstWeekday) {
      DateTime.monday => [...labels.skip(1), labels.first],
      DateTime.saturday => [labels.last, ...labels.take(6)],
      _ => labels,
    };
    return Container(
      height: height,
      color: const Color(0xFFF7F6FE),
      alignment: Alignment.center,
      child: Row(
        children: ordered
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE1E1E1),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
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
    required this.isDisabled,
    required this.showBottomDivider,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool showBottomDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = CalendarDateUtils.isSameMonth(date, focusedMonth);
    Color dayColor;
    Color lunarColor;

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (isWeekend && inMonth) {
      dayColor = const Color(0xFF489DFF);
      lunarColor = const Color(0xFF489DFF);
    } else if (!inMonth) {
      dayColor = const Color(0xFFE1E1E1);
      lunarColor = const Color(0xFFE1E1E1);
    } else {
      dayColor = const Color(0xFF333333);
      lunarColor = const Color(0xFFCFCFCF);
    }

    if (isToday) {
      dayColor = const Color(0xFFFF0000);
      lunarColor = const Color(0xFFFF0000);
    }

    if (isSelected) {
      dayColor = const Color(0xFF128C4B);
      lunarColor = const Color(0xFF128C4B);
    }

    final schemeColor = markers.isEmpty ? null : markers.first.color;
    final schemeText = markers.isEmpty ? null : markers.first.label;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth;
          final circleSize = (cellWidth).clamp(36.0, 42.0);
          final circleTop = 6.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSelected || isToday)
                Positioned(
                  top: circleTop,
                  left: (cellWidth - circleSize) / 2,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0x80CFCFCF)
                          : const Color(0xFFEAEAEA),
                    ),
                  ),
                ),
              if (schemeText != null && schemeColor != null)
                Positioned(
                  top: 4,
                  right: 0,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          schemeText,
                          style: TextStyle(
                            fontSize: 8,
                            color: schemeColor,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      color: dayColor,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 33,
                left: 2,
                right: 2,
                child: Center(
                  child: Text(
                    lunarText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 10,
                      color: lunarColor,
                      height: 1,
                    ),
                  ),
                ),
              ),
              if (showBottomDivider)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: Divider(
                    height: 0.3,
                    thickness: 0.3,
                    color: Color(0xFFE5E5E5),
                  ),
                ),
              // if (markers.isNotEmpty)
              //   Positioned(
              //     left: 0,
              //     right: 0,
              //     bottom: 0.8,
              //     child: Center(
              //       child: Container(
              //         width: 4,
              //         height: 4,
              //         decoration: BoxDecoration(
              //           color: isSelected ? Colors.white : Colors.grey,
              //           shape: BoxShape.circle,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          );
        },
      ),
    );
  }
}
