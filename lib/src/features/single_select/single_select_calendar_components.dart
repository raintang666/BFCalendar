import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class SingleSelectCalendarComponentBuilder extends CalendarComponentBuilder {
  const SingleSelectCalendarComponentBuilder();

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
      painter: _SingleSelectCellPainter(
        dayText: data.isToday ? '今' : '${data.date.day}',
        selectedText: data.isToday ? '今' : '选',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isSelected: data.isSelected,
        isDisabled: data.isDisabled,
        hasScheme: data.markers.isNotEmpty,
      ),
    );
  }
}

class _SingleSelectCellPainter extends CustomPainter {
  _SingleSelectCellPainter({
    required this.dayText,
    required this.selectedText,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    required this.hasScheme,
  });

  final String dayText;
  final String selectedText;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool hasScheme;

  static const _selectedColor = Color(0xFF108CD4);
  static const _ringColor = Color(0xFF128C4B);
  static const _disabledLineColor = Color(0xFF9F9F9F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortSide = size.width < size.height ? size.width : size.height;
    final radius = shortSide / 6 * 2;
    final ringRadius = shortSide / 5 * 2;

    if (isSelected) {
      final selectedPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = _selectedColor;
      final ringPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _ringColor;
      canvas.drawCircle(center, radius, selectedPaint);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    final textColor = isSelected
        ? isToday
              ? const Color(0xFFFF0000)
              : Colors.white
        : isToday
        ? const Color(0xFFFF0000)
        : hasScheme
        ? inMonth
              ? _ringColor
              : const Color(0xFFE1E1E1)
        : inMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final textPainter = TextPainter(
      text: TextSpan(
        text: isSelected ? selectedText : dayText,
        style: TextStyle(
          color: textColor,
          fontSize: isSelected ? 17 : 15,
          fontWeight: FontWeight.w500,
          height: 1,
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

    if (isDisabled) {
      final h = shortSide < 44 ? 12.0 : 18.0;
      final linePaint = Paint()
        ..isAntiAlias = true
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _disabledLineColor;
      canvas.drawLine(
        Offset(h, h),
        Offset(size.width - h, size.height - h),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingleSelectCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.selectedText != selectedText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.hasScheme != hasScheme;
  }
}
