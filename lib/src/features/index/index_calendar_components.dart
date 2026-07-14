import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class IndexCalendarComponentBuilder extends CalendarComponentBuilder {
  const IndexCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: 12);

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
      painter: _IndexCellPainter(
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

class _IndexCellPainter extends CustomPainter {
  _IndexCellPainter({
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

  static const _padding = 4.0;
  static const _schemeHeight = 2.0;
  static const _schemeWidth = 8.0;
  static const _selectedColor = Color(0x80CFCFCF);

  @override
  void paint(Canvas canvas, Size size) {
    if (isSelected) {
      final selectedPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = _selectedColor;
      canvas.drawRect(
        Rect.fromLTRB(
          _padding,
          _padding,
          size.width - _padding,
          size.height - _padding,
        ),
        selectedPaint,
      );
    }

    if (schemeColor != null) {
      final schemePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = schemeColor!;
      canvas.drawRect(
        Rect.fromLTRB(
          size.width / 2 - _schemeWidth / 2,
          size.height - _schemeHeight * 2 - _padding,
          size.width / 2 + _schemeWidth / 2,
          size.height - _schemeHeight - _padding,
        ),
        schemePaint,
      );
    }

    final dayColor = isToday
        ? const Color(0xFFFF0000)
        : inMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final lunarColor = isToday
        ? const Color(0xFFFF0000)
        : inMonth
        ? const Color(0xFFCFCFCF)
        : const Color(0xFFE1E1E1);

    _paintCenteredText(
      canvas,
      text: dayText,
      color: dayColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      center: Offset(size.width / 2, size.height / 2 - size.height / 6),
      maxWidth: size.width,
    );
    _paintCenteredText(
      canvas,
      text: lunarText,
      color: lunarColor,
      fontSize: 8,
      fontWeight: FontWeight.w400,
      center: Offset(size.width / 2, size.height / 2 + size.height / 10),
      maxWidth: size.width,
    );
  }

  void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required Offset center,
    required double maxWidth,
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
    )..layout(maxWidth: maxWidth);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _IndexCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.lunarText != lunarText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.schemeColor != schemeColor;
  }
}
