import 'package:lunar/calendar/Lunar.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

class LunarService {
  const LunarService._();

  static LunarMetadata metadataForDate(DateTime date) {
    final lunar = Lunar.fromDate(CalendarDateUtils.stripTime(date));
    final jieQi = lunar.getJieQi();
    return LunarMetadata(
      lunarText: jieQi.isNotEmpty ? jieQi : lunar.getDayInChinese(),
      solarTerm: jieQi.isEmpty ? null : jieQi,
    );
  }
}
