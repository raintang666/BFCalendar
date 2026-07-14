import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:calendarview_flutter/src/features/ios_calendar/ios_calendar_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar view can hot swap week and month style at runtime', (
    tester,
  ) async {
    final controller = CalendarController(
      focusedDay: DateTime(2026, 7, 9),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 12, 31),
    );

    Future<void> pumpCalendar(CalendarComponentBuilder componentBuilder) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarView(
              controller: controller,
              pageOrientation: CalendarPageOrientation.horizontal,
              componentBuilder: componentBuilder,
              onDaySelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpCalendar(const CustomCalendarComponentBuilder());
    expect(find.text('周日'), findsOneWidget);
    expect(find.text('SUN'), findsNothing);

    await pumpCalendar(const MeizuCalendarComponentBuilder());
    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('周日'), findsNothing);

    await pumpCalendar(const IOSCalendarComponentBuilder());
    expect(find.text('日'), findsOneWidget);
    expect(find.text('SUN'), findsNothing);
  });
}
