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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final focusedMonth = DateTime(
          controller.focusedDay.year,
          controller.focusedDay.month,
          1,
        );
        final monthDays = CalendarDateUtils.visibleMonthDays(
          focusedMonth,
          firstWeekday: controller.firstWeekday,
        );
        final weekDays = CalendarDateUtils.visibleWeekDays(
          controller.focusedDay,
          firstWeekday: controller.firstWeekday,
        );
        final monthLineCount = CalendarDateUtils.visibleMonthRowCount(
          focusedMonth,
          firstWeekday: controller.firstWeekday,
          onlyCurrentMonth: controller.onlyCurrentMonth,
        );
        final selectedLine = CalendarDateUtils.weekIndexInMonth(
          controller.focusedDay,
          firstWeekday: controller.firstWeekday,
        ).clamp(0, monthLineCount - 1);
        final collapseProgress =
            collapsePreviewProgress ??
            (controller.displayMode == CalendarDisplayMode.week ? 1.0 : 0.0);
        final monthBodyHeight = monthLineCount * calendarHeight;
        final weekBodyHeight = calendarHeight;
        final bodyHeight = lerpDouble(
          monthBodyHeight,
          weekBodyHeight,
          collapseProgress,
        )!;
        final monthTranslation = selectedLine * calendarHeight * collapseProgress;
        final shouldShowMonthBody =
            controller.displayMode == CalendarDisplayMode.month ||
            previewExpandFromWeek ||
            collapseProgress < 1;

        return SizedBox(
          height: monthHeaderHeight + weekBarHeight + bodyHeight,
          child: Column(
            children: [
              _MonthHeader(
                month: controller.focusedDay.month,
                height: monthHeaderHeight,
              ),
              _WeekBar(
                firstWeekday: controller.firstWeekday,
                height: weekBarHeight,
              ),
              SizedBox(
                height: bodyHeight,
                child: ClipRect(
                  child: shouldShowMonthBody
                      ? OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: monthBodyHeight,
                          maxHeight: monthBodyHeight,
                          child: Transform.translate(
                            offset: Offset(0, -monthTranslation),
                            child: SizedBox(
                              height: monthBodyHeight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: _MonthGrid(
                                  days: monthDays,
                                  lineCount: monthLineCount,
                                  focusedMonth: focusedMonth,
                                  controller: controller,
                                  onDaySelected: onDaySelected,
                                  rowHeight: calendarHeight,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _WeekGrid(
                            days: weekDays,
                            focusedMonth: focusedMonth,
                            controller: controller,
                            onDaySelected: onDaySelected,
                            rowHeight: calendarHeight,
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
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.height});

  final int month;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          '$month月',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.days,
    required this.lineCount,
    required this.focusedMonth,
    required this.controller,
    required this.onDaySelected,
    required this.rowHeight,
  });

  final List<DateTime> days;
  final int lineCount;
  final DateTime focusedMonth;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(lineCount, (rowIndex) {
        final rowDays = days.skip(rowIndex * 7).take(7).toList();
        return SizedBox(
          height: rowHeight,
          child: Row(
            children: List.generate(7, (columnIndex) {
              final date = rowDays[columnIndex];
              final shouldHide =
                  controller.onlyCurrentMonth &&
                  !CalendarDateUtils.isSameMonth(date, focusedMonth);
              return Expanded(
                child: shouldHide
                    ? const SizedBox.expand()
                    : _CalendarDayCell(
                        date: date,
                        focusedMonth: focusedMonth,
                        markers: controller.markers[date] ?? const [],
                        lunarText: LunarService.metadataForDate(date).lunarText,
                        isToday: CalendarDateUtils.isSameDay(
                          date,
                          CalendarDateUtils.stripTime(DateTime.now()),
                        ),
                        isSelected: controller.isSelected(date),
                        isDisabled: controller.isDisabled(date),
                        showBottomDivider: rowIndex < lineCount - 1,
                        onTap: () => onDaySelected(date),
                      ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.focusedMonth,
    required this.controller,
    required this.onDaySelected,
    required this.rowHeight,
  });

  final List<DateTime> days;
  final DateTime focusedMonth;
  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: days.map((date) {
          return Expanded(
            child: _CalendarDayCell(
              date: date,
              focusedMonth: focusedMonth,
              markers: controller.markers[date] ?? const [],
              lunarText: LunarService.metadataForDate(date).lunarText,
              isToday: CalendarDateUtils.isSameDay(
                date,
                CalendarDateUtils.stripTime(DateTime.now()),
              ),
              isSelected: controller.isSelected(date),
              isDisabled: controller.isDisabled(date),
              showBottomDivider: false,
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
    required this.showBottomDivider,
    required this.onTap,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool showBottomDivider;
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

    final schemeColor = markers.isEmpty ? null : markers.first.color;
    final schemeText = markers.isEmpty ? null : markers.first.label;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth;
          final circleSize = (cellWidth).clamp(36.0, 42.0);
          final circleTop = 6.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSelected || isToday)
                Positioned(
                  top: circleTop,
                  left: (cellWidth - circleSize) / 2,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
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
                    '${date.day}',
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
                    lunarText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 10,
                      color: lunarColor,
                      height: 1,
                    ),
                  ),
                ),
              ),
              if (showBottomDivider)
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
              // if (markers.isNotEmpty)
              //   Positioned(
              //     left: 0,
              //     right: 0,
              //     bottom: 0.8,
              //     child: Center(
              //       child: Container(
              //         width: 4,
              //         height: 4,
              //         decoration: BoxDecoration(
              //           color: isSelected ? Colors.white : Colors.grey,
              //           shape: BoxShape.circle,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          );
        },
      ),
    );
  }
}
