import 'package:lunar/calendar/Lunar.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

/// 农历和节气元数据服务。
class LunarService {
  /// 禁止实例化。
  const LunarService._();

  static final Map<int, LunarMetadata> _metadataCache = <int, LunarMetadata>{};

  /// 获取指定日期的农历和节气信息。
  static LunarMetadata metadataForDate(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    final cacheKey = _cacheKey(normalized);
    return _metadataCache.putIfAbsent(cacheKey, () {
      final lunar = Lunar.fromDate(normalized);
      final jieQi = lunar.getJieQi();
      return LunarMetadata(
        lunarText: jieQi.isNotEmpty ? jieQi : lunar.getDayInChinese(),
        solarTerm: jieQi.isEmpty ? null : jieQi,
      );
    });
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
