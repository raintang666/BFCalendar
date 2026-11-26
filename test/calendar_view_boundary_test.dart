import 'dart:ui' show Tristate;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final monthList in [false, true]) {
    testWidgets(
      'pulling the earliest month rebounds in vertical list=$monthList',
      (tester) async {
        final controller = CalendarController(
          focusedDay: DateTime(2026, 7, 9),
          minDate: DateTime(2026, 7, 3),
          maxDate: DateTime(2026, 10, 31),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              platform: monthList ? TargetPlatform.iOS : TargetPlatform.android,
            ),
            home: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 390,
                height: 500,
                child: monthList
                    ? CalendarMonthListView(
                        controller: controller,
                        calendarHeight: 62,
                        weekBarHeight: 46,
                        onDaySelected: (_) {},
                      )
                    : CalendarView(
                        controller: controller,
                        pageOrientation: CalendarPageOrientation.vertical,
                        onDaySelected: (_) {},
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final visible = find
            .byKey(const ValueKey('calendar-canvas-grid'))
            .hitTestable()
            .first;
        final firstMonth = tester.element(visible);
        final surface = find.byElementPredicate((e) => e == firstMonth);
        final resting = tester.getSize(surface).height;
        final start = tester.getTopLeft(surface) + const Offset(60, 70);
        final drag = await tester.startGesture(start);
        await drag.moveBy(const Offset(0, 100));
        await tester.pump();
        expect(tester.getSize(surface).height, greaterThan(resting));
        if (monthList) {
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position;
          expect(position.pixels, position.minScrollExtent);
        }
        await drag.up();
        await tester.pumpAndSettle();
        expect(tester.getSize(surface).height, resting);
        expect(controller.focusedDay, DateTime(2026, 7, 9));
        await tester.flingFrom(start, const Offset(0, -220), 900);
        await tester.pumpAndSettle();
        if (monthList) {
          expect(
            tester
                .state<ScrollableState>(find.byType(Scrollable))
                .position
                .pixels,
            greaterThan(0),
          );
        } else {
          expect(controller.focusedDay.month, 8);
          final nextMonth = tester.element(visible);
          final nextSurface = find.byElementPredicate((e) => e == nextMonth);
          final nextHeight = tester.getSize(nextSurface).height;
          final back = await tester.startGesture(start);
          await back.moveBy(const Offset(0, 60));
          await tester.pump();
          expect(tester.getSize(nextSurface).height, nextHeight);
          await back.up();
          await tester.pumpAndSettle();
        }
      },
    );
  }

  testWidgets('swiping to another month follows the selected day of month', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalendarController(
      focusedDay: DateTime(2024, 6, 12),
      minDate: DateTime(2024, 6, 1),
      maxDate: DateTime(2024, 8, 31),
    )..setInterceptBlocked(false);
    final tappedDays = <DateTime>[];
    final pageChanges = <DateTime>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            controller: controller,
            pageOrientation: CalendarPageOrientation.horizontal,
            handleDaySelection: true,
            onDaySelected: tappedDays.add,
            onPageChanged: pageChanges.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(CalendarView)),
    );
    final originalDay = DateTime(2024, 6, 18);
    tester.semantics.tap(
      find.semantics.byLabel(localizations.formatFullDate(originalDay)),
    );
    await tester.pumpAndSettle();
    expect(controller.selection.single, originalDay);

    await tester.drag(find.byType(PageView).first, const Offset(-240, 0));
    await tester.pumpAndSettle();

    final nextDay = DateTime(2024, 7, 18);
    expect(controller.selection.single, nextDay);
    expect(controller.focusedDay, nextDay);
    expect(tappedDays, [originalDay]);
    expect(pageChanges, [nextDay]);
    final selectedCell = find.semantics
        .byLabel(localizations.formatFullDate(nextDay))
        .evaluate()
        .single;
    expect(selectedCell.flagsCollection.isSelected, Tristate.isTrue);
  });

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

      expect(find.semantics.byLabel('8月'), findsOne);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(focusedHistory, isNotEmpty);
      expect(
        focusedHistory.map((item) => item.month).toList(),
        isNot(contains(8)),
      );
      expect(controller.focusedDay.month, 7);
      expect(find.semantics.byLabel('7月'), findsOne);
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

    expect(find.semantics.byLabel('4月'), findsOne);

    await tester.drag(find.byType(PageView).first, const Offset(-240, 0));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.focusedDay, DateTime(2019, 4, 28));
    expect(find.semantics.byLabel('4月'), findsOne);
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

      expect(find.semantics.byLabel('3月'), findsOne);

      await tester.drag(find.byType(PageView).first, const Offset(-240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.focusedDay.month, 4);
      expect(find.semantics.byLabel('4月'), findsOne);

      await tester.drag(find.byType(PageView).first, const Offset(240, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.focusedDay.month, 3);
      expect(find.semantics.byLabel('3月'), findsOne);
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

      expect(find.semantics.byLabel('4月'), findsOne);

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
      expect(find.semantics.byLabel('12月'), findsOne);
    },
  );
}
