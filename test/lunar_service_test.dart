import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/lunar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/calendar/Lunar.dart';

Future<void> _showCalendar(
  WidgetTester tester,
  CalendarController controller, {
  CalendarPageOrientation orientation = CalendarPageOrientation.horizontal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalendarView(
          controller: controller,
          pageOrientation: orientation,
          onDaySelected: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _announcedValue(WidgetTester tester, DateTime date) {
  final localizations = MaterialLocalizations.of(
    tester.element(find.byType(CalendarView)),
  );
  final label = localizations.formatFullDate(date);
  return find.semantics.byLabel(label).evaluate().single.value;
}

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

  test('day labels match lunar across leap months and solar year changes', () {
    void check(DateTime date) {
      final civilDay = DateTime(date.year, date.month, date.day);
      final lunar = Lunar.fromDate(civilDay);
      final term = lunar.getJieQi();
      final actual = LunarService.metadataForDate(date);
      expect(actual.solarTerm, term.isEmpty ? null : term, reason: '$date');
      expect(
        actual.lunarText,
        term.isEmpty ? lunar.getDayInChinese() : term,
        reason: '$date',
      );
    }

    // The 2023 leap second month spans March 22 through April 19.
    for (var day = 20; day <= 52; day++) {
      check(DateTime.utc(2023, 3, day, 23, 59));
    }
    for (var day = 20; day <= 38; day++) {
      check(DateTime(2024, 12, day, 12));
    }
    check(DateTime.utc(2023, 12, 22, 23)); // Switch back to an uncached date.
    check(DateTime(767, 12, 21));
    check(DateTime(1582, 10, 4));
    check(DateTime(1582, 10, 15));

    LunarService.clearCache();
    expect(LunarService.cacheSize, 0);
    check(DateTime(2024, 12, 21));
  });

  test('preserves the upstream Gregorian reform gap', () {
    final missingDay = DateTime(1582, 10, 10);
    final rejectsDate = throwsA(
      equals('wrong solar year 1582 month 10 day 10'),
    );
    expect(() => Lunar.fromDate(missingDay), rejectsDate);
    expect(() => LunarService.metadataForDate(missingDay), rejectsDate);
    expect(LunarService.isDateCached(missingDay), isFalse);
  });

  test('the cache retains recent reads and recomputes evicted solar terms', () {
    final newYear = DateTime(2024, 2, 10);
    final qingming = DateTime(2024, 4, 4);
    final newYearMetadata = LunarService.metadataForDate(newYear);
    final qingmingMetadata = LunarService.metadataForDate(qingming);
    expect(newYearMetadata.lunarText, '初一');
    expect(newYearMetadata.solarTerm, isNull);
    expect(qingmingMetadata.lunarText, '清明');
    expect(qingmingMetadata.solarTerm, '清明');
    LunarService.prefetchDates(
      Iterable.generate(
        LunarService.cacheCapacity - 2,
        (index) => DateTime(2025, 1, 1 + index),
      ),
    );

    // A read of the same civil date at a different time keeps it hot.
    expect(
      LunarService.metadataForDate(DateTime.utc(2024, 2, 10, 23, 59)),
      same(newYearMetadata),
    );
    LunarService.prefetchDates([DateTime(2023, 12, 31)]);
    expect(LunarService.cacheSize, LunarService.cacheCapacity);
    expect(LunarService.isDateCached(newYear), isTrue);
    expect(LunarService.isDateCached(qingming), isFalse);

    final recomputed = LunarService.metadataForDate(qingming);
    expect(recomputed.lunarText, qingmingMetadata.lunarText);
    expect(recomputed.solarTerm, qingmingMetadata.solarTerm);
    expect(LunarService.cacheSize, LunarService.cacheCapacity);
  });

  for (final orientation in CalendarPageOrientation.values) {
    testWidgets('$orientation cross-year jumps only warm pages being built', (
      tester,
    ) async {
      final controller = CalendarController(focusedDay: DateTime(2020, 6, 15));
      addTearDown(controller.dispose);
      await _showCalendar(tester, controller, orientation: orientation);

      // Neither intermediate destination is displayed before the next frame.
      controller.jumpToDay(DateTime(2021, 6, 15));
      controller.jumpToDay(DateTime(2022, 6, 15));
      final qingming = DateTime(2024, 4, 4);
      controller.jumpToDay(qingming);
      await tester.pumpAndSettle();

      expect(_announcedValue(tester, qingming), '清明');
      expect(LunarService.isDateCached(DateTime(2024, 3, 15)), isTrue);
      expect(LunarService.isDateCached(DateTime(2024, 5, 15)), isTrue);
      for (final year in [2021, 2022]) {
        for (final month in [5, 6, 7]) {
          expect(LunarService.isDateCached(DateTime(year, month, 15)), isFalse);
        }
      }
    });
  }

  testWidgets('hidden month padding loads when it becomes a visible week day', (
    tester,
  ) async {
    final qingming = DateTime(2024, 4, 4);
    final controller = CalendarController(
      focusedDay: qingming,
      minDate: DateTime(2024, 4),
      maxDate: DateTime(2024, 4, 30),
    )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
    addTearDown(controller.dispose);
    await _showCalendar(tester, controller);

    final sunday = DateTime(2024, 3, 31);
    expect(_announcedValue(tester, qingming), '清明');
    expect(LunarService.isDateCached(sunday), isFalse);
    expect(LunarService.isDateCached(DateTime(2024, 5)), isFalse);

    controller.setDisplayMode(CalendarDisplayMode.week);
    await tester.pumpAndSettle();
    expect(_announcedValue(tester, sunday), '廿二');
    expect(LunarService.isDateCached(sunday), isTrue);
    expect(_announcedValue(tester, qingming), '清明');
  });
}
