import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder holidayShortcut(HolidayScene scene) =>
    find.byKey(ValueKey('holiday-shortcut-${scene.name}'));

Future<void> openHolidayPicker(WidgetTester tester) async {
  final entry = find.widgetWithText(TextButton, '全部光影');
  final pageScroll = find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(entry, 180, scrollable: pageScroll);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> selectHolidayShortcut(
  WidgetTester tester,
  HolidayScene scene,
  DateTime date,
) async {
  final calendar = tester.widget<CalendarView>(find.byType(CalendarView));
  final focused = calendar.controller.focusedDay;
  var shortcut = holidayShortcut(scene);
  if (date.year != focused.year || date.month != focused.month) {
    await openHolidayPicker(tester);
    final month = find.byKey(
      ValueKey('holiday-picker-month-${date.year}-${date.month}'),
    );
    await tester.ensureVisible(month);
    await tester.pumpAndSettle();
    await tester.tap(month);
    await tester.pumpAndSettle();
    shortcut = find.descendant(
      of: find.byType(BottomSheet),
      matching: shortcut,
    );
  } else {
    final pageScroll = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(shortcut, 180, scrollable: pageScroll);
  }
  await Scrollable.ensureVisible(tester.element(shortcut), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(shortcut);
  await tester.pumpAndSettle();
}
