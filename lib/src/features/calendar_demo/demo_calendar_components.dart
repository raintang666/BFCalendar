import 'package:flutter/material.dart';

import '../../calendar/calendar_components.dart';

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
    return Text(
      data.label,
      style: const TextStyle(color: Color(0xFFE1E1E1), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return _CustomDayCellContent(data: data);
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
    return Text(
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
    return _MeizuDayCellContent(data: data);
  }
}

class _CustomDayCellContent extends StatelessWidget {
  const _CustomDayCellContent({required this.data});

  final CalendarDayCellData data;

  @override
  Widget build(BuildContext context) {
    Color dayColor;
    Color lunarColor;

    if (data.isWeekend && data.isCurrentMonth) {
      dayColor = const Color(0xFF489DFF);
      lunarColor = const Color(0xFF489DFF);
    } else if (!data.isCurrentMonth) {
      dayColor = const Color(0xFFE1E1E1);
      lunarColor = const Color(0xFFE1E1E1);
    } else {
      dayColor = const Color(0xFF333333);
      lunarColor = const Color(0xFFCFCFCF);
    }

    if (data.isToday) {
      dayColor = const Color(0xFFFF0000);
      lunarColor = const Color(0xFFFF0000);
    }

    if (data.isSelected) {
      dayColor = const Color(0xFF128C4B);
      lunarColor = const Color(0xFF128C4B);
    }

    final schemeColor = data.primaryMarker?.color;
    final schemeText = data.primaryMarker?.label;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth;
        final circleSize = cellWidth.clamp(36.0, 42.0);
        const circleTop = 6.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (data.isSelected || data.isToday)
              Positioned(
                top: circleTop,
                left: (cellWidth - circleSize) / 2,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.isSelected
                        ? const Color(0x80CFCFCF)
                        : const Color(0xFFEAEAEA),
                  ),
                ),
              ),
            if (schemeText != null && schemeColor != null)
              Positioned(
                top: 4,
                right: 0,
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        schemeText,
                        style: TextStyle(
                          fontSize: 8,
                          color: schemeColor,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${data.date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    color: dayColor,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 33,
              left: 2,
              right: 2,
              child: Center(
                child: Text(
                  data.lunarText,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 10, color: lunarColor, height: 1),
                ),
              ),
            ),
            if (data.showBottomDivider)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 5,
                child: Divider(
                  height: 0.3,
                  thickness: 0.3,
                  color: Color(0xFFE5E5E5),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeizuDayCellContent extends StatelessWidget {
  const _MeizuDayCellContent({required this.data});

  final CalendarDayCellData data;

  @override
  Widget build(BuildContext context) {
    final schemeColor = data.primaryMarker?.color;
    final schemeText = data.primaryMarker?.label;

    var dayColor = data.isCurrentMonth
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    var lunarColor = data.isCurrentMonth
        ? const Color(0xFFCFCFCF)
        : const Color(0xFFE1E1E1);

    if (data.isToday) {
      dayColor = const Color(0xFFFF0000);
      lunarColor = const Color(0xFFFF0000);
    }
    if (data.isSelected) {
      dayColor = const Color(0xFF128C4B);
      lunarColor = const Color(0xFF128C4B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration.zero,
              decoration: data.isSelected
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF128C4B),
                        width: 1.6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 10,
                          offset: Offset(2, 6),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          if (schemeText != null && schemeColor != null)
            Positioned(
              top: 2,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: schemeColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  schemeText,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${data.date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    color: dayColor,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.lunarText,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 10, color: lunarColor, height: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
