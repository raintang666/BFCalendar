import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class MultiSelectCalendarComponentBuilder extends CalendarComponentBuilder {
  const MultiSelectCalendarComponentBuilder();

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
    return SizedBox(height: height);
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
      data.label,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _MultiSelectCellPainter(
        dayText: '${data.date.day}',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isDisabled: data.isDisabled,
        hasScheme: data.markers.isNotEmpty,
        isSelected: data.isSelected,
        isSelectedPre: data.isSelectedPrevious,
        isSelectedNext: data.isSelectedNext,
      ),
    );
  }
}

class _MultiSelectCellPainter extends CustomPainter {
  _MultiSelectCellPainter({
    required this.dayText,
    required this.inMonth,
    required this.isToday,
    required this.isDisabled,
    required this.hasScheme,
    required this.isSelected,
    required this.isSelectedPre,
    required this.isSelectedNext,
  });

  final String dayText;
  final bool inMonth;
  final bool isToday;
  final bool isDisabled;
  final bool hasScheme;
  final bool isSelected;
  final bool isSelectedPre;
  final bool isSelectedNext;

  static const _selectedColor = Color(0xFFF17706);
  static const _schemeColor = Color(0xFF128C4B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 5 * 2;

    final selectedPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = _selectedColor;
    final schemePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _schemeColor;

    if (isSelected) {
      if (isSelectedPre) {
        if (isSelectedNext) {
          canvas.drawRect(
            Rect.fromLTRB(
              0,
              center.dy - radius,
              size.width,
              center.dy + radius,
            ),
            selectedPaint,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTRB(0, center.dy - radius, center.dx, center.dy + radius),
            selectedPaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        }
      } else {
        if (isSelectedNext) {
          canvas.drawRect(
            Rect.fromLTRB(
              center.dx,
              center.dy - radius,
              size.width,
              center.dy + radius,
            ),
            selectedPaint,
          );
        }
        canvas.drawCircle(center, radius, selectedPaint);
      }
    } else if (hasScheme) {
      canvas.drawCircle(center, radius, schemePaint);
    }

    final textColor = isSelected
        ? Colors.white
        : isToday
        ? const Color(0xFFFF0000)
        : inMonth && !isDisabled
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
  bool shouldRepaint(covariant _MultiSelectCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.hasScheme != hasScheme ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSelectedPre != isSelectedPre ||
        oldDelegate.isSelectedNext != isSelectedNext;
  }
}
