import 'dart:ui';

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain marker maps keep date normalization and payload identity', () {
    final day = DateTime(2026, 7, 9);
    const before = _LegacyMarker(label: 'before', color: Color(0xFF000000));
    final payload = Object();
    final marker = CalendarMarker(
      label: 'event',
      color: const Color(0xFF000000),
      data: payload,
    );
    final list = <CalendarMarker>[marker];
    final input = {
      DateTime.utc(2026, 7, 9, 9): [before],
      DateTime(2026, 7, 9, 12): list,
    };
    final controller = CalendarController(markers: input);
    addTearDown(controller.dispose);

    expect(before.data, isNull);
    expect(controller.markers.keys, [day]);
    expect(controller.markers[day], same(list));
    expect(controller.markers[day]!.single.data, same(payload));
    input.clear();
    expect(controller.markers[day], same(list));

    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.setMarkers({
      DateTime(2026, 7, 9, 21): [before],
    });
    expect(controller.markers[day], [before]);
    expect(notifications, 1);
  });

  test(
    'large normalized marker maps are detached and preserve insertion order',
    () {
      final source = <DateTime, List<CalendarMarker>>{
        for (var i = 0; i < 1100; i++) DateTime(2026, 1, 1 + i): [],
      };
      final originalDays = source.keys.toList();
      final firstDay = originalDays.first;
      final firstMarkers = source[firstDay];
      final controller = CalendarController()..setMarkers(source);
      addTearDown(controller.dispose);
      source.clear();

      expect(controller.markers.keys, originalDays);
      expect(controller.markers[firstDay], same(firstMarkers));
      expect(controller.markers.remove(firstDay), same(firstMarkers));
      expect(controller.markers.containsKey(firstDay), isFalse);
    },
  );

  test(
    'large marker maps keep normalized collisions in their first position',
    () {
      final source = <DateTime, List<CalendarMarker>>{
        for (var i = 0; i < 1100; i++) DateTime(2026, 1, 1 + i): [],
      };
      final originalDays = source.keys.toList();
      final firstDay = originalDays.first;
      final finalDay = DateTime(2030, 1, 1);
      final laterMarkers = <CalendarMarker>[
        const CalendarMarker(label: 'later', color: Color(0xFF000000)),
      ];
      source[DateTime.utc(2026, 1, 1, 12)] = [];
      source[DateTime(2030, 1, 1, 12)] = [];
      source[DateTime(2026, 1, 1, 23)] = laterMarkers;
      final controller = CalendarController(markers: source);
      addTearDown(controller.dispose);

      expect(controller.markers.keys, [...originalDays, finalDay]);
      expect(controller.markers[firstDay], same(laterMarkers));
    },
  );

  test('setRange clamps focused day and exposes original-style range text', () {
    final controller = CalendarController(
      focusedDay: DateTime(2020, 5, 12),
      minDate: DateTime(1, 1, 1),
      maxDate: DateTime(9999, 12, 31),
    );

    final changed = controller.setRange(2018, 7, 1, 2019, 4, 28);

    expect(changed, isTrue);
    expect(controller.focusedDay, DateTime(2018, 7, 1));
    expect(controller.minRangeCalendar, DateTime(2018, 7, 1));
    expect(controller.maxRangeCalendar, DateTime(2019, 4, 28));
    expect(
      controller.rangeDescription,
      'Calendar Range: 2018-07-01 —— 2019-04-28',
    );
  });

  test('setCalendarRange rejects invalid bounds', () {
    final controller = CalendarController(
      focusedDay: DateTime(2020, 5, 12),
      minDate: DateTime(1, 1, 1),
      maxDate: DateTime(9999, 12, 31),
    );

    final changed = controller.setCalendarRange(
      minDate: DateTime(2020, 12, 1),
      maxDate: DateTime(2020, 1, 1),
    );

    expect(changed, isFalse);
    expect(controller.minRangeCalendar, DateTime(1, 1, 1));
    expect(controller.maxRangeCalendar, DateTime(9999, 12, 31));
  });

  test('range selection limits are enforced by controller', () {
    final controller =
        CalendarController(
            focusedDay: DateTime(2024, 1, 7),
            minSelectRange: 3,
            maxSelectRange: 5,
          )
          ..setInterceptBlocked(false)
          ..setSelectionMode(CalendarSelectionMode.range);

    expect(controller.minSelectRange, 3);
    expect(controller.maxSelectRange, 5);

    expect(controller.selectDay(DateTime(2024, 1, 7)), isTrue);
    expect(controller.rangeSelection.start, DateTime(2024, 1, 7));

    expect(
      controller.rangeSelectionLimitViolation(DateTime(2024, 1, 8)),
      CalendarRangeLimitViolation.belowMinRange,
    );
    expect(controller.selectDay(DateTime(2024, 1, 8)), isFalse);
    expect(controller.focusedDay, DateTime(2024, 1, 7));
    expect(controller.rangeSelection.end, isNull);

    expect(
      controller.rangeSelectionLimitViolation(DateTime(2024, 1, 14)),
      CalendarRangeLimitViolation.aboveMaxRange,
    );
    expect(controller.selectDay(DateTime(2024, 1, 14)), isFalse);
    expect(controller.rangeSelection.end, isNull);

    expect(controller.selectDay(DateTime(2024, 1, 10)), isTrue);
    expect(controller.rangeSelection.end, DateTime(2024, 1, 10));
    expect(controller.selectedRangeDates.length, 4);
  });

  test('range selection limit updates reject invalid pairs', () {
    final controller = CalendarController(focusedDay: DateTime(2024, 1, 7));

    expect(
      controller.setRangeSelectionLimits(minRange: 6, maxRange: 3),
      isFalse,
    );
    expect(controller.minSelectRange, -1);
    expect(controller.maxSelectRange, -1);

    expect(
      controller.setRangeSelectionLimits(minRange: 2, maxRange: 4),
      isTrue,
    );
    expect(controller.minSelectRange, 2);
    expect(controller.maxSelectRange, 4);
  });

  test('multi selection obeys max size and still allows deselect', () {
    final controller =
        CalendarController(
            focusedDay: DateTime(2024, 1, 7),
            maxMultiSelectSize: 2,
          )
          ..setInterceptBlocked(false)
          ..setSelectionMode(CalendarSelectionMode.multi);

    expect(controller.selectDay(DateTime(2024, 1, 7)), isTrue);
    expect(controller.selectDay(DateTime(2024, 1, 8)), isTrue);
    expect(controller.selectedMultiDates.length, 2);
    expect(controller.isMultiSelectOutOfSize(DateTime(2024, 1, 9)), isTrue);

    expect(controller.selectDay(DateTime(2024, 1, 9)), isFalse);
    expect(controller.selectedMultiDates.length, 2);

    expect(controller.selectDay(DateTime(2024, 1, 8)), isTrue);
    expect(controller.selectedMultiDates, [DateTime(2024, 1, 7)]);
  });

  test('page navigation is blocked at month range boundaries', () {
    final controller = CalendarController(
      focusedDay: DateTime(2019, 4, 28),
      minDate: DateTime(2018, 7, 1),
      maxDate: DateTime(2019, 4, 28),
    );

    expect(controller.canNavigateToNextPage(), isFalse);
    expect(controller.canNavigateToPreviousPage(), isTrue);

    controller.nextPage();

    expect(controller.focusedDay, DateTime(2019, 4, 28));
  });

  test('edge months that overlap range are still reachable', () {
    final controller = CalendarController(
      focusedDay: DateTime(2018, 8, 20),
      minDate: DateTime(2018, 7, 15),
      maxDate: DateTime(2018, 12, 31),
    );

    controller.previousPage();

    expect(controller.focusedDay, DateTime(2018, 7, 20));
    expect(controller.canNavigateToPreviousPage(), isFalse);
  });

  test(
    'week navigation clamps to range edge inside partially visible week',
    () {
      final controller = CalendarController(
        focusedDay: DateTime(2019, 4, 26),
        minDate: DateTime(2018, 7, 1),
        maxDate: DateTime(2019, 4, 28),
      )..setDisplayMode(CalendarDisplayMode.week);

      expect(controller.canNavigateToNextPage(), isTrue);
      expect(
        controller.resolvedPageAnchorForRelative(1),
        DateTime(2019, 4, 28),
      );

      controller.nextPage();

      expect(controller.focusedDay, DateTime(2019, 4, 28));
      expect(controller.canNavigateToNextPage(), isFalse);
    },
  );

  test('month navigation crosses year boundary correctly', () {
    final controller = CalendarController(
      focusedDay: DateTime(2019, 1, 15),
      minDate: DateTime(2018, 7, 1),
      maxDate: DateTime(2019, 4, 28),
    );

    expect(controller.canNavigateToPreviousPage(), isTrue);

    controller.previousPage();

    expect(controller.focusedDay, DateTime(2018, 12, 15));
  });

  test('month navigation restores the last explicitly selected day', () {
    final controller = CalendarController(focusedDay: DateTime(2024, 1, 10));
    final selections = <DateTime?>[];
    controller.addListener(() => selections.add(controller.selection.single));

    expect(controller.selectDay(DateTime(2024, 1, 31)), isTrue);
    controller.nextPage();
    expect(controller.focusedDay, DateTime(2024, 2, 29));
    controller.nextPage();
    expect(controller.focusedDay, DateTime(2024, 3, 31));
    controller.jumpToMonth(DateTime(2024, 4));
    expect(controller.focusedDay, DateTime(2024, 4, 30));
    controller.previousPage();
    expect(controller.focusedDay, DateTime(2024, 3, 31));

    expect(selections, [
      DateTime(2024, 1, 31),
      DateTime(2024, 2, 29),
      DateTime(2024, 3, 31),
      DateTime(2024, 4, 30),
      DateTime(2024, 3, 31),
    ]);
  });

  test('month selection respects disabled dates and partial month bounds', () {
    final controller = CalendarController(
      focusedDay: DateTime(2024, 1, 31),
      maxDate: DateTime(2024, 3, 28),
      disabledDates: {DateTime(2024, 2, 29)},
    );

    controller.nextPage();
    expect(controller.focusedDay, DateTime(2024, 2, 29));
    expect(controller.selection.single, DateTime(2024, 1, 31));

    controller.nextPage();
    expect(controller.focusedDay, DateTime(2024, 3, 28));
    expect(controller.selection.single, DateTime(2024, 3, 28));
  });

  test(
    'disabled date lookup uses the supplied calendar day in UTC and local time',
    () {
      final dates = {
        DateTime.utc(2024, 2, 29, 23, 59),
        DateTime(2024, 3, 2, 8),
      };
      final controller = CalendarController(disabledDates: dates)
        ..setInterceptBlocked(false);
      addTearDown(controller.dispose);
      dates.clear();

      expect(controller.isDisabled(DateTime(2024, 2, 29, 12)), isTrue);
      expect(controller.isDisabled(DateTime.utc(2024, 3, 2, 23, 59)), isTrue);
      expect(controller.selectDay(DateTime(2024, 3, 2, 7)), isFalse);
      expect(controller.selectDay(DateTime.utc(2024, 3, 1, 23, 59)), isTrue);
    },
  );
}

class _LegacyMarker extends CalendarMarker {
  const _LegacyMarker({required super.label, required super.color});
}
