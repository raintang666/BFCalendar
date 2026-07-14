import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';

class ViewPagerCalendarPage extends StatefulWidget {
  const ViewPagerCalendarPage({super.key});

  @override
  State<ViewPagerCalendarPage> createState() => _ViewPagerCalendarPageState();
}

class _ViewPagerCalendarPageState extends State<ViewPagerCalendarPage>
    with TickerProviderStateMixin {
  static const int _minYear = 2004;
  static const int _maxYear = 2099;
  static const double _calendarItemHeight = 56;
  static const double _weekBarHeight = 40;
  static const double _gestureLockDistance = 8;
  static const _contentBackground = Color(0xFFF2F2F2);
  static const _tabs = ['热门', '头条', '时尚'];

  late final CalendarController _controller;
  late final CalendarInteractiveController _interactiveController;
  late final TabController _tabController;
  late final PageController _pageController;
  late final DateTime _today;
  int _currentTab = 0;
  Offset? _pagerPointerStart;
  bool _pagerVerticalDragLocked = false;
  bool _pagerHorizontalDragLocked = false;
  double? _lockedVerticalOffset;

  @override
  void initState() {
    super.initState();
    _today = CalendarDateUtils.stripTime(DateTime.now());
    _controller =
        CalendarController(
            focusedDay: _today,
            minDate: DateTime(_minYear, 1, 1),
            maxDate: DateTime(_maxYear, 12, 31),
            markers: _buildMarkers(_today.year, _today.month),
          )
          ..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth)
          ..setWeekStart(DateTime.saturday)
          ..setInterceptBlocked(false);
    _interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.horizontal,
    );
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_handleTabChange);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    _interactiveController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildToolbar(),
            ),
            Expanded(
              child: CalendarInteractiveView(
                controller: _controller,
                interactionController: _interactiveController,
                pageOrientation: CalendarPageOrientation.horizontal,
                componentBuilder: const MeizuCalendarComponentBuilder(),
                calendarHeight: _calendarItemHeight,
                weekBarHeight: _weekBarHeight,
                monthHeaderHeight: 0,
                contentVerticalDragLocked: _pagerHorizontalDragLocked,
                onFocusedDayChanged: (_) => _rebuildMarkersForFocusedMonth(),
                onDaySelected: _handleDaySelected,
                contentBuilder: _buildPagerContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final selected = _controller.focusedDay;
    final lunar = CalendarDateUtils.isSameDay(selected, _today)
        ? '今日'
        : LunarService.metadataForDate(selected).lunarText;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              '${selected.month}月${selected.day}日',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selected.year}',
                  style: const TextStyle(color: Colors.black, fontSize: 10),
                ),
                Text(
                  lunar,
                  style: const TextStyle(color: Colors.black, fontSize: 10),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _jumpToToday,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 28,
                        color: Colors.black,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${_today.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagerContent(
    BuildContext context,
    ScrollController scrollController,
    ScrollPhysics physics,
  ) {
    return ColoredBox(
      color: _contentBackground,
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0x00333333),
              labelColor: const Color(0xFF333333),
              unselectedLabelColor: const Color(0xFFCFCFCF),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: '热门'),
                Tab(text: '头条'),
                Tab(text: '时尚'),
              ],
            ),
          ),
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) =>
                  _handlePagerPointerDown(event, scrollController),
              onPointerMove: (event) =>
                  _handlePagerPointerMove(event, scrollController),
              onPointerUp: _handlePagerPointerEnd,
              onPointerCancel: _handlePagerPointerEnd,
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) =>
                    _handlePagerScrollUpdate(notification, scrollController),
                child: PageView.builder(
                  controller: _pageController,
                  physics: _pagerVerticalDragLocked
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: _tabs.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentTab = index;
                    });
                    _tabController.animateTo(index);
                  },
                  itemBuilder: (context, index) {
                    return _PagerArticleList(
                      tab: _tabs[index],
                      index: index,
                      controller: index == _currentTab
                          ? scrollController
                          : null,
                      physics: index == _currentTab
                          ? _pagerHorizontalDragLocked
                                ? const NeverScrollableScrollPhysics()
                                : physics
                          : const ClampingScrollPhysics(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final index = _tabController.index;
      setState(() {
        _currentTab = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handlePagerPointerDown(
    PointerDownEvent event,
    ScrollController scrollController,
  ) {
    _pagerPointerStart = event.position;
    _lockedVerticalOffset = scrollController.hasClients
        ? scrollController.offset
        : null;
    if (_pagerVerticalDragLocked || _pagerHorizontalDragLocked) {
      setState(() {
        _pagerVerticalDragLocked = false;
        _pagerHorizontalDragLocked = false;
      });
    }
  }

  void _handlePagerPointerMove(
    PointerMoveEvent event,
    ScrollController scrollController,
  ) {
    final start = _pagerPointerStart;
    if (start == null ||
        _pagerVerticalDragLocked ||
        _pagerHorizontalDragLocked) {
      return;
    }
    final delta = event.position - start;
    final dx = delta.dx.abs();
    final dy = delta.dy.abs();
    if (dy >= _gestureLockDistance && dy > dx) {
      setState(() {
        _pagerVerticalDragLocked = true;
      });
      return;
    }
    if (dx >= _gestureLockDistance && dx > dy) {
      _lockedVerticalOffset = scrollController.hasClients
          ? scrollController.offset
          : null;
      setState(() {
        _pagerHorizontalDragLocked = true;
      });
    }
  }

  bool _handlePagerScrollUpdate(
    ScrollUpdateNotification notification,
    ScrollController scrollController,
  ) {
    if (!_pagerHorizontalDragLocked ||
        notification.metrics.axis != Axis.vertical ||
        !scrollController.hasClients ||
        _lockedVerticalOffset == null) {
      return false;
    }
    final target = _lockedVerticalOffset!.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );
    if ((scrollController.offset - target).abs() > 0.5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scrollController.hasClients) {
          return;
        }
        scrollController.jumpTo(target);
      });
    }
    return true;
  }

  void _handlePagerPointerEnd(PointerEvent event) {
    _pagerPointerStart = null;
    _lockedVerticalOffset = null;
    if (!_pagerVerticalDragLocked && !_pagerHorizontalDragLocked) {
      return;
    }
    setState(() {
      _pagerVerticalDragLocked = false;
      _pagerHorizontalDragLocked = false;
    });
  }

  void _handleDaySelected(DateTime day) {
    final previousMonth = DateTime(
      _controller.focusedDay.year,
      _controller.focusedDay.month,
    );
    _controller.selectDay(day);
    final currentMonth = DateTime(
      _controller.focusedDay.year,
      _controller.focusedDay.month,
    );
    if (previousMonth != currentMonth) {
      _rebuildMarkersForFocusedMonth();
    }
  }

  void _jumpToToday() {
    _controller.selectDay(_today);
    _controller.setMarkers(_buildMarkers(_today.year, _today.month));
  }

  void _rebuildMarkersForFocusedMonth() {
    _controller.setMarkers(
      _buildMarkers(_controller.focusedDay.year, _controller.focusedDay.month),
    );
  }

  Map<DateTime, List<CalendarMarker>> _buildMarkers(int year, int month) {
    final specs = <(int, int, String)>[
      (3, 0xFF40DB25, '假'),
      (6, 0xFFE69138, '事'),
      (9, 0xFFDF1356, '议'),
      (13, 0xFFEDC56D, '记'),
      (14, 0xFFEDC56D, '记'),
      (15, 0xFFAACC44, '假'),
      (18, 0xFFBC13F0, '记'),
      (25, 0xFF13ACF0, '假'),
      (27, 0xFF13ACF0, '多'),
    ];
    return {
      for (final spec in specs)
        DateTime(year, month, spec.$1): [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
        ],
    };
  }
}

class _PagerArticleList extends StatelessWidget {
  const _PagerArticleList({
    required this.tab,
    required this.index,
    required this.controller,
    required this.physics,
  });

  final String tab;
  final int index;
  final ScrollController? controller;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.zero,
      itemCount: 18,
      itemBuilder: (context, itemIndex) {
        return _PagerArticleItem(
          title: '$tab ${(itemIndex + 1).toString().padLeft(2, '0')}',
          subtitle: 'ViewPager content',
          color: _colorFor(index, itemIndex),
          index: itemIndex,
        );
      },
    );
  }

  Color _colorFor(int tabIndex, int itemIndex) {
    const colors = [
      Color(0xFF40DB25),
      Color(0xFFE69138),
      Color(0xFFDF1356),
      Color(0xFF13ACF0),
      Color(0xFFBC13F0),
    ];
    return colors[(tabIndex + itemIndex) % colors.length];
  }
}

class _PagerArticleItem extends StatelessWidget {
  const _PagerArticleItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.index,
  });

  final String title;
  final String subtitle;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E3E3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
