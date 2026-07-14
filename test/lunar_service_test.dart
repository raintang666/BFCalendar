import 'package:calendarview_flutter/src/calendar/lunar_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LunarService.clearCache);

  test('prefetchDates warms and reuses cached lunar metadata', () {
    final firstDay = DateTime(2026, 7, 9);
    final secondDay = DateTime(2026, 7, 10);

    expect(LunarService.cacheSize, 0);

    LunarService.prefetchDates([firstDay, secondDay, DateTime(2026, 7, 9)]);

    expect(LunarService.isDateCached(firstDay), isTrue);
    expect(LunarService.isDateCached(secondDay), isTrue);
    expect(LunarService.cacheSize, 2);
    expect(LunarService.metadataForDate(firstDay).lunarText, isNotEmpty);
    expect(LunarService.cacheSize, 2);
  });
}
