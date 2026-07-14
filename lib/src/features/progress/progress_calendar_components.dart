import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

class ProgressCalendarComponentBuilder extends CalendarComponentBuilder {
  const ProgressCalendarComponentBuilder();

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
    final progress = int.tryParse(data.primaryMarker?.label ?? '');
    return CustomPaint(
      painter: _ProgressCellPainter(
        dayText: '${data.date.day}',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isSelected: data.isSelected,
        progress: progress,
      ),
    );
  }
}

class _ProgressCellPainter extends CustomPainter {
  _ProgressCellPainter({
    required this.dayText,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.progress,
  });

  final String dayText;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final int? progress;

  static const _selectedColor = Color(0xFFF54A00);
  static const _progressColor = Color(0xBBF54A00);
  static const _noneProgressColor = Color(0x90CFCFCF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 11 * 4;

    if (isSelected) {
      final selectedPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = _selectedColor;
      canvas.drawCircle(center, radius, selectedPaint);
    } else if (progress != null) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressValue = progress!.clamp(0, 100) / 100;
      final progressPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = _progressColor;
      final noneProgressPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = _noneProgressColor;
      final sweep = progressValue * math.pi * 2;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
      canvas.drawArc(
        rect,
        sweep - math.pi / 2,
        (math.pi * 2) - sweep,
        false,
        noneProgressPaint,
      );
    }

    final textColor = isSelected
        ? Colors.white
        : isToday
        ? const Color(0xFFFF0000)
        : inMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
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
  }

  @override
  bool shouldRepaint(covariant _ProgressCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.progress != progress;
  }
}
