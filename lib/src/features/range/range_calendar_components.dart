import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class RangeCalendarComponentBuilder extends CalendarComponentBuilder {
  const RangeCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(const [
      'S',
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
    ], firstWeekday);
  }

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(height: height);
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    final isWeekend = data.index == 0 || data.index == 6;
    return Text(
      data.label,
      style: TextStyle(
        color: isWeekend ? const Color(0xFF9F9F9F) : const Color(0xFF666666),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _RangeCellPainter(
        dayText: '${data.date.day}',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isDisabled: data.isDisabled,
        isSelected: data.isSelected,
        isRangeStart: data.isRangeStart,
        isRangeEnd: data.isRangeEnd,
        isSelectedPre: data.isSelectedPrevious,
        isSelectedNext: data.isSelectedNext,
        dimForOutOfSelectableRange: data.isOutOfSelectableRange,
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
            const Offset(0, rectDiff),
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
            const Offset(0, rectDiff),
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
            1.5 * math.pi,
            math.pi,
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
            0.5 * math.pi,
            math.pi,
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
