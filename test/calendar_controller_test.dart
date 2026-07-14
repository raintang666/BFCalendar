import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
