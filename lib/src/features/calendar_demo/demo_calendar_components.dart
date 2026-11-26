import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/calendar_canvas_labels.dart';
import '../../calendar/calendar_components.dart';
import '../../calendar/calendar_retained_day_painter.dart';
import '../../calendar/calendar_text_layout.dart';

class CustomCalendarComponentBuilder extends CalendarComponentBuilder {
  const CustomCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => const Color(0xFFF7F6FE);

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
    return CalendarCanvasLabel(
      data.label,
      style: const TextStyle(color: Color(0xFFE1E1E1), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _CustomDayPainter(data, CalendarCanvasText.of(context)),
    );
  }
}

class MeizuCalendarComponentBuilder extends CalendarComponentBuilder {
  const MeizuCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(const [
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ], firstWeekday);
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return CalendarCanvasLabel(
      data.label,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _MeizuDayPainter(data, CalendarCanvasText.of(context)),
    );
  }
}

class _CustomDayPainter extends CalendarRetainedDayPainter {
  const _CustomDayPainter(this.data, this.text);

  final CalendarDayCellData data;
  final CalendarCanvasText text;

  Color get _dayColor => switch (data) {
    _ when data.isSelected => const Color(0xFF128C4B),
    _ when data.isToday => const Color(0xFFFF0000),
    _ when !data.isCurrentMonth => const Color(0xFFE1E1E1),
    _ when data.isWeekend => const Color(0xFF489DFF),
    _ => const Color(0xFF333333),
  };
  TextPainter _dayLine(double width) => text.layout(
    '${data.date.day}',
    TextStyle(
      color: _dayColor,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      height: 1,
    ),
    width,
  );

  TextPainter _lunarLine(double width) => text.layout(
    data.lunarText,
    TextStyle(
      color: _dayColor == const Color(0xFF333333)
          ? const Color(0xFFCFCFCF)
          : _dayColor,
      fontSize: 10,
      height: 1,
    ),
    width - 4,
    maxLines: 1,
  );

  @override
  bool get cacheStretchPixels => true;

  @override
  double contentHeight(double width) => math.max(
    48,
    math.max(10 + _dayLine(width).height, 33 + _lunarLine(width).height),
  );

  @override
  Alignment get contentAlignment => Alignment.topCenter;

  @override
  double get footerHeight => data.showBottomDivider ? 6 : 0;

  @override
  void paintContent(Canvas canvas, Size size) {
    final fill = Paint();
    if (data.isSelected || data.isToday) {
      final radius = size.width.clamp(36.0, 42.0) / 2;
      canvas.drawCircle(
        Offset(size.width / 2, 6 + radius),
        radius,
        fill
          ..color = data.isSelected
              ? const Color(0x80CFCFCF)
              : const Color(0xFFEAEAEA),
      );
    }
    if (data.primaryMarker case final marker?) {
      final badge = Rect.fromLTWH(size.width - 14, 4, 14, 14);
      canvas.drawCircle(badge.center, 7, fill..color = Colors.white);
      text.paint(
        canvas,
        marker.label,
        TextStyle(
          fontSize: 8,
          color: marker.color,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        badge,
      );
    }
    final day = _dayLine(size.width);
    day.paint(canvas, Offset((size.width - day.width) / 2, 10));
    final lunar = _lunarLine(size.width);
    lunar.paint(canvas, Offset((size.width - lunar.width) / 2, 33));
  }

  @override
  void paintFooter(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 5.3, size.width, .3),
      Paint()..color = const Color(0xFFE5E5E5),
    );
  }

  @override
  bool shouldRepaint(covariant _CustomDayPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.text != text;
}

class _MeizuDayPainter extends CustomPainter {
  const _MeizuDayPainter(this.data, this.text);

  static final _selectedBackground = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFF128C4B), width: 1.6),
    boxShadow: const [
      BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(2, 6)),
    ],
  ).createBoxPainter();

  final CalendarDayCellData data;
  final CalendarCanvasText text;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = const EdgeInsets.symmetric(
      horizontal: 2,
      vertical: 4,
    ).deflateRect(Offset.zero & size);
    if (cell.isEmpty) return;
    final dayColor = switch (data) {
      _ when data.isSelected => const Color(0xFF128C4B),
      _ when data.isToday => const Color(0xFFFF0000),
      _ when data.isCurrentMonth => const Color(0xFF333333),
      _ => const Color(0xFFE1E1E1),
    };
    final lunarColor = dayColor == const Color(0xFF333333)
        ? const Color(0xFFCFCFCF)
        : dayColor;
    if (data.isSelected) {
      _selectedBackground.paint(
        canvas,
        cell.topLeft,
        ImageConfiguration(size: cell.size),
      );
    }
    if (data.primaryMarker case final marker?) {
      final badge = Rect.fromLTWH(cell.right - 20, cell.top + 2, 16, 16);
      canvas.drawCircle(badge.center, 8, Paint()..color = marker.color);
      text.paint(
        canvas,
        marker.label,
        const TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        badge,
      );
    }
    text.paintDayAndLunar(
      canvas,
      const EdgeInsets.symmetric(horizontal: 4, vertical: 6).deflateRect(cell),
      day: '${data.date.day}',
      dayStyle: TextStyle(
        fontSize: 15,
        color: dayColor,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
      lunar: data.lunarText,
      lunarStyle: TextStyle(fontSize: 10, color: lunarColor, height: 1),
      gap: 8,
      alignment: AlignmentDirectional.centerStart,
    );
  }

  @override
  bool shouldRepaint(covariant _MeizuDayPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.text != text;
}
