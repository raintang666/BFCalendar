import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';

class DarkListCalendarPage extends StatefulWidget {
  const DarkListCalendarPage({super.key});

  @override
  State<DarkListCalendarPage> createState() => _DarkListCalendarPageState();
}

class _DarkListCalendarPageState extends State<DarkListCalendarPage> {
  static const double _monthHeaderHeight = 120;
  static const double _dayRowHeight = 46;
  static const double _monthItemHeight =
      _monthHeaderHeight + (_dayRowHeight * 6);
  static const int _minYear = 1;
  static const int _maxYear = 2099;

  late final ScrollController _scrollController;
  DateTime _selectedDay = CalendarDateUtils.stripTime(DateTime.now());
  bool _yearVisible = false;
  int _selectedTab = 1;

  int get _monthCount => (_maxYear - _minYear + 1) * 12;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _monthIndexFor(_selectedDay) * _monthItemHeight,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedTab == 0 ? 0 : 1,
                children: [const _DarkHomePanel(), _buildCalendarPanel()],
              ),
            ),
            const _BottomDivider(),
            _DarkBottomNav(
              selectedIndex: _selectedTab,
              onSelected: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPanel() {
    return Stack(
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _yearVisible = true;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedOpacity(
                opacity: _yearVisible ? 0 : 1,
                duration: const Duration(milliseconds: 280),
                child: SizedBox(
                  height: 86,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _titleForDay(_selectedDay),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemExtent: _monthItemHeight,
                itemCount: _monthCount,
                itemBuilder: (context, index) {
                  final month = _monthForIndex(index);
                  return _DarkMonthSection(
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
          ],
        ),
        if (_yearVisible)
          _DarkYearOverlay(
            year: _selectedDay.year,
            selectedDay: _selectedDay,
            onClose: () {
              setState(() {
                _yearVisible = false;
              });
            },
            onMonthSelected: (month) {
              setState(() {
                _selectedDay = DateTime(month.year, month.month, 1);
                _yearVisible = false;
              });
              _scrollToMonth(month);
            },
          ),
      ],
    );
  }

  void _scrollToMonth(DateTime month) {
    final target = _monthIndexFor(month) * _monthItemHeight;
    _scrollController.animateTo(
      target,
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

class _DarkMonthSection extends StatelessWidget {
  const _DarkMonthSection({
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
        _DarkMonthHeader(month: month),
        SizedBox(
          height: _DarkListCalendarPageState._dayRowHeight * 6,
          child: Column(
            children: List.generate(6, (row) {
              final rowDays = days.skip(row * 7).take(7).toList();
              return SizedBox(
                height: _DarkListCalendarPageState._dayRowHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: rowDays.map((day) {
                      return Expanded(
                        child: _DarkDayCell(
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

class _DarkMonthHeader extends StatelessWidget {
  const _DarkMonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _DarkListCalendarPageState._monthHeaderHeight,
      padding: const EdgeInsets.fromLTRB(32, 22, 32, 0),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_monthName(month.month)}, ${month.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
          const _BottomDivider(color: Color(0xFF999999)),
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
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DarkDayCell extends StatelessWidget {
  const _DarkDayCell({
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
        ? Colors.black
        : isCurrentMonth
        ? Colors.white
        : const Color(0xFF666666);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: isSelected
              ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
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

class _DarkYearOverlay extends StatelessWidget {
  const _DarkYearOverlay({
    required this.year,
    required this.selectedDay,
    required this.onClose,
    required this.onMonthSelected,
  });

  final int year;
  final DateTime selectedDay;
  final VoidCallback onClose;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Column(
        children: [
          SizedBox(
            height: 86,
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    '$year年',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  onPressed: onClose,
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Color(0xFFE4E4E4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const _BottomDivider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.82,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(year, index + 1);
                return _DarkYearMonthCard(
                  month: month,
                  selectedDay: selectedDay,
                  onTap: () => onMonthSelected(month),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkYearMonthCard extends StatelessWidget {
  const _DarkYearMonthCard({
    required this.month,
    required this.selectedDay,
    required this.onTap,
  });

  final DateTime month;
  final DateTime selectedDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.visibleMonthDays(
      month,
      monthViewShowMode: MonthViewShowMode.allMonth,
    );
    final isSelectedMonth =
        selectedDay.year == month.year && selectedDay.month == month.month;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelectedMonth ? Colors.white : const Color(0xFF333333),
            width: isSelectedMonth ? 1.2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _monthName(month.month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isInMonth = CalendarDateUtils.isSameMonth(day, month);
                    final isSelected =
                        CalendarDateUtils.isSameDay(day, selectedDay) &&
                        isInMonth;
                    return DecoratedBox(
                      decoration: isSelected
                          ? const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            )
                          : const BoxDecoration(),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : isInMonth
                                ? Colors.white
                                : const Color(0xFF666666),
                            fontSize: 7,
                            height: 1,
                          ),
                        ),
                      ),
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
}

class _DarkHomePanel extends StatelessWidget {
  const _DarkHomePanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              'Hello,Calendar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              'Don not forget to setup a reminder for the time you plan your day',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkBottomNav extends StatelessWidget {
  const _DarkBottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      CupertinoIcons.house_fill,
      CupertinoIcons.calendar,
      CupertinoIcons.add,
      CupertinoIcons.checkmark_square_fill,
      CupertinoIcons.gear_solid,
    ];
    return SizedBox(
      height: 62,
      child: Row(
        children: List.generate(icons.length, (index) {
          final color = index == selectedIndex
              ? const Color(0xFFE4E4E4)
              : const Color(0xFF666666);
          return Expanded(
            child: CupertinoButton(
              minimumSize: const Size(52, 62),
              padding: EdgeInsets.zero,
              onPressed: () => onSelected(index),
              child: Icon(icons[index], color: color, size: 22),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomDivider extends StatelessWidget {
  const _BottomDivider({this.color = const Color(0xFF666666)});

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
