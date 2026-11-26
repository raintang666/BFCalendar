import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/date_utils_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TZ=America/New_York flutter test test/calendar_date_transition_test.dart
void main() {
  test(
    'month and week grids contain consecutive local dates across fall back',
    () {
      final start = DateTime(2026, 11, 1);
      List<DateTime> novemberDays(int count) =>
          List.generate(count, (index) => DateTime(2026, 11, index + 1));

      expect(CalendarDateUtils.visibleMonthDays(start), novemberDays(42));
      expect(
        CalendarDateUtils.visibleWeekDays(DateTime(2026, 11, 4)),
        novemberDays(7),
      );
    },
  );

  test('range selection counts both local dates across spring forward', () {
    final controller = CalendarController(minSelectRange: 2, maxSelectRange: 2)
      ..setInterceptBlocked(false)
      ..setSelectionMode(CalendarSelectionMode.range);
    addTearDown(controller.dispose);
    final first = DateTime(2026, 3, 8);
    final last = DateTime(2026, 3, 9);

    expect(controller.selectDay(last), isTrue);
    expect(controller.selectDay(first), isTrue);
    expect(controller.selectedRangeDates, [first, last]);
    controller.setRangeSelectionLimits(minRange: 2, maxRange: 3);
    expect(controller.selectedRangeDates, [first, last]);
    expect(
      CalendarDateUtils.eachDay(DateTime(2026, 10, 31), DateTime(2026, 11, 2)),
      [DateTime(2026, 10, 31), DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
    );
  });

  test('week navigation keeps its weekday across both clock changes', () {
    final controller = CalendarController()
      ..setDisplayMode(CalendarDisplayMode.week);
    addTearDown(controller.dispose);
    for (final date in [DateTime(2026, 3, 3), DateTime(2026, 10, 28)]) {
      controller.jumpToDay(date);
      controller.nextPage();
      expect(
        controller.focusedDay,
        DateTime(date.year, date.month, date.day + 7),
      );
      controller.previousPage();
      expect(controller.focusedDay, date);
    }
  });

  testWidgets(
    'range cells use the adjacent calendar date across clock changes',
    (tester) async {
      final controller = CalendarController()
        ..setInterceptBlocked(false)
        ..setSelectionMode(CalendarSelectionMode.range);
      addTearDown(controller.dispose);
      final cells = _CapturedDays();
      for (final first in [DateTime(2026, 3, 8), DateTime(2026, 11, 1)]) {
        final last = DateTime(first.year, first.month, first.day + 1);
        controller.selectDay(first);
        controller.selectDay(first);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CalendarView(
                controller: controller,
                pageOrientation: CalendarPageOrientation.horizontal,
                onDaySelected: (_) {},
                componentBuilder: cells,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(cells.days[first]!.isSelectedPrevious, isFalse);
        expect(cells.days[first]!.isSelectedNext, isFalse);
        expect(cells.days[last]!.isSelectedPrevious, isTrue);
        expect(cells.days[last]!.isSelectedNext, isFalse);
      }
    },
  );
}

class _CapturedDays extends DefaultCalendarComponentBuilder {
  final days = <DateTime, CalendarDayCellData>{};

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    days[data.date] = data;
    return super.buildDayCell(context, data);
  }
}
