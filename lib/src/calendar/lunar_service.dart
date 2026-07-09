import 'package:lunar/calendar/Lunar.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

class LunarService {
  const LunarService._();

  static final Map<int, LunarMetadata> _metadataCache = <int, LunarMetadata>{};

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

  static void prefetchDates(Iterable<DateTime> dates) {
    for (final date in dates) {
      metadataForDate(date);
    }
  }

  static int _cacheKey(DateTime date) {
    return (date.year * 10000) + (date.month * 100) + date.day;
  }

  static void clearCache() {
    _metadataCache.clear();
  }

  static int get cacheSize {
    return _metadataCache.length;
  }

  static bool isDateCached(DateTime date) {
    final normalized = CalendarDateUtils.stripTime(date);
    return _metadataCache.containsKey(_cacheKey(normalized));
  }
}
