import 'package:flutter/material.dart';

import 'calendar_models.dart';
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
  Color get weekBarBackgroundColor => Colors.transparent;

  /// 按照周起始日返回星期文本。
  List<String> orderedWeekLabels(int firstWeekday);

  /// 构建月份头部。
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

  /// 构建单个星期栏单元格。
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data);

  /// 构建单个日期单元格。
  Widget buildDayCell(BuildContext context, CalendarDayCellData data);

  /// 构建完整星期栏。
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
    return Text(
      data.label,
      style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    final textColor = data.isDisabled || !data.isCurrentMonth
        ? const Color(0xFFE1E1E1)
        : data.isSelected
        ? Colors.white
        : data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: data.isSelected
            ? const BoxDecoration(
                color: Color(0xFF128C4B),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          '${data.date.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
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
