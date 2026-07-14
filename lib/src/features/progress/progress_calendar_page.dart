import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';

class ProgressCalendarPage extends StatefulWidget {
  const ProgressCalendarPage({super.key});

  @override
  State<ProgressCalendarPage> createState() => _ProgressCalendarPageState();
}

class _ProgressCalendarPageState extends State<ProgressCalendarPage> {
  static const int _minYear = 2004;
  static const int _maxYear = 2099;
  static const double _calendarItemHeight = 52;
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
          ..setMonthViewShowMode(MonthViewShowMode.allMonth)
          ..setWeekStart(DateTime.sunday)
          ..setInterceptBlocked(false);
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
                componentBuilder: const ProgressCalendarComponentBuilder(),
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
                        return _ProgressListItem(index: index);
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
      (3, 0xFF40DB25, '20'),
      (6, 0xFFE69138, '33'),
      (9, 0xFFDF1356, '25'),
      (13, 0xFFEDC56D, '50'),
      (14, 0xFFEDC56D, '80'),
      (15, 0xFFAACC44, '20'),
      (18, 0xFFBC13F0, '70'),
      (25, 0xFF13ACF0, '36'),
      (27, 0xFF13ACF0, '95'),
    ];
    return {
      for (final spec in specs)
        DateTime(year, month, spec.$1): [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
        ],
    };
  }
}

class _ProgressListItem extends StatelessWidget {
  const _ProgressListItem({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final value = ((index * 17 + 20) % 100).clamp(8, 96);
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
          SizedBox(
            width: 42,
            child: Text(
              '$value%',
              style: const TextStyle(
                color: Color(0xFFF54A00),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 5,
                backgroundColor: const Color(0x90CFCFCF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xBBF54A00),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Todo ${(index + 1).toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
