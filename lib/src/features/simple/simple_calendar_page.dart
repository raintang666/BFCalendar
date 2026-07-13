import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:calendarview_flutter/calendarview_flutter.dart';

import '../../calendar/date_utils_ext.dart';

class SimpleCalendarPage extends StatefulWidget {
  const SimpleCalendarPage({super.key});

  @override
  State<SimpleCalendarPage> createState() => _SimpleCalendarPageState();
}

class _SimpleCalendarPageState extends State<SimpleCalendarPage> {
  late final CalendarController _calendarController;
  late final CalendarInteractiveController _interactiveController;
  int _selectedTab = 3;

  static const List<_Plan> _plans = <_Plan>[
    _Plan('Remove trash from the desktop', '12:00-12:30'),
    _Plan('Call Friends', '13:00-13:50'),
    _Plan('Play Basketball', '14:15-16:30'),
  ];

  @override
  void initState() {
    super.initState();
    final now = CalendarDateUtils.stripTime(DateTime.now());
    _calendarController =
        CalendarController(
            focusedDay: now,
            minDate: DateTime(2004),
            markers: _buildMarkers(now.year, now.month),
          )
          ..setWeekStart(DateTime.sunday)
          ..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth)
          ..setInterceptBlocked(false);
    _interactiveController = CalendarInteractiveController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _interactiveController.dispose();
    super.dispose();
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

  void _syncMarkersForFocusedMonth() {
    _calendarController.setMarkers(
      _buildMarkers(
        _calendarController.focusedDay.year,
        _calendarController.focusedDay.month,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  const _SimpleGreeting(),
                  Expanded(
                    child: CalendarInteractiveView(
                      controller: _calendarController,
                      interactionController: _interactiveController,
                      pageOrientation: CalendarPageOrientation.horizontal,
                      calendarHeight: 52,
                      weekBarHeight: 32,
                      monthHeaderHeight: 0,
                      componentBuilder: const _SimpleCalendarComponentBuilder(),
                      onFocusedDayChanged: (_) => _syncMarkersForFocusedMonth(),
                      onDaySelected: (day) {
                        _calendarController.selectDay(day);
                        _syncMarkersForFocusedMonth();
                      },
                      contentBuilder: (context, scrollController, physics) {
                        return ListView(
                          controller: scrollController,
                          physics: physics,
                          padding: EdgeInsets.zero,
                          children: const [_TaskHeader(), _PlanList()],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _SimpleBottomTab(
              selectedIndex: _selectedTab,
              onSelected: (index) {
                if (index == 4) {
                  return;
                }
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
}

class _SimpleCalendarComponentBuilder extends CalendarComponentBuilder {
  const _SimpleCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: 16);

  @override
  Color get weekBarBackgroundColor => const Color(0xFFF4F3F9);

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    const labels = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return switch (firstWeekday) {
      DateTime.monday => [...labels.skip(1), labels.first],
      DateTime.saturday => [labels.last, ...labels.take(6)],
      _ => labels,
    };
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
      data.label,
      style: const TextStyle(
        color: Color(0xFF19181E),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    final textColor = data.isSelected
        ? Colors.white
        : data.isCurrentMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    return Center(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: data.isSelected ? const Color(0xFF8168E2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${data.date.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SimpleGreeting extends StatelessWidget {
  const _SimpleGreeting();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello,Atom',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: 'What are your ',
              children: [
                TextSpan(
                  text: 'plans',
                  style: TextStyle(color: Color(0xFF8168E2)),
                ),
                TextSpan(text: ' this month?'),
              ],
            ),
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 62,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Task for today',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _SimpleCalendarPageState._plans
          .map((plan) => _PlanTile(plan: plan))
          .toList(),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final _Plan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 30,
            alignment: Alignment.center,
            child: Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF8168E2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock_fill,
                      size: 14,
                      color: Color(0xFF9F9F9F),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plan.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9F9F9F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBottomTab extends StatelessWidget {
  const _SimpleBottomTab({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _TabIcon(
              index: 0,
              selectedIndex: selectedIndex,
              icon: CupertinoIcons.house_fill,
              onSelected: onSelected,
            ),
            _TabIcon(
              index: 1,
              selectedIndex: selectedIndex,
              icon: CupertinoIcons.square_grid_2x2_fill,
              onSelected: onSelected,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x35FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x268168E2),
                      offset: Offset(0, 8),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: CupertinoButton(
                  minimumSize: const Size(46, 46),
                  padding: EdgeInsets.zero,
                  onPressed: () => onSelected(4),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8168E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            _TabIcon(
              index: 2,
              selectedIndex: selectedIndex,
              icon: CupertinoIcons.pencil,
              onSelected: onSelected,
            ),
            _TabIcon(
              index: 3,
              selectedIndex: selectedIndex,
              icon: CupertinoIcons.calendar,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.onSelected,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        minimumSize: const Size(48, 60),
        padding: EdgeInsets.zero,
        onPressed: () => onSelected(index),
        child: Icon(
          icon,
          size: 22,
          color: selectedIndex == index
              ? const Color(0xFF8168E2)
              : const Color(0xFFCCC9EE),
        ),
      ),
    );
  }
}

class _Plan {
  const _Plan(this.title, this.time);

  final String title;
  final String time;
}
