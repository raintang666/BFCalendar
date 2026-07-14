import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';
import 'single_select_calendar_components.dart';

class SingleSelectPage extends StatefulWidget {
  const SingleSelectPage({super.key});

  @override
  State<SingleSelectPage> createState() => _SingleSelectPageState();
}

class _SingleSelectPageState extends State<SingleSelectPage> {
  static const int _minYear = 2004;
  static const int _maxYear = 2099;
  static const double _calendarItemHeight = 56;
  static const double _weekBarHeight = 40;
  static const _contentBackground = Color(0xFFF2F2F2);

  late final CalendarController _controller;
  late final CalendarInteractiveController _interactiveController;
  late final DateTime _today;

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
          ..setSelectionMode(CalendarSelectionMode.single)
          ..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth)
          ..setWeekStart(DateTime.sunday);
    _interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.horizontal,
    );
  }

  @override
  void dispose() {
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
                componentBuilder: const SingleSelectCalendarComponentBuilder(),
                calendarHeight: _calendarItemHeight,
                weekBarHeight: _weekBarHeight,
                monthHeaderHeight: 0,
                onFocusedDayChanged: (_) => _rebuildMarkersForFocusedMonth(),
                onDaySelected: _handleDaySelected,
                contentBuilder: (context, scrollController, physics) {
                  return ColoredBox(
                    color: _contentBackground,
                    child: ListView.builder(
                      controller: scrollController,
                      physics: physics,
                      padding: EdgeInsets.zero,
                      itemCount: 18,
                      itemBuilder: (context, index) {
                        return _SingleListItem(index: index);
                      },
                    ),
                  );
                },
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

  void _handleDaySelected(DateTime day) {
    final previousMonth = DateTime(
      _controller.focusedDay.year,
      _controller.focusedDay.month,
    );
    final selected = _controller.selectDay(day);
    if (!selected) {
      _showInterceptMessage(day);
      return;
    }
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

  void _showInterceptMessage(DateTime day) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${CalendarDateUtils.formatIsoDate(day)}拦截不可点击'),
          duration: const Duration(seconds: 2),
        ),
      );
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

class _SingleListItem extends StatelessWidget {
  const _SingleListItem({required this.index});

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
            decoration: const BoxDecoration(
              color: Color(0xFF108CD4),
              shape: BoxShape.circle,
            ),
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
                  'Single ${(index + 1).toString().padLeft(2, '0')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Radio style may be very popular',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
