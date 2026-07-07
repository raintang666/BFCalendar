import 'dart:ui';

import 'package:flutter/material.dart';

import 'calendar_controller.dart';
import 'calendar_models.dart';
import 'date_utils_ext.dart';
import 'lunar_service.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    this.collapsePreviewProgress,
    this.previewExpandFromWeek = false,
    this.calendarHeight = 62,
    this.weekBarHeight = 46,
    this.monthHeaderHeight = 60,
  });

  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final double? collapsePreviewProgress;
  final bool previewExpandFromWeek;
  final double calendarHeight;
  final double weekBarHeight;
  final double monthHeaderHeight;

  bool get _isInteractivePreview =>
      collapsePreviewProgress != null &&
      collapsePreviewProgress! > 0 &&
      collapsePreviewProgress! < 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final monthDays = CalendarDateUtils.visibleMonthDays(
          controller.focusedDay,
          firstWeekday: controller.firstWeekday,
        );
        final weekDays = CalendarDateUtils.visibleWeekDays(
          controller.focusedDay,
          firstWeekday: controller.firstWeekday,
        );
        final monthRows = _buildMonthRows(monthDays);
        final visibleMonthRows = _visibleMonthRows(monthRows);
        final showingMonthGrid =
            controller.displayMode == CalendarDisplayMode.month ||
            previewExpandFromWeek;
        final collapseProgress =
            collapsePreviewProgress ??
            (controller.displayMode == CalendarDisplayMode.week ? 1.0 : 0.0);
        final monthRowCount = visibleMonthRows.length;
        final monthBodyHeight = calendarHeight * monthRowCount;
        final displayHeight = lerpDouble(
          monthBodyHeight,
          calendarHeight,
          collapseProgress,
        )!;
        final height = monthHeaderHeight + weekBarHeight + displayHeight;
        final selectedRow = _selectedRow(visibleMonthRows);

        return AnimatedContainer(
          duration: _isInteractivePreview
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: height,
          child: Column(
            children: [
              SizedBox(
                height: monthHeaderHeight,
                child: Center(
                  child: Text(
                    '${controller.focusedDay.month}月',
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _WeekBar(
                firstWeekday: controller.firstWeekday,
                height: weekBarHeight,
              ),
              AnimatedSize(
                duration: _isInteractivePreview
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  height: displayHeight,
                  child: ClipRect(
                    child: Transform.translate(
                      offset: showingMonthGrid
                          ? Offset(
                              0,
                              -selectedRow.clamp(0, monthRowCount - 1) *
                                  calendarHeight *
                                  collapseProgress,
                            )
                          : Offset.zero,
                      child: SizedBox(
                        height: showingMonthGrid
                            ? monthBodyHeight
                            : calendarHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: showingMonthGrid
                                ? visibleMonthRows
                                      .map(
                                        (row) => _CalendarRow(
                                          dates: row,
                                          height: calendarHeight,
                                          focusedMonth: controller.focusedDay,
                                          controller: controller,
                                          onDaySelected: onDaySelected,
                                        ),
                                      )
                                      .toList()
                                : [
                                    _CalendarRow(
                                      dates: weekDays,
                                      height: calendarHeight,
                                      focusedMonth: controller.focusedDay,
                                      controller: controller,
                                      onDaySelected: onDaySelected,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<List<DateTime>> _buildMonthRows(List<DateTime> monthDays) {
    final rows = <List<DateTime>>[];
    for (var i = 0; i < monthDays.length; i += 7) {
      rows.add(monthDays.sublist(i, i + 7));
    }
    return rows;
  }

  List<List<DateTime>> _visibleMonthRows(List<List<DateTime>> monthRows) {
    if (!controller.onlyCurrentMonth) {
      return monthRows;
    }
    return monthRows
        .where(
          (row) => row.any(
            (day) => CalendarDateUtils.isSameMonth(day, controller.focusedDay),
          ),
        )
        .toList();
  }

  int _selectedRow(List<List<DateTime>> monthRows) {
    for (var rowIndex = 0; rowIndex < monthRows.length; rowIndex++) {
      if (monthRows[rowIndex].any(
        (day) => CalendarDateUtils.isSameDay(day, controller.focusedDay),
      )) {
        return rowIndex;
      }
    }
    return 0;
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.dates,
    required this.height,
    required this.focusedMonth,
    required this.controller,
    required this.onDaySelected,
  });

  final List<DateTime> dates;
  final double height;
  final DateTime focusedMonth;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: dates.map((date) {
          final lunar = LunarService.metadataForDate(date);
          return Expanded(
            child: _CalendarDayCell(
              date: date,
              focusedMonth: focusedMonth,
              markers: controller.markers[date] ?? const [],
              lunarText: lunar.lunarText,
              isToday: CalendarDateUtils.isSameDay(
                date,
                CalendarDateUtils.stripTime(DateTime.now()),
              ),
              isSelected: controller.isSelected(date),
              isDisabled: controller.isDisabled(date),
              onTap: () => onDaySelected(date),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.firstWeekday, required this.height});

  final int firstWeekday;
  final double height;

  @override
  Widget build(BuildContext context) {
    const labels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final ordered = switch (firstWeekday) {
      DateTime.monday => [...labels.skip(1), labels.first],
      DateTime.saturday => [labels.last, ...labels.take(6)],
      _ => labels,
    };
    return Container(
      height: height,
      color: const Color(0xFFF7F6FE),
      alignment: Alignment.center,
      child: Row(
        children: ordered
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE1E1E1),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.focusedMonth,
    required this.markers,
    required this.lunarText,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = CalendarDateUtils.isSameMonth(date, focusedMonth);
    Color dayColor;
    Color lunarColor;

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (isWeekend && inMonth) {
      dayColor = const Color(0xFF489DFF);
      lunarColor = const Color(0xFF489DFF);
    } else if (!inMonth) {
      dayColor = const Color(0xFFE1E1E1);
      lunarColor = const Color(0xFFE1E1E1);
    } else {
      dayColor = const Color(0xFF333333);
      lunarColor = const Color(0xFFCFCFCF);
    }

    if (isToday) {
      dayColor = const Color(0xFFFF0000);
      lunarColor = const Color(0xFFFF0000);
    }

    if (isSelected) {
      dayColor = const Color(0xFF128C4B);
      lunarColor = const Color(0xFF128C4B);
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: CustomPaint(
        painter: _CellPainter(
          isToday: isToday,
          isSelected: isSelected,
          hasScheme: markers.isNotEmpty,
          schemeColor: markers.isEmpty ? null : markers.first.color,
          schemeText: markers.isEmpty ? null : markers.first.label,
          dayText: '${date.day}',
          lunarText: lunarText,
          dayColor: dayColor,
          lunarColor: lunarColor,
        ),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter({
    required this.isToday,
    required this.isSelected,
    required this.hasScheme,
    required this.schemeColor,
    required this.schemeText,
    required this.dayText,
    required this.lunarText,
    required this.dayColor,
    required this.lunarColor,
  });

  final bool isToday;
  final bool isSelected;
  final bool hasScheme;
  final Color? schemeColor;
  final String? schemeText;
  final String dayText;
  final String lunarText;
  final Color dayColor;
  final Color lunarColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = const Color(0xFFE5E5E5);
    final pointPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = isSelected ? Colors.white : Colors.grey;
    final currentDayPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEAEAEA);
    final selectedPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = const Color(0x80CFCFCF);
    final schemeBgPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final centerX = size.width / 2;
    const top = 22.0;
    final radius =
        (size.width < size.height ? size.width : size.height) / 11 * 2.2;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      linePaint,
    );

    if (isSelected) {
      canvas.drawCircle(Offset(centerX, top), radius, selectedPaint);
    } else if (isToday) {
      canvas.drawCircle(Offset(centerX, top), radius, currentDayPaint);
    }

    if (hasScheme) {
      canvas.drawCircle(Offset(size.width - 6.5, top), 7, schemeBgPaint);
      final schemeTextPainter = TextPainter(
        text: TextSpan(
          text: schemeText,
          style: TextStyle(
            fontSize: 8,
            color: schemeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      schemeTextPainter.paint(
        canvas,
        Offset(size.width - 10.5 - schemeTextPainter.width / 2, 4),
      );
    }

    final dayPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          fontSize: 15,
          color: dayColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dayPainter.paint(canvas, Offset(centerX - dayPainter.width / 2, 12));

    final lunarPainter = TextPainter(
      text: TextSpan(
        text: lunarText,
        style: TextStyle(fontSize: 10, color: lunarColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 4);
    lunarPainter.paint(canvas, Offset(centerX - lunarPainter.width / 2, 36));

    if (hasScheme) {
      canvas.drawCircle(Offset(centerX, size.height - 9), 2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CellPainter oldDelegate) {
    return oldDelegate.isToday != isToday ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.hasScheme != hasScheme ||
        oldDelegate.schemeText != schemeText ||
        oldDelegate.dayText != dayText ||
        oldDelegate.lunarText != lunarText ||
        oldDelegate.dayColor != dayColor ||
        oldDelegate.lunarColor != lunarColor;
  }
}
