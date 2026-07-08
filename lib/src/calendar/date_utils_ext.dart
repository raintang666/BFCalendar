class CalendarDateUtils {
  const CalendarDateUtils._();

  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static DateTime addMonths(DateTime date, int delta) {
    final monthIndex = date.month + delta;
    final targetYear = date.year + ((monthIndex - 1) ~/ 12);
    final targetMonth = ((monthIndex - 1) % 12 + 12) % 12 + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    return DateTime(targetYear, targetMonth, date.day.clamp(1, lastDay));
  }

  static List<DateTime> visibleMonthDays(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
  }) {
    final first = firstDayOfMonth(month);
    final offset = (first.weekday - firstWeekday + 7) % 7;
    final gridStart = first.subtract(Duration(days: offset));
    return List<DateTime>.generate(
      42,
      (index) => stripTime(gridStart.add(Duration(days: index))),
    );
  }

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

  static List<DateTime> eachDay(DateTime start, DateTime end) {
    final normalizedStart = stripTime(start);
    final normalizedEnd = stripTime(end);
    final days = normalizedEnd.difference(normalizedStart).inDays;
    return List<DateTime>.generate(
      days + 1,
      (index) => normalizedStart.add(Duration(days: index)),
    );
  }

  static int visibleMonthRowCount(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
    bool onlyCurrentMonth = false,
  }) {
    if (!onlyCurrentMonth) {
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

  static int monthViewStartDiff(
    DateTime month, {
    int firstWeekday = DateTime.sunday,
  }) {
    final first = firstDayOfMonth(month);
    return (first.weekday - firstWeekday + 7) % 7;
  }

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

  static int daysInMonth(DateTime month) {
    return lastDayOfMonth(month).day;
  }

  static int weekIndexInMonth(
    DateTime day, {
    int firstWeekday = DateTime.sunday,
  }) {
    final normalized = stripTime(day);
    final preDiff = monthViewStartDiff(
      normalized,
      firstWeekday: firstWeekday,
    );
    return ((normalized.day + preDiff - 1) ~/ 7);
  }
}
