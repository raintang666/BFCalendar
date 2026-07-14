import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';
import '../../calendar/lunar_service.dart';

class FullCalendarPage extends StatefulWidget {
  const FullCalendarPage({super.key});

  @override
  State<FullCalendarPage> createState() => _FullCalendarPageState();
}

class _FullCalendarPageState extends State<FullCalendarPage> {
  static const int _minYear = 2004;
  static const int _maxYear = 2020;
  static const double _weekBarHeight = 40;
  static const double _monthPageCount = (_maxYear - _minYear + 1) * 12;
  static const List<String> _weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

  late final PageController _pageController;
  late final CalendarMonthYearController _monthYearController;
  DateTime _selectedDay = CalendarDateUtils.stripTime(DateTime.now());
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _clampDay(_selectedDay);
    _currentPage = _monthIndexFor(_selectedDay);
    _pageController = PageController(initialPage: _currentPage);
    _monthYearController = CalendarMonthYearController();
  }

  @override
  void dispose() {
    _monthYearController.dispose();
    _pageController.dispose();
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
            _buildToolbar(),
            Expanded(
              child: CalendarYearModeLayout(
                controller: _monthYearController,
                selectedDate: _selectedDay,
                minDate: DateTime(_minYear, 1, 1),
                maxDate: DateTime(_maxYear, 12, 31),
                style: CalendarYearModeStyle.vertical,
                onMonthSelected: (month) {
                  final next = _sameDayInMonth(_selectedDay, month);
                  setState(() {
                    _selectedDay = next;
                    _currentPage = _monthIndexFor(next);
                  });
                  _pageController.jumpToPage(_currentPage);
                },
                child: Column(
                  children: [
                    const _FullWeekBar(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: _monthPageCount.toInt(),
                        onPageChanged: (page) {
                          final month = _monthForIndex(page);
                          setState(() {
                            _currentPage = page;
                            _selectedDay = _sameDayInMonth(_selectedDay, month);
                          });
                        },
                        itemBuilder: (context, index) {
                          return _FullMonthGrid(
                            month: _monthForIndex(index),
                            selectedDay: _selectedDay,
                            markers: _buildMarkers(_monthForIndex(index)),
                            onDaySelected: (day) {
                              setState(() {
                                _selectedDay = CalendarDateUtils.stripTime(day);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final selected = _selectedDay;
    final lunar =
        CalendarDateUtils.isSameDay(
          selected,
          CalendarDateUtils.stripTime(DateTime.now()),
        )
        ? '今日'
        : LunarService.metadataForDate(selected).lunarText;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _monthYearController.showYearMode();
            },
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  _monthYearController.isYearMode
                      ? '${_monthYearController.visibleYear}'
                      : '${selected.month}月${selected.day}日',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                if (!_monthYearController.isYearMode) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 28,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selected.year}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          lunar,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _scrollToToday,
            child: _TodayButton(day: DateTime.now().day),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _scrollToToday() {
    final today = _clampDay(CalendarDateUtils.stripTime(DateTime.now()));
    final page = _monthIndexFor(today);
    setState(() {
      _selectedDay = today;
      _currentPage = page;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  DateTime _clampDay(DateTime day) {
    if (day.year < _minYear) {
      return DateTime(_minYear, 1, 1);
    }
    if (day.year > _maxYear) {
      return DateTime(_maxYear, 12, 31);
    }
    return day;
  }

  DateTime _sameDayInMonth(DateTime source, DateTime month) {
    final lastDay = CalendarDateUtils.daysInMonth(month);
    return DateTime(month.year, month.month, source.day.clamp(1, lastDay));
  }

  int _monthIndexFor(DateTime date) {
    final clampedYear = date.year.clamp(_minYear, _maxYear);
    return ((clampedYear - _minYear) * 12) + date.month - 1;
  }

  DateTime _monthForIndex(int index) {
    final year = _minYear + (index ~/ 12);
    final month = (index % 12) + 1;
    return DateTime(year, month);
  }

  Map<int, List<CalendarMarker>> _buildMarkers(DateTime month) {
    final specs = <(int, int, String)>[
      (3, 0xFF40DB25, '假'),
      (6, 0xFFE69138, '事'),
      (9, 0xFFDF1356, '议'),
      (13, 0xFFEDC56D, '记'),
      (14, 0xFFEDC56D, '记'),
      (15, 0xFFAACC44, '假'),
      (18, 0xFFBC13F0, '记'),
      (22, 0xFFDF1356, '议'),
      (25, 0xFF13ACF0, '假'),
      (27, 0xFF13ACF0, '多'),
    ];
    final lastDay = CalendarDateUtils.daysInMonth(month);
    return {
      for (final spec in specs.where((spec) => spec.$1 <= lastDay))
        spec.$1: [
          CalendarMarker(label: spec.$3, color: Color(spec.$2)),
          CalendarMarker(
            label: '节',
            color: spec.$1.isEven
                ? const Color(0xFF00CD00)
                : const Color(0xFFD15FEE),
          ),
          CalendarMarker(
            label: '记',
            color: spec.$1.isEven
                ? const Color(0xFF660000)
                : const Color(0xFF4169E1),
          ),
        ],
    };
  }
}

class _FullWeekBar extends StatelessWidget {
  const _FullWeekBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _FullCalendarPageState._weekBarHeight,
      child: Row(
        children: _FullCalendarPageState._weekLabels.map((label) {
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFFE1E1E1), fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FullMonthGrid extends StatelessWidget {
  const _FullMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.markers,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<int, List<CalendarMarker>> markers;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.visibleMonthDays(
      month,
      firstWeekday: DateTime.sunday,
      monthViewShowMode: MonthViewShowMode.allMonth,
    );
    return Column(
      children: List.generate(6, (row) {
        final rowDays = days.skip(row * 7).take(7).toList();
        return Expanded(
          child: Row(
            children: rowDays.map((day) {
              return Expanded(
                child: _FullDayCell(
                  day: day,
                  month: month,
                  selectedDay: selectedDay,
                  markers: markers[day.day] ?? const [],
                  onTap: () => onDaySelected(day),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

class _FullDayCell extends StatelessWidget {
  const _FullDayCell({
    required this.day,
    required this.month,
    required this.selectedDay,
    required this.markers,
    required this.onTap,
  });

  final DateTime day;
  final DateTime month;
  final DateTime selectedDay;
  final List<CalendarMarker> markers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = CalendarDateUtils.isSameDay(day, selectedDay);
    final isToday = CalendarDateUtils.isSameDay(
      day,
      CalendarDateUtils.stripTime(DateTime.now()),
    );
    final isCurrentMonth = CalendarDateUtils.isSameMonth(day, month);
    final dayColor = isSelected
        ? const Color(0xFF333333)
        : isToday
        ? Colors.red
        : isCurrentMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final lunarColor = isSelected
        ? const Color(0xFF999999)
        : isToday && isCurrentMonth
        ? Colors.red
        : isCurrentMonth
        ? const Color(0xFFCFCFCF)
        : const Color(0xFFE1E1E1);
    final lunar = LunarService.metadataForDate(day).lunarText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x88EFEFEF), width: 0.5),
          color: isSelected ? Colors.white : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 14,
                    offset: Offset(2, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Text(
                '${day.day}',
                textAlign: TextAlign.center,
                style: TextStyle(color: dayColor, fontSize: 18, height: 1),
              ),
            ),
            Positioned(
              top: 48,
              left: 2,
              right: 2,
              child: Text(
                lunar,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
                style: TextStyle(color: lunarColor, fontSize: 10, height: 1),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: markers.take(3).map((marker) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 10,
                      height: 4,
                      child: ColoredBox(color: marker.color),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0x11000000),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '$day',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
