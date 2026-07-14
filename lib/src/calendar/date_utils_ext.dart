import 'calendar_models.dart';

/// 日历日期工具类。
class CalendarDateUtils {
  /// 禁止实例化。
  const CalendarDateUtils._();

  /// 去除时分秒，只保留年月日。
  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 判断两个日期是否是同一天。
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断两个日期是否是同一个月。
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// 获取日期所在月份的第一天。
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// 获取日期所在月份的最后一天。
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 在日期上增加指定月份数，并自动处理目标月天数不足的情况。
  static DateTime addMonths(DateTime date, int delta) {
    final totalMonths = (date.year * 12) + (date.month - 1) + delta;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = (totalMonths % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    return DateTime(targetYear, targetMonth, date.day.clamp(1, lastDay));
  }

  /// 计算月视图中需要展示的日期列表。
  static List<DateTime> visibleMonthDays(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
    MonthViewShowMode monthViewShowMode = MonthViewShowMode.allMonth,
  }) {
    final first = firstDayOfMonth(month);
    final offset = (first.weekday - firstWeekday + 7) % 7;
    final gridStart = first.subtract(Duration(days: offset));
    final itemCount = switch (monthViewShowMode) {
      MonthViewShowMode.allMonth => 42,
      MonthViewShowMode.onlyCurrentMonth || MonthViewShowMode.fitMonth =>
        visibleMonthRowCount(
              month,
              firstWeekday: firstWeekday,
              monthViewShowMode: monthViewShowMode,
            ) *
            7,
    };
    return List<DateTime>.generate(
      itemCount,
      (index) => stripTime(gridStart.add(Duration(days: index))),
    );
  }

  /// 计算周视图中需要展示的日期列表。
  static List<DateTime> visibleWeekDays(
    DateTime anchor, {
    int firstWeekday = DateTime.sunday,
  }) {
    final normalized = stripTime(anchor);
    final weekday = normalized.weekday % 7;
    final startWeekday = firstWeekday % 7;
    final offset = (weekday - startWeekday + 7) % 7;
    final start = normalized.subtract(Duration(days: offset));
    return List<DateTime>.generate(
      7,
      (index) => stripTime(start.add(Duration(days: index))),
    );
  }

  /// 获取两个日期之间的所有日期，包含起止日期。
  static List<DateTime> eachDay(DateTime start, DateTime end) {
    final normalizedStart = stripTime(start);
    final normalizedEnd = stripTime(end);
    final days = normalizedEnd.difference(normalizedStart).inDays;
    return List<DateTime>.generate(
      days + 1,
      (index) => normalizedStart.add(Duration(days: index)),
    );
  }

  /// 计算指定月份在月视图中需要展示的行数。
  static int visibleMonthRowCount(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
    MonthViewShowMode monthViewShowMode = MonthViewShowMode.allMonth,
  }) {
    if (monthViewShowMode == MonthViewShowMode.allMonth) {
      return 6;
    }
    final preDiff = monthViewStartDiff(month, firstWeekday: firstWeekday);
    final monthDayCount = daysInMonth(month);
    final nextDiff = monthViewEndDiff(
      month,
      firstWeekday: firstWeekday,
      monthDayCount: monthDayCount,
    );
    return (preDiff + monthDayCount + nextDiff) ~/ 7;
  }

  /// 计算月视图开头需要补齐的日期数量。
  static int monthViewStartDiff(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
  }) {
    final first = firstDayOfMonth(month);
    return (first.weekday - firstWeekday + 7) % 7;
  }

  /// 计算月视图结尾需要补齐的日期数量。
  static int monthViewEndDiff(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
    int? monthDayCount,
  }) {
    final dayCount = monthDayCount ?? daysInMonth(month);
    final last = DateTime(month.year, month.month, dayCount);
    final weekIndex = last.weekday % 7;
    final startWeekday = firstWeekday % 7;
    return (startWeekday + 6 - weekIndex + 7) % 7;
  }

  /// 获取指定月份的天数。
  static int daysInMonth(DateTime month) {
    return lastDayOfMonth(month).day;
  }

  /// 计算指定日期在月视图中的第几行。
  static int weekIndexInMonth(
    DateTime day, {
    int firstWeekday = DateTime.sunday,
  }) {
    final normalized = stripTime(day);
    final preDiff = monthViewStartDiff(normalized, firstWeekday: firstWeekday);
    return ((normalized.day + preDiff - 1) ~/ 7);
  }

  /// 格式化为 yyyy-MM-dd。
  static String formatIsoDate(DateTime date) {
    final normalized = stripTime(date);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}
