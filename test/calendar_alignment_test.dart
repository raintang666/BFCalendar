import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'week bar columns stay horizontally aligned with calendar cells',
    (tester) async {
      final semantics = tester.ensureSemantics();
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

      final weekBarSunday = _center(
        find.semantics.byLabel('周日').evaluate().single,
      );
      final dateLabel = MaterialLocalizations.of(
        tester.element(find.byType(CalendarView)),
      ).formatFullDate(DateTime(2026, 2, 1));
      final firstDay = _center(
        find.semantics.byLabel(dateLabel).evaluate().single,
      );

      expect((weekBarSunday.dx - firstDay.dx).abs(), lessThan(0.1));
      semantics.dispose();
    },
  );
}

Offset _center(SemanticsNode node) {
  var center = node.rect.center;
  for (
    SemanticsNode? current = node;
    current != null;
    current = current.parent
  ) {
    if (current.transform case final transform?) {
      center = MatrixUtils.transformPoint(transform, center);
    }
  }
  return center;
}
