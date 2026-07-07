import 'package:flutter/material.dart';

import 'calendar_controller.dart';
import 'calendar_models.dart';
import 'date_utils_ext.dart';

class RangeCalendarView extends StatelessWidget {
  const RangeCalendarView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    this.calendarHeight = 66,
    this.weekBarHeight = 40,
    this.horizontalPadding = 10,
    this.minRange,
    this.maxRange,
  });

  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final double calendarHeight;
  final double weekBarHeight;
  final double horizontalPadding;
  final int? minRange;
  final int? maxRange;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final monthDays = CalendarDateUtils.visibleMonthDays(
          controller.focusedDay,
          firstWeekday: controller.firstWeekday,
        );
        final height = weekBarHeight + (calendarHeight * 6);
        return SizedBox(
          height: height,
          child: Column(
            children: [
              SizedBox(height: weekBarHeight, child: const _RangeWeekBar()),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: calendarHeight,
                  ),
                  itemCount: monthDays.length,
                  itemBuilder: (context, index) {
                    final date = monthDays[index];
                    return _RangeDayCell(
                      date: date,
                      focusedMonth: controller.focusedDay,
                      range: controller.rangeSelection,
                      isToday: CalendarDateUtils.isSameDay(
                        date,
                        CalendarDateUtils.stripTime(DateTime.now()),
                      ),
                      isDisabled: controller.isDisabled(date),
                      isOutOfSelectableRange: _isOutOfSelectableRange(date),
                      onTap: () => onDaySelected(date),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isOutOfSelectableRange(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    final start = controller.rangeSelection.start;
    final end = controller.rangeSelection.end;
    if (start == null || end != null) {
      return false;
    }
    final hasMinLimit = minRange != null && minRange! > 0;
    final hasMaxLimit = maxRange != null && maxRange! > 0;
    if (!hasMinLimit && !hasMaxLimit) {
      return false;
    }
    final distance = normalized.difference(start).inDays.abs() + 1;
    if (hasMinLimit && distance < minRange!) {
      return true;
    }
    if (hasMaxLimit && distance > maxRange!) {
      return true;
    }
    return false;
  }
}

class _RangeWeekBar extends StatelessWidget {
  const _RangeWeekBar();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: i == 0 || i == 6
                        ? const Color(0xFF9F9F9F)
                        : const Color(0xFF666666),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeDayCell extends StatelessWidget {
  const _RangeDayCell({
    required this.date,
    required this.focusedMonth,
    required this.range,
    required this.isToday,
    required this.isDisabled,
    required this.isOutOfSelectableRange,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final DateRangeValue range;
  final bool isToday;
  final bool isDisabled;
  final bool isOutOfSelectableRange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRangeStart =
        range.start != null && CalendarDateUtils.isSameDay(range.start!, date);
    final isRangeEnd =
        range.end != null && CalendarDateUtils.isSameDay(range.end!, date);
    final hasCompletedRange = range.start != null && range.end != null;
    final isSelected =
        isRangeStart ||
        isRangeEnd ||
        (hasCompletedRange &&
            !date.isBefore(range.start!) &&
            !date.isAfter(range.end!));
    final previousSelected =
        hasCompletedRange &&
        !date.subtract(const Duration(days: 1)).isBefore(range.start!) &&
        !date.subtract(const Duration(days: 1)).isAfter(range.end!);
    final nextSelected =
        hasCompletedRange &&
        !date.add(const Duration(days: 1)).isBefore(range.start!) &&
        !date.add(const Duration(days: 1)).isAfter(range.end!);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: CustomPaint(
        painter: _RangeCellPainter(
          dayText: '${date.day}',
          inMonth: CalendarDateUtils.isSameMonth(date, focusedMonth),
          isToday: isToday,
          isDisabled: isDisabled,
          isSelected: isSelected,
          isRangeStart: isRangeStart,
          isRangeEnd: isRangeEnd,
          isSelectedPre: previousSelected,
          isSelectedNext: nextSelected,
          dimForOutOfSelectableRange: isOutOfSelectableRange,
        ),
      ),
    );
  }
}

class _RangeCellPainter extends CustomPainter {
  _RangeCellPainter({
    required this.dayText,
    required this.inMonth,
    required this.isToday,
    required this.isDisabled,
    required this.isSelected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isSelectedPre,
    required this.isSelectedNext,
    required this.dimForOutOfSelectableRange,
  });

  final String dayText;
  final bool inMonth;
  final bool isToday;
  final bool isDisabled;
  final bool isSelected;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isSelectedPre;
  final bool isSelectedNext;
  final bool dimForOutOfSelectableRange;

  static const _themeColor = Color(0xFF06CB93);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 50 * 28;
    const rectDiff = 4.0;

    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _themeColor;

    final selectedPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = _themeColor;

    if (isSelected) {
      if (isSelectedPre) {
        if (isSelectedNext) {
          canvas.drawLine(
            Offset(0, rectDiff),
            Offset(size.width, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(0, size.height - rectDiff),
            Offset(size.width, size.height - rectDiff),
            linePaint,
          );
        } else {
          canvas.drawLine(
            Offset(0, rectDiff),
            Offset(size.width / 2, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(0, size.height - rectDiff),
            Offset(size.width / 2, size.height - rectDiff),
            linePaint,
          );
          canvas.drawArc(
            Rect.fromLTWH(0, rectDiff, size.width, size.height - rectDiff * 2),
            1.5 * 3.1415926,
            3.1415926,
            false,
            linePaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        }
      } else {
        if (isSelectedNext) {
          canvas.drawLine(
            Offset(size.width / 2, rectDiff),
            Offset(size.width, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(size.width / 2, size.height - rectDiff),
            Offset(size.width, size.height - rectDiff),
            linePaint,
          );
          canvas.drawArc(
            Rect.fromLTWH(0, rectDiff, size.width, size.height - rectDiff * 2),
            0.5 * 3.1415926,
            3.1415926,
            false,
            linePaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        } else {
          canvas.drawCircle(center, radius, selectedPaint);
        }
      }
    }

    Color textColor;
    if (isSelected &&
        (isRangeStart || isRangeEnd || (!isSelectedPre && !isSelectedNext))) {
      textColor = Colors.white;
    } else if (!inMonth || isDisabled || dimForOutOfSelectableRange) {
      textColor = const Color(0xFFE1E1E1);
    } else if (isToday) {
      textColor = Colors.red;
    } else {
      textColor = const Color(0xFF4F4F4F);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RangeCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isRangeStart != isRangeStart ||
        oldDelegate.isRangeEnd != isRangeEnd ||
        oldDelegate.isSelectedPre != isSelectedPre ||
        oldDelegate.isSelectedNext != isSelectedNext ||
        oldDelegate.dimForOutOfSelectableRange != dimForOutOfSelectableRange;
  }
}
