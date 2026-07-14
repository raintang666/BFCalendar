import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

const double kCalendarHorizontalPadding = 10;

@immutable
class CalendarWeekBarData {
  const CalendarWeekBarData({required this.firstWeekday, required this.height});

  final int firstWeekday;
  final double height;
}

@immutable
class CalendarWeekBarCellData {
  const CalendarWeekBarCellData({
    required this.label,
    required this.index,
    required this.firstWeekday,
  });

  final String label;
  final int index;
  final int firstWeekday;
}

@immutable
class CalendarDayCellData {
  const CalendarDayCellData({
    required this.date,
    required this.focusedMonth,
    required this.markers,
    required this.lunarText,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    required this.showBottomDivider,
    this.isRangeStart = false,
    this.isRangeEnd = false,
    this.isSelectedPrevious = false,
    this.isSelectedNext = false,
    this.isOutOfSelectableRange = false,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool showBottomDivider;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isSelectedPrevious;
  final bool isSelectedNext;
  final bool isOutOfSelectableRange;

  bool get isCurrentMonth => CalendarDateUtils.isSameMonth(date, focusedMonth);
  bool get isWeekend =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  CalendarMarker? get primaryMarker => markers.isEmpty ? null : markers.first;
}

abstract class CalendarComponentBuilder {
  const CalendarComponentBuilder();

  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

  Color get weekBarBackgroundColor => Colors.transparent;

  List<String> orderedWeekLabels(int firstWeekday);

  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          '${month.month}月',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data);

  Widget buildDayCell(BuildContext context, CalendarDayCellData data);

  Widget buildWeekBar(BuildContext context, CalendarWeekBarData data) {
    final labels = orderedWeekLabels(data.firstWeekday);
    return Container(
      height: data.height,
      color: weekBarBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: contentPadding,
        child: Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Center(
                child: buildWeekBarCell(
                  context,
                  CalendarWeekBarCellData(
                    label: labels[index],
                    index: index,
                    firstWeekday: data.firstWeekday,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DefaultCalendarComponentBuilder extends CalendarComponentBuilder {
  const DefaultCalendarComponentBuilder();

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(const [
      '周日',
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
    ], firstWeekday);
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
      data.label,
      style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    final textColor = data.isDisabled || !data.isCurrentMonth
        ? const Color(0xFFE1E1E1)
        : data.isSelected
        ? Colors.white
        : data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: data.isSelected
            ? const BoxDecoration(
                color: Color(0xFF128C4B),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          '${data.date.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}

List<String> calendarOrderedWeekLabels(List<String> labels, int firstWeekday) {
  return switch (firstWeekday) {
    DateTime.monday => [...labels.skip(1), labels.first],
    DateTime.saturday => [labels.last, ...labels.take(6)],
    _ => labels,
  };
}
