import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('year mode clamps pages and disables months outside range', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final monthYearController = CalendarMonthYearController();
    DateTime? selectedMonth;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarYearModeLayout(
            controller: monthYearController,
            selectedDate: DateTime(2024, 6, 12),
            minDate: DateTime(2024, 2, 3),
            maxDate: DateTime(2025, 10, 20),
            style: CalendarYearModeStyle.vertical,
            onMonthSelected: (month) {
              selectedMonth = month;
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    monthYearController.showYearMode();
    await tester.pumpAndSettle();

    expect(find.text('2024年'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Jan')).style?.color,
      CalendarYearModeStyle.vertical.disabledMonthTextColor,
    );

    await tester.tap(find.text('Jan'));
    await tester.pumpAndSettle();
    expect(selectedMonth, isNull);
    expect(find.text('2024年'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2025年'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2025年'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Dec')).style?.color,
      CalendarYearModeStyle.vertical.disabledMonthTextColor,
    );

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2024年'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(find.text('2024年'), findsOneWidget);
  });

  testWidgets(
    'month pager stays on min boundary month after swiping from next month',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2018, 8, 15),
        minDate: DateTime(2018, 7, 1),
        maxDate: DateTime(2019, 4, 28),
      );
      final focusedHistory = <DateTime>[];
      controller.addListener(() {
        focusedHistory.add(controller.focusedDay);
      });

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

      expect(find.text('8月'), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(focusedHistory, isNotEmpty);
      expect(
        focusedHistory.map((item) => item.month).toList(),
        isNot(contains(8)),
      );
      expect(controller.focusedDay.month, 7);
      expect(find.text('7月'), findsOneWidget);
    },
  );

  testWidgets('month pager does not leave current page at max boundary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalendarController(
      focusedDay: DateTime(2019, 4, 28),
      minDate: DateTime(2018, 7, 1),
      maxDate: DateTime(2019, 4, 28),
    );

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

    expect(find.text('4月'), findsOneWidget);

    await tester.drag(find.byType(PageView).first, const Offset(-240, 0));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.focusedDay, DateTime(2019, 4, 28));
    expect(find.text('4月'), findsOneWidget);
  });

  testWidgets(
    'month pager can still swipe back after reaching max boundary month',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2019, 3, 15),
        minDate: DateTime(2018, 7, 1),
        maxDate: DateTime(2019, 4, 28),
      );

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

      expect(find.text('3月'), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(-240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.focusedDay.month, 4);
      expect(find.text('4月'), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.focusedDay.month, 3);
      expect(find.text('3月'), findsOneWidget);
    },
  );

  testWidgets(
    'month pager can still swipe backward in non-boundary months near max range',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2019, 4, 15),
        minDate: DateTime(2018, 7, 1),
        maxDate: DateTime(2019, 4, 28),
      );
      final focusedHistory = <DateTime>[];
      controller.addListener(() {
        focusedHistory.add(controller.focusedDay);
      });

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

      expect(find.text('4月'), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(controller.focusedDay.month, 3);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(controller.focusedDay.month, 2);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.focusedDay.year, 2019);
      expect(controller.focusedDay.month, 1);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(focusedHistory, isNotEmpty);
      expect(
        controller.focusedDay.year,
        2018,
        reason: 'focusedHistory=$focusedHistory',
      );
      expect(
        controller.focusedDay.month,
        12,
        reason: 'focusedHistory=$focusedHistory',
      );
      expect(find.text('12月'), findsOneWidget);
    },
  );
}
