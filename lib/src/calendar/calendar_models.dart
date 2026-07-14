import 'package:flutter/material.dart';

/// 日历选择模式。
enum CalendarSelectionMode { single, range, multi }

/// 日历显示模式。
enum CalendarDisplayMode { month, week }

/// 日历分页方向。
enum CalendarPageOrientation { horizontal, vertical }

/// 月视图日期显示模式。
enum MonthViewShowMode { allMonth, onlyCurrentMonth, fitMonth }

/// 范围选择违反限制的类型。
enum CalendarRangeLimitViolation { belowMinRange, aboveMaxRange }

/// 范围选择完成或更新时的回调。
typedef CalendarRangeSelectedCallback = void Function(DateRangeValue range);

/// 范围选择超出最小或最大天数限制时的回调。
typedef CalendarRangeLimitViolationCallback =
    void Function(DateTime day, CalendarRangeLimitViolation violation);

/// 多选成功后的回调。
typedef CalendarMultiSelectedCallback =
    void Function(DateTime day, int selectedSize, int maxSize);

/// 多选数量超出上限时的回调。
typedef CalendarMultiSelectOutOfSizeCallback =
    void Function(DateTime day, int maxSize);

/// 用于动态判断某一天是否不可选。
typedef CalendarDatePredicate = bool Function(DateTime day);

/// 日历可显示、可选择的日期边界。
@immutable
class CalendarBounds {
  /// 创建日期边界。
  const CalendarBounds({this.min, this.max});

  /// 最小日期，为 null 表示没有下边界。
  final DateTime? min;

  /// 最大日期，为 null 表示没有上边界。
  final DateTime? max;

  /// 是否存在下边界。
  bool get hasLowerBound => min != null;

  /// 是否存在上边界。
  bool get hasUpperBound => max != null;

  /// 是否完全不限制日期边界。
  bool get isUnbounded => min == null && max == null;

  /// 复制边界并替换指定字段。
  CalendarBounds copyWith({
    DateTime? min,
    DateTime? max,
    bool clearMin = false,
    bool clearMax = false,
  }) {
    return CalendarBounds(
      min: clearMin ? null : (min ?? this.min),
      max: clearMax ? null : (max ?? this.max),
    );
  }
}

/// 日期标记数据。
@immutable
class CalendarMarker {
  /// 创建一个日期标记。
  const CalendarMarker({required this.label, required this.color});

  /// 标记文本，可由样式层自行解释。
  final String label;

  /// 标记颜色。
  final Color color;
}

/// 农历和节气显示数据。
@immutable
class LunarMetadata {
  /// 创建农历元数据。
  const LunarMetadata({required this.lunarText, this.solarTerm});

  /// 农历文本。
  final String lunarText;

  /// 节气文本，为 null 表示当天没有节气。
  final String? solarTerm;
}

/// 范围选择值。
@immutable
class DateRangeValue {
  /// 创建范围选择值。
  const DateRangeValue({this.start, this.end});

  /// 范围开始日期。
  final DateTime? start;

  /// 范围结束日期。
  final DateTime? end;

  /// 是否已经同时具备开始和结束日期。
  bool get isComplete => start != null && end != null;

  /// 复制范围值并替换指定字段。
  DateRangeValue copyWith({
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
  }) {
    return DateRangeValue(
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
    );
  }
}

/// 日历完整选择状态。
@immutable
class CalendarSelectionState {
  /// 创建选择状态。
  const CalendarSelectionState({
    this.single,
    this.range = const DateRangeValue(),
    this.multi = const <DateTime>{},
  });

  /// 单选模式下的选中日期。
  final DateTime? single;

  /// 范围选择模式下的选中范围。
  final DateRangeValue range;

  /// 多选模式下的选中日期集合。
  final Set<DateTime> multi;

  /// 复制选择状态并替换指定字段。
  CalendarSelectionState copyWith({
    DateTime? single,
    bool clearSingle = false,
    DateRangeValue? range,
    Set<DateTime>? multi,
  }) {
    return CalendarSelectionState(
      single: clearSingle ? null : (single ?? this.single),
      range: range ?? this.range,
      multi: multi ?? this.multi,
    );
  }
}
