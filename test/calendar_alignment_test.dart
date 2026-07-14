import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'week bar columns stay horizontally aligned with calendar cells',
    (tester) async {
      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 1),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarView(
              controller: controller,
              pageOrientation: CalendarPageOrientation.horizontal,
              onDaySelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final weekBarSunday = tester.getCenter(find.text('周日'));
      final firstDay = tester.getCenter(find.text('1').first);

      expect((weekBarSunday.dx - firstDay.dx).abs(), lessThan(0.1));
    },
  );
}
