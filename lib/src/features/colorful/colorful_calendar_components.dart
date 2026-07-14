import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class ColorfulCalendarComponentBuilder extends CalendarComponentBuilder {
  const ColorfulCalendarComponentBuilder();

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
      painter: _ColorfulCellPainter(
        dayText: '${data.date.day}',
        lunarText: data.lunarText,
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isSelected: data.isSelected,
        schemeColor: data.primaryMarker?.color,
      ),
    );
  }
}

class _ColorfulCellPainter extends CustomPainter {
  _ColorfulCellPainter({
    required this.dayText,
    required this.lunarText,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.schemeColor,
  });

  final String dayText;
  final String lunarText;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final Color? schemeColor;

  static const _selectedColor = Color(0xFF108CD4);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 5 * 2;
    final backgroundColor = isSelected ? _selectedColor : schemeColor;
    if (backgroundColor != null) {
      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = backgroundColor;
      canvas.drawCircle(center, radius, paint);
    }

    final hasScheme = schemeColor != null;
    final dayColor = isSelected
        ? isToday
              ? const Color(0xFFFF0000)
              : Colors.white
        : hasScheme
        ? isToday
              ? const Color(0xFFFF0000)
              : inMonth
              ? Colors.white
              : const Color(0xFFE1E1E1)
        : isToday
        ? const Color(0xFFFF0000)
        : inMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final lunarColor = isSelected
        ? isToday
              ? const Color(0xFFFF0000)
              : Colors.white
        : hasScheme
        ? Colors.white
        : isToday
        ? const Color(0xFFFF0000)
        : inMonth
        ? const Color(0xFFCFCFCF)
        : const Color(0xFFE1E1E1);

    _paintCenteredText(
      canvas,
      text: dayText,
      color: dayColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      center: Offset(center.dx, center.dy - size.height / 10),
    );
    _paintCenteredText(
      canvas,
      text: lunarText,
      color: lunarColor,
      fontSize: 10,
      fontWeight: FontWeight.w400,
      center: Offset(center.dx, center.dy + size.height / 8),
    );
  }

  void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required Offset center,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: 42);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ColorfulCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.lunarText != lunarText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.schemeColor != schemeColor;
  }
}
