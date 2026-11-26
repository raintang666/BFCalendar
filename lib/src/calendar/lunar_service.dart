import 'package:lunar/lunar.dart' show Lunar, LunarUtil, LunarYear, Solar;

import 'calendar_models.dart';
import 'date_utils_ext.dart';

/// 农历和节气元数据服务。
class LunarService {
  /// 禁止实例化。
  const LunarService._();

  /// 可同时容纳两个不相邻月份及其前后页，每页最多 42 个日期。
  static const int cacheCapacity = 256;
  static final Map<int, LunarMetadata> _metadataCache = <int, LunarMetadata>{};

  static _LunarYearDays? _yearDays;

  /// 获取指定日期的农历和节气信息。
  static LunarMetadata metadataForDate(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    final cacheKey = _cacheKey(normalized);
    final cached = _metadataCache.remove(cacheKey);
    if (cached != null) {
      _metadataCache[cacheKey] = cached;
      return cached;
    }

    final metadata = _computeMetadata(normalized);
    if (_metadataCache.length == cacheCapacity) {
      _metadataCache.remove(_metadataCache.keys.first);
    }
    _metadataCache[cacheKey] = metadata;
    return metadata;
  }

  static LunarMetadata _computeMetadata(DateTime date) {
    // Let lunar handle its Julian calendar and the 1582 Gregorian reform.
    if (date.year <= 1582) return _fullLunarMetadata(date);
    var yearDays = _yearDays;
    if (yearDays == null || yearDays.year != date.year) {
      _yearDays = yearDays = _LunarYearDays(date.year);
    }
    return yearDays.metadataForDate(date);
  }

  /// 预加载一批日期的农历信息。
  static void prefetchDates(Iterable<DateTime> dates) {
    for (final date in dates) {
      metadataForDate(date);
    }
  }

  static int _cacheKey(DateTime date) {
    return (date.year * 10000) + (date.month * 100) + date.day;
  }

  /// 清空农历信息缓存。
  static void clearCache() {
    _metadataCache.clear();
    _yearDays = null;
  }

  /// 当前缓存条目数量。
  static int get cacheSize {
    return _metadataCache.length;
  }

  /// 判断指定日期是否已经缓存。
  static bool isDateCached(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    return _metadataCache.containsKey(_cacheKey(normalized));
  }
}

/// 复用上游库计算的农历月界和节气日期，只保留最近使用的一个公历年。
class _LunarYearDays {
  _LunarYearDays(this.year) {
    final lunarYear = LunarYear.fromYear(year);
    for (final month in lunarYear.getMonths()) {
      _months.add((
        start: Solar.fromJulianDay(month.getFirstJulianDay()),
        length: month.getDayCount(),
      ));
    }
    for (final julianDay in lunarYear.getJieQiJulianDays()) {
      final term = Solar.fromJulianDay(julianDay);
      if (term.getYear() == year) {
        _termDates.add(term.getMonth() * 100 + term.getDay());
      }
    }
  }

  final int year;
  final _months = <({Solar start, int length})>[];
  final _termDates = <int>{};

  LunarMetadata metadataForDate(DateTime date) {
    if (_termDates.contains(date.month * 100 + date.day)) {
      return _fullLunarMetadata(date);
    }
    final solar = Solar.fromDate(date);
    for (final month in _months) {
      final offset = solar.subtract(month.start);
      if (offset < 0) break;
      if (offset < month.length) {
        return LunarMetadata(lunarText: LunarUtil.DAY[offset + 1]);
      }
    }
    return _fullLunarMetadata(date);
  }
}

// 直接取上游节气名称，包括跨年节气的别名处理。
LunarMetadata _fullLunarMetadata(DateTime date) {
  final lunar = Lunar.fromDate(date);
  final term = lunar.getJieQi();
  return LunarMetadata(
    lunarText: term.isEmpty ? lunar.getDayInChinese() : term,
    solarTerm: term.isEmpty ? null : term,
  );
}
