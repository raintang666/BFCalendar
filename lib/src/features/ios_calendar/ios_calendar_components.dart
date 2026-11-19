import 'package:flutter/material.dart';

import '../../calendar/calendar_canvas_labels.dart';
import '../../calendar/calendar_components.dart';
import '../../calendar/calendar_text_layout.dart';

class IOSCalendarComponentBuilder extends CalendarComponentBuilder {
  const IOSCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

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
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return SizedBox(
      height: height,
      child: CalendarCanvasLabels(
        padding: const EdgeInsets.symmetric(
          horizontal: kCalendarHorizontalPadding,
        ),
        background: const Color(0xFFF9F9F9),
        bottomDivider: const Color(0xFFC6C6C6),
        labels: [
          CalendarCanvasLabel(
            '${month.month}月',
            alignment: Alignment.centerLeft,
            style: TextStyle(
              color: isCurrent
                  ? const Color(0xFFFF0000)
                  : const Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return CalendarCanvasLabel(
      data.label,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _IOSDayPainter(data, CalendarCanvasText.of(context)),
    );
  }
}

class _IOSDayPainter extends CustomPainter {
  const _IOSDayPainter(this.data, this.text);

  final CalendarDayCellData data;
  final CalendarCanvasText text;

  @override
  void paint(Canvas canvas, Size size) {
    final isMuted = data.isWeekend && data.isCurrentMonth;
    final circleColor = data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    final textColor = data.isSelected
        ? Colors.white
        : data.isToday
        ? const Color(0xFFFF0000)
        : isMuted
        ? const Color(0xFF9F9F9F)
        : const Color(0xFF333333);
    final fill = Paint();
    if (data.showBottomDivider) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - 0.5, size.width, 0.5),
        fill..color = const Color(0xFFC6C6C6),
      );
    }
    final width = size.width.clamp(0.0, 45.0);
    final height = (size.height - 6).clamp(0.0, 45.0);
    final circle = Rect.fromLTWH((size.width - width) / 2, 6, width, height);
    if (data.isSelected) {
      canvas.drawCircle(
        circle.center,
        circle.shortestSide / 2,
        fill..color = circleColor,
      );
    }
    text.paintDayAndLunar(
      canvas,
      circle,
      day: '${data.date.day}',
      dayStyle: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      lunar: data.lunarText,
      lunarStyle: TextStyle(color: textColor, fontSize: 10, height: 1),
      gap: 3,
    );
    if (data.markers.isNotEmpty) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height - 12),
        3,
        fill..color = const Color(0xFF808080),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IOSDayPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.text != text;
}
