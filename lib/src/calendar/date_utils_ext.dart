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
    final days = visibleMonthDays(month, firstWeekday: firstWeekday);
    if (!onlyCurrentMonth) {
      return 6;
    }
    var firstIndex = -1;
    var lastIndex = -1;
    for (var i = 0; i < days.length; i++) {
      if (isSameMonth(days[i], month)) {
        firstIndex = i;
        break;
      }
    }
    for (var i = days.length - 1; i >= 0; i--) {
      if (isSameMonth(days[i], month)) {
        lastIndex = i;
        break;
      }
    }
    if (firstIndex < 0 || lastIndex < 0) {
      return 6;
    }
    return ((lastIndex ~/ 7) - (firstIndex ~/ 7)) + 1;
  }
}
