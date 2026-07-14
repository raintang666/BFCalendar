import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

const double kCalendarHorizontalPadding = 10;

@immutable
class CalendarWeekBarData {
  const CalendarWeekBarData({required this.firstWeekday, required this.height});

  final int firstWeekday;
  final double height;
}

@immutable
class CalendarWeekBarCellData {
  const CalendarWeekBarCellData({
    required this.label,
    required this.index,
    required this.firstWeekday,
  });

  final String label;
  final int index;
  final int firstWeekday;
}

@immutable
class CalendarDayCellData {
  const CalendarDayCellData({
    required this.date,
    required this.focusedMonth,
    required this.markers,
    required this.lunarText,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    required this.showBottomDivider,
    this.isRangeStart = false,
    this.isRangeEnd = false,
    this.isSelectedPrevious = false,
    this.isSelectedNext = false,
    this.isOutOfSelectableRange = false,
  });

  final DateTime date;
  final DateTime focusedMonth;
  final List<CalendarMarker> markers;
  final String lunarText;
  final bool isToday;
  final bool isSelected;
  final bool isDisabled;
  final bool showBottomDivider;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isSelectedPrevious;
  final bool isSelectedNext;
  final bool isOutOfSelectableRange;

  bool get isCurrentMonth => CalendarDateUtils.isSameMonth(date, focusedMonth);
  bool get isWeekend =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  CalendarMarker? get primaryMarker => markers.isEmpty ? null : markers.first;
}

abstract class CalendarComponentBuilder {
  const CalendarComponentBuilder();

  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

  Color get weekBarBackgroundColor => Colors.transparent;

  List<String> orderedWeekLabels(int firstWeekday);

  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          '${month.month}月',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data);

  Widget buildDayCell(BuildContext context, CalendarDayCellData data);

  Widget buildWeekBar(BuildContext context, CalendarWeekBarData data) {
    final labels = orderedWeekLabels(data.firstWeekday);
    return Container(
      height: data.height,
      color: weekBarBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: contentPadding,
        child: Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Center(
                child: buildWeekBarCell(
                  context,
                  CalendarWeekBarCellData(
                    label: labels[index],
                    index: index,
                    firstWeekday: data.firstWeekday,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class CustomCalendarComponentBuilder extends CalendarComponentBuilder {
  const CustomCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => const Color(0xFFF7F6FE);

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return _reorderedLabels(const [
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
    return _reorderedLabels(const [
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

class IOSCalendarComponentBuilder extends CalendarComponentBuilder {
  const IOSCalendarComponentBuilder();

  @override
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return _reorderedLabels(const [
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
    return Container(
      height: height,
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(
        horizontal: kCalendarHorizontalPadding,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${month.month}月',
              style: TextStyle(
                color: isCurrent
                    ? const Color(0xFFFF0000)
                    : const Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: ColoredBox(
              color: Color(0xFFC6C6C6),
              child: SizedBox(height: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(
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
    return _IOSDayCellContent(data: data);
  }
}

class RangeCalendarComponentBuilder extends CalendarComponentBuilder {
  const RangeCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return _reorderedLabels(const [
      'S',
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
    ], firstWeekday);
  }

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(height: height);
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    final isWeekend = data.index == 0 || data.index == 6;
    return Text(
      data.label,
      style: TextStyle(
        color: isWeekend ? const Color(0xFF9F9F9F) : const Color(0xFF666666),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _RangeCellPainter(
        dayText: '${data.date.day}',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isDisabled: data.isDisabled,
        isSelected: data.isSelected,
        isRangeStart: data.isRangeStart,
        isRangeEnd: data.isRangeEnd,
        isSelectedPre: data.isSelectedPrevious,
        isSelectedNext: data.isSelectedNext,
        dimForOutOfSelectableRange: data.isOutOfSelectableRange,
      ),
    );
  }
}

class MultiSelectCalendarComponentBuilder extends CalendarComponentBuilder {
  const MultiSelectCalendarComponentBuilder();

  @override
  Color get weekBarBackgroundColor => Colors.white;

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return _reorderedLabels(const [
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
      painter: _MultiSelectCellPainter(
        dayText: '${data.date.day}',
        inMonth: data.isCurrentMonth,
        isToday: data.isToday,
        isDisabled: data.isDisabled,
        hasScheme: data.markers.isNotEmpty,
        isSelected: data.isSelected,
        isSelectedPre: data.isSelectedPrevious,
        isSelectedNext: data.isSelectedNext,
      ),
    );
  }
}

List<String> _reorderedLabels(List<String> labels, int firstWeekday) {
  return switch (firstWeekday) {
    DateTime.monday => [...labels.skip(1), labels.first],
    DateTime.saturday => [labels.last, ...labels.take(6)],
    _ => labels,
  };
}

class _IOSDayCellContent extends StatelessWidget {
  const _IOSDayCellContent({required this.data});

  final CalendarDayCellData data;

  @override
  Widget build(BuildContext context) {
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
    return Stack(
      children: [
        if (data.showBottomDivider)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ColoredBox(
              color: Color(0xFFC6C6C6),
              child: SizedBox(height: 0.5),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 45,
              height: 45,
              decoration: data.isSelected
                  ? BoxDecoration(color: circleColor, shape: BoxShape.circle)
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${data.date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.lunarText,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(color: textColor, fontSize: 10, height: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (data.markers.isNotEmpty)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 9,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF808080),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 6, height: 6),
              ),
            ),
          ),
      ],
    );
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
        final circleTop = 6.0;
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

class _RangeCellPainter extends CustomPainter {
  _RangeCellPainter({
    required this.dayText,
    required this.inMonth,
    required this.isToday,
    required this.isDisabled,
    required this.isSelected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.isSelectedPre,
    required this.isSelectedNext,
    required this.dimForOutOfSelectableRange,
  });

  final String dayText;
  final bool inMonth;
  final bool isToday;
  final bool isDisabled;
  final bool isSelected;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool isSelectedPre;
  final bool isSelectedNext;
  final bool dimForOutOfSelectableRange;

  static const _themeColor = Color(0xFF06CB93);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 50 * 28;
    const rectDiff = 4.0;

    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _themeColor;

    final selectedPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = _themeColor;

    if (isSelected) {
      if (isSelectedPre) {
        if (isSelectedNext) {
          canvas.drawLine(
            Offset(0, rectDiff),
            Offset(size.width, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(0, size.height - rectDiff),
            Offset(size.width, size.height - rectDiff),
            linePaint,
          );
        } else {
          canvas.drawLine(
            Offset(0, rectDiff),
            Offset(size.width / 2, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(0, size.height - rectDiff),
            Offset(size.width / 2, size.height - rectDiff),
            linePaint,
          );
          canvas.drawArc(
            Rect.fromLTWH(0, rectDiff, size.width, size.height - rectDiff * 2),
            1.5 * 3.1415926,
            3.1415926,
            false,
            linePaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        }
      } else {
        if (isSelectedNext) {
          canvas.drawLine(
            Offset(size.width / 2, rectDiff),
            Offset(size.width, rectDiff),
            linePaint,
          );
          canvas.drawLine(
            Offset(size.width / 2, size.height - rectDiff),
            Offset(size.width, size.height - rectDiff),
            linePaint,
          );
          canvas.drawArc(
            Rect.fromLTWH(0, rectDiff, size.width, size.height - rectDiff * 2),
            0.5 * 3.1415926,
            3.1415926,
            false,
            linePaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        } else {
          canvas.drawCircle(center, radius, selectedPaint);
        }
      }
    }

    Color textColor;
    if (isSelected &&
        (isRangeStart || isRangeEnd || (!isSelectedPre && !isSelectedNext))) {
      textColor = Colors.white;
    } else if (!inMonth || isDisabled || dimForOutOfSelectableRange) {
      textColor = const Color(0xFFE1E1E1);
    } else if (isToday) {
      textColor = Colors.red;
    } else {
      textColor = const Color(0xFF4F4F4F);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
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
  bool shouldRepaint(covariant _RangeCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isRangeStart != isRangeStart ||
        oldDelegate.isRangeEnd != isRangeEnd ||
        oldDelegate.isSelectedPre != isSelectedPre ||
        oldDelegate.isSelectedNext != isSelectedNext ||
        oldDelegate.dimForOutOfSelectableRange != dimForOutOfSelectableRange;
  }
}

class _MultiSelectCellPainter extends CustomPainter {
  _MultiSelectCellPainter({
    required this.dayText,
    required this.inMonth,
    required this.isToday,
    required this.isDisabled,
    required this.hasScheme,
    required this.isSelected,
    required this.isSelectedPre,
    required this.isSelectedNext,
  });

  final String dayText;
  final bool inMonth;
  final bool isToday;
  final bool isDisabled;
  final bool hasScheme;
  final bool isSelected;
  final bool isSelectedPre;
  final bool isSelectedNext;

  static const _selectedColor = Color(0xFFF17706);
  static const _schemeColor = Color(0xFF128C4B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 5 * 2;

    final selectedPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = _selectedColor;
    final schemePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _schemeColor;

    if (isSelected) {
      if (isSelectedPre) {
        if (isSelectedNext) {
          canvas.drawRect(
            Rect.fromLTRB(
              0,
              center.dy - radius,
              size.width,
              center.dy + radius,
            ),
            selectedPaint,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTRB(0, center.dy - radius, center.dx, center.dy + radius),
            selectedPaint,
          );
          canvas.drawCircle(center, radius, selectedPaint);
        }
      } else {
        if (isSelectedNext) {
          canvas.drawRect(
            Rect.fromLTRB(
              center.dx,
              center.dy - radius,
              size.width,
              center.dy + radius,
            ),
            selectedPaint,
          );
        }
        canvas.drawCircle(center, radius, selectedPaint);
      }
    } else if (hasScheme) {
      canvas.drawCircle(center, radius, schemePaint);
    }

    final textColor = isSelected
        ? Colors.white
        : isToday
        ? const Color(0xFFFF0000)
        : inMonth && !isDisabled
        ? const Color(0xFF333333)
        : const Color(0xFFE1E1E1);
    final textPainter = TextPainter(
      text: TextSpan(
        text: dayText,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
  bool shouldRepaint(covariant _MultiSelectCellPainter oldDelegate) {
    return oldDelegate.dayText != dayText ||
        oldDelegate.inMonth != inMonth ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.hasScheme != hasScheme ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSelectedPre != isSelectedPre ||
        oldDelegate.isSelectedNext != isSelectedNext;
  }
}
