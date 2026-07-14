import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class IOSCalendarComponentBuilder extends CalendarComponentBuilder {
  const IOSCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(const [
      '日',
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
    ], firstWeekday);
  }

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Container(
      height: height,
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(
        horizontal: kCalendarHorizontalPadding,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${month.month}月',
              style: TextStyle(
                color: isCurrent
                    ? const Color(0xFFFF0000)
                    : const Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: ColoredBox(
              color: Color(0xFFC6C6C6),
              child: SizedBox(height: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
      data.label,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return _IOSDayCellContent(data: data);
  }
}

class _IOSDayCellContent extends StatelessWidget {
  const _IOSDayCellContent({required this.data});

  final CalendarDayCellData data;

  @override
  Widget build(BuildContext context) {
    final isMuted = data.isWeekend && data.isCurrentMonth;
    final circleColor = data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    final textColor = data.isSelected
        ? Colors.white
        : data.isToday
        ? const Color(0xFFFF0000)
        : isMuted
        ? const Color(0xFF9F9F9F)
        : const Color(0xFF333333);
    return Stack(
      children: [
        if (data.showBottomDivider)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xFFC6C6C6),
              child: SizedBox(height: 0.5),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 45,
              height: 45,
              decoration: data.isSelected
                  ? BoxDecoration(color: circleColor, shape: BoxShape.circle)
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${data.date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.lunarText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(color: textColor, fontSize: 10, height: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (data.markers.isNotEmpty)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 9,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 6, height: 6),
              ),
            ),
          ),
      ],
    );
  }
}
