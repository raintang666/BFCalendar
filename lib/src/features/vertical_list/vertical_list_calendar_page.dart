import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';

class VerticalListCalendarPage extends StatefulWidget {
  const VerticalListCalendarPage({super.key});

  @override
  State<VerticalListCalendarPage> createState() =>
      _VerticalListCalendarPageState();
}

class _VerticalListCalendarPageState extends State<VerticalListCalendarPage> {
  static const double _monthHeaderHeight = 82;
  static const double _dayRowHeight = 46;
  static const double _monthItemHeight =
      _monthHeaderHeight + (_dayRowHeight * 6);
  static const int _minYear = 1;
  static const int _maxYear = 2099;

  late final ScrollController _scrollController;
  late final CalendarMonthYearController _monthYearController;
  DateTime _selectedDay = CalendarDateUtils.stripTime(DateTime.now());

  int get _monthCount => (_maxYear - _minYear + 1) * 12;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _monthIndexFor(_selectedDay) * _monthItemHeight,
    );
    _monthYearController = CalendarMonthYearController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _monthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _monthYearController.setYearMode(true),
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _monthYearController,
                builder: (context, _) {
                  return AnimatedOpacity(
                    opacity: _monthYearController.isYearMode ? 0 : 1,
                    duration: const Duration(milliseconds: 280),
                    child: SizedBox(
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _titleForDay(_selectedDay),
                            style: const TextStyle(
                              color: Color(0xFFB66974),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: CalendarYearModeLayout(
                controller: _monthYearController,
                selectedDate: _selectedDay,
                style: CalendarYearModeStyle.vertical,
                onMonthSelected: (month) {
                  setState(() {
                    _selectedDay = DateTime(month.year, month.month, 1);
                  });
                  _scrollToMonth(month);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemExtent: _monthItemHeight,
                  itemCount: _monthCount,
                  itemBuilder: (context, index) {
                    final month = _monthForIndex(index);
                    return _VerticalMonthSection(
                      month: month,
                      selectedDay: _selectedDay,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = CalendarDateUtils.stripTime(day);
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToMonth(DateTime month) {
    _scrollController.animateTo(
      _monthIndexFor(month) * _monthItemHeight,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  int _monthIndexFor(DateTime date) {
    return ((date.year - _minYear) * 12) + date.month - 1;
  }

  DateTime _monthForIndex(int index) {
    final year = _minYear + (index ~/ 12);
    final month = (index % 12) + 1;
    return DateTime(year, month);
  }
}

class _VerticalMonthSection extends StatelessWidget {
  const _VerticalMonthSection({
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.visibleMonthDays(
      month,
      firstWeekday: DateTime.sunday,
      monthViewShowMode: MonthViewShowMode.allMonth,
    );
    return Column(
      children: [
        _VerticalMonthHeader(month: month),
        SizedBox(
          height: _VerticalListCalendarPageState._dayRowHeight * 6,
          child: Column(
            children: List.generate(6, (row) {
              final rowDays = days.skip(row * 7).take(7).toList();
              return SizedBox(
                height: _VerticalListCalendarPageState._dayRowHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: rowDays.map((day) {
                      return Expanded(
                        child: _VerticalDayCell(
                          day: day,
                          month: month,
                          selectedDay: selectedDay,
                          onTap: () => onDaySelected(day),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _VerticalMonthHeader extends StatelessWidget {
  const _VerticalMonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _VerticalListCalendarPageState._monthHeaderHeight,
      child: Stack(
        children: [
          const Positioned(
            top: 6,
            left: 22,
            right: 22,
            child: _Hairline(color: Color(0xAAE5E7E7)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 22, 32, 0),
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_monthName(month.month)}, ${month.year}',
                      style: const TextStyle(
                        color: Color(0xFFB66974),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Row(
                    children: [
                      _WeekHeaderLabel('SUN'),
                      _WeekHeaderLabel('MON'),
                      _WeekHeaderLabel('TUE'),
                      _WeekHeaderLabel('WED'),
                      _WeekHeaderLabel('THU'),
                      _WeekHeaderLabel('FRI'),
                      _WeekHeaderLabel('SAT'),
                    ],
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

class _WeekHeaderLabel extends StatelessWidget {
  const _WeekHeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE5E7E7),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _VerticalDayCell extends StatelessWidget {
  const _VerticalDayCell({
    required this.day,
    required this.month,
    required this.selectedDay,
    required this.onTap,
  });

  final DateTime day;
  final DateTime month;
  final DateTime selectedDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = CalendarDateUtils.isSameMonth(day, month);
    final isSelected = CalendarDateUtils.isSameDay(day, selectedDay);
    final textColor = isSelected
        ? Colors.white
        : isCurrentMonth
        ? const Color(0xFFA7A8AC)
        : const Color(0xFFF0F0F0);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: isSelected
              ? const BoxDecoration(
                  color: Color(0xFFB66974),
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: color);
  }
}

String _titleForDay(DateTime day) {
  return '${_weekTitle(day.weekday)}, ${day.day} ${_monthName(day.month)}';
}

String _weekTitle(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tues',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    _ => 'Sun',
  };
}

String _monthName(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'June',
    'July',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
