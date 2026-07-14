import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';
import '../../calendar/calendar_models.dart';

class SolarCalendarComponentBuilder extends CalendarComponentBuilder {
  const SolarCalendarComponentBuilder();

  static const backgroundColor = Color(0xFF009988);

  @override
  EdgeInsetsGeometry get contentPadding => EdgeInsets.zero;

  @override
  Color get weekBarBackgroundColor => backgroundColor;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(const [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
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
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _SolarCellPainter(
        dayText: '${data.date.day}',
        isSelected: data.isSelected,
        isToday: data.isToday,
        markers: data.markers,
      ),
    );
  }
}

class _SolarCellPainter extends CustomPainter {
  _SolarCellPainter({
    required this.dayText,
    required this.isSelected,
    required this.isToday,
    required this.markers,
  });

  final String dayText;
  final bool isSelected;
  final bool isToday;
  final List<CalendarMarker> markers;

  static const _backgroundColor = Color(0xFF009988);
  static const _schemeColor = Colors.white;
  static const _pointRadius = 3.6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 5 * 2;

    if (isSelected) {
      final selectedPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = Colors.white;
      canvas.drawCircle(center, radius, selectedPaint);
    } else if (markers.isNotEmpty) {
      final schemePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _schemeColor;
      canvas.drawCircle(center, radius, schemePaint);
      _paintPoint(canvas, center, radius, -10, _markerColor(0));
      _paintPoint(canvas, center, radius, -140, _markerColor(1));
      _paintPoint(canvas, center, radius, 100, _markerColor(2));
    }

    final textColor = isSelected ? _backgroundColor : Colors.white;
    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
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
  }

  Color _markerColor(int index) {
    if (markers.length > index) {
      return markers[index].color;
    }
    return Colors.white;
  }

  void _paintPoint(
    Canvas canvas,
    Offset center,
    double radius,
    double degrees,
    Color color,
  ) {
    final radians = degrees * math.pi / 180;
    final point = Offset(
      center.dx + radius * math.cos(radians),
      center.dy + radius * math.sin(radians),
    );
    final pointPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(point, _pointRadius, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _SolarCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isToday != isToday ||
        oldDelegate.markers != markers;
  }
}
