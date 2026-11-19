import 'package:flutter/widgets.dart';

import 'calendar_canvas_labels.dart';
import 'calendar_models.dart';
import 'calendar_text_layout.dart';
import 'date_utils_ext.dart';

/// 日历默认水平内边距。
const double kCalendarHorizontalPadding = 10;

/// 构建星期栏时传递给样式层的数据。
@immutable
class CalendarWeekBarData {
  /// 创建星期栏数据。
  const CalendarWeekBarData({required this.firstWeekday, required this.height});

  /// 周起始日。
  final int firstWeekday;

  /// 星期栏高度。
  final double height;
}

/// 单个星期栏单元格的数据。
@immutable
class CalendarWeekBarCellData {
  /// 创建星期栏单元格数据。
  const CalendarWeekBarCellData({
    required this.label,
    required this.index,
    required this.firstWeekday,
  });

  /// 展示文本。
  final String label;

  /// 当前单元格索引。
  final int index;

  /// 周起始日。
  final int firstWeekday;
}

/// 单个日期单元格的数据。
@immutable
class CalendarDayCellData {
  /// 创建日期单元格数据。
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

  /// 当前日期。
  final DateTime date;

  /// 当前页面聚焦的月份。
  final DateTime focusedMonth;

  /// 当前日期标记列表。
  final List<CalendarMarker> markers;

  /// 农历文本。
  final String lunarText;

  /// 是否今天。
  final bool isToday;

  /// 是否选中。
  final bool isSelected;

  /// 是否禁用。
  final bool isDisabled;

  /// 是否显示底部分割线。
  final bool showBottomDivider;

  /// 是否范围选择的开始日期。
  final bool isRangeStart;

  /// 是否范围选择的结束日期。
  final bool isRangeEnd;

  /// 前一天是否同样处于选中状态。
  final bool isSelectedPrevious;

  /// 后一天是否同样处于选中状态。
  final bool isSelectedNext;

  /// 是否超出可选范围。
  final bool isOutOfSelectableRange;

  /// 是否属于当前聚焦月份。
  bool get isCurrentMonth => CalendarDateUtils.isSameMonth(date, focusedMonth);

  /// 是否周末。
  bool get isWeekend =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  /// 第一个日期标记。
  CalendarMarker? get primaryMarker => markers.isEmpty ? null : markers.first;
}

/// 日历 UI 样式扩展协议。
abstract class CalendarComponentBuilder {
  /// 创建组件构建器。
  const CalendarComponentBuilder();

  /// 日期区域和星期栏的水平内边距。
  EdgeInsetsGeometry get contentPadding =>
      const EdgeInsets.symmetric(horizontal: kCalendarHorizontalPadding);

  /// 星期栏背景色。
  Color get weekBarBackgroundColor => const Color(0x00000000);

  /// 按照周起始日返回星期文本。
  List<String> orderedWeekLabels(int firstWeekday);

  /// 构建月份头部。
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    return SizedBox(
      height: height,
      child: CalendarCanvasLabels(
        labels: [
          CalendarCanvasLabel(
            '${month.month}月',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个星期栏单元格。
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data);

  /// 构建单个日期单元格。
  Widget buildDayCell(BuildContext context, CalendarDayCellData data);

  /// 构建完整星期栏。
  Widget buildWeekBar(BuildContext context, CalendarWeekBarData data) {
    final labels = orderedWeekLabels(data.firstWeekday);
    final cells = List.generate(labels.length, (index) {
      return buildWeekBarCell(
        context,
        CalendarWeekBarCellData(
          label: labels[index],
          index: index,
          firstWeekday: data.firstWeekday,
        ),
      );
    });
    if (cells.every(
      (cell) => cell is CalendarCanvasLabel && cell.key == null,
    )) {
      return SizedBox(
        height: data.height,
        child: CalendarCanvasLabels(
          labels: cells.cast<CalendarCanvasLabel>(),
          padding: contentPadding,
          background: weekBarBackgroundColor,
        ),
      );
    }
    return Container(
      height: data.height,
      color: weekBarBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: contentPadding,
        child: Row(
          children: [
            for (final cell in cells) Expanded(child: Center(child: cell)),
          ],
        ),
      ),
    );
  }
}

/// 默认基础日历样式。
class DefaultCalendarComponentBuilder extends CalendarComponentBuilder {
  /// 创建默认基础日历样式。
  const DefaultCalendarComponentBuilder();

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
      style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return CustomPaint(
      painter: _DefaultCalendarDayPainter(
        data: data,
        textStyle: DefaultTextStyle.of(context).style,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
        locale: Localizations.maybeLocaleOf(context),
      ),
    );
  }
}

class _DefaultCalendarDayPainter extends CustomPainter {
  _DefaultCalendarDayPainter({
    required this.data,
    required this.textStyle,
    required this.textScaler,
    required this.textDirection,
    required this.locale,
  });

  final CalendarDayCellData data;
  final TextStyle textStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final Locale? locale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final diameter = 36.0.clamp(0.0, size.shortestSide);
    if (data.isSelected) {
      canvas.drawCircle(
        center,
        diameter / 2,
        Paint()..color = const Color(0xFF128C4B),
      );
    }
    final textColor = data.isDisabled || !data.isCurrentMonth
        ? const Color(0xFFE1E1E1)
        : data.isSelected
        ? const Color(0xFFFFFFFF)
        : data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    final text = CalendarTextLayout.layout(
      text: TextSpan(
        text: '${data.date.day}',
        style: textStyle.merge(
          TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      maxWidth: diameter,
    );
    // Match the original 36×36 text box, including clipping at large text scales.
    final textHeight = text.height.clamp(0.0, diameter);
    final offset = center - Offset(text.width / 2, textHeight / 2);
    canvas.save();
    if (text.height > diameter) {
      canvas.clipRect(offset & Size(text.width, textHeight));
    }
    text.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DefaultCalendarDayPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.locale != locale;
  }
}

/// 根据周起始日重新排列星期文本。
List<String> calendarOrderedWeekLabels(List<String> labels, int firstWeekday) {
  return switch (firstWeekday) {
    DateTime.monday => [...labels.skip(1), labels.first],
    DateTime.saturday => [labels.last, ...labels.take(6)],
    _ => labels,
  };
}
