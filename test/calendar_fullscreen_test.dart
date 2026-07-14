import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'fullscreen calendar hides month header and fills available height',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 1),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      final interactiveController = CalendarInteractiveController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              interactionController: interactiveController,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2月'), findsOneWidget);

      interactiveController.toggleFullScreen();
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(CalendarView)).height,
        closeTo(844, 0.1),
      );
    },
  );

  testWidgets(
    'dragging down inside calendar area enters fullscreen in horizontal month mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 1),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      final interactiveController = CalendarInteractiveController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              interactionController: interactiveController,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CalendarView)),
      );
      await gesture.moveBy(const Offset(0, 520));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(interactiveController.isFullScreenExpanded, isTrue);
      expect(
        tester.getSize(find.byType(CalendarView)).height,
        closeTo(844, 0.1),
      );
    },
  );

  testWidgets(
    'horizontal paging gesture does not trigger vertical fullscreen stretch',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 4),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      final interactiveController = CalendarInteractiveController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              interactionController: interactiveController,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CalendarView)),
      );
      await gesture.moveBy(const Offset(-220, 48));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(interactiveController.isFullScreenExpanded, isFalse);
      expect(tester.getSize(find.byType(CalendarView)).height, lessThan(844));
    },
  );

  testWidgets('vertical mode fullscreen button shows full-height month list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalendarController(
      focusedDay: DateTime(2026, 2, 1),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 12, 31),
    )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
    final interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.vertical,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarInteractiveView(
            controller: controller,
            interactionController: interactiveController,
            onDaySelected: (_) {},
            contentBuilder: (_, __, ___) => const Text('feed'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('feed'), findsOneWidget);

    interactiveController.toggleFullScreen();
    await tester.pumpAndSettle();

    expect(interactiveController.isFullScreenExpanded, isTrue);
    expect(
      find.byKey(const ValueKey('calendar-vertical-fullscreen-list')),
      findsOneWidget,
    );
    expect(find.text('feed'), findsNothing);
  });

  testWidgets('vertical month pager keeps pinned month label hidden at rest', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CalendarController(
      focusedDay: DateTime(2026, 2, 10),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 12, 31),
    )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
    final interactiveController = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.vertical,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarInteractiveView(
            controller: controller,
            interactionController: interactiveController,
            monthHeaderHeight: 0,
            onDaySelected: (_) {},
            contentBuilder: (_, __, ___) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelOpacityFinder = find.byKey(
      const ValueKey('calendar-vertical-pinned-month-label-opacity'),
    );
    expect(tester.widget<Opacity>(labelOpacityFinder).opacity, 0);
  });

  testWidgets(
    'horizontal month paging keeps selected day when target month contains it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 4),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(PageView).first,
        const Offset(-320, 0),
        900,
      );
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 3, 4));
    },
  );

  testWidgets(
    'horizontal month paging clamps selected day to last day of target month',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 1, 31),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(PageView).first,
        const Offset(-320, 0),
        900,
      );
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 2, 28));
    },
  );

  testWidgets(
    'vertical month paging clamps selected day to last day of target month',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 1, 31),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      final interactiveController = CalendarInteractiveController(
        pageOrientation: CalendarPageOrientation.vertical,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              interactionController: interactiveController,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(const ValueKey('calendar-vertical-pager')),
        const Offset(0, -500),
        900,
      );
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 2, 28));
    },
  );

  testWidgets(
    'vertical month paging keeps latest selected day when paging back',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 1, 31),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      final interactiveController = CalendarInteractiveController(
        pageOrientation: CalendarPageOrientation.vertical,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarInteractiveView(
              controller: controller,
              interactionController: interactiveController,
              onDaySelected: (_) {},
              contentBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(const ValueKey('calendar-vertical-pager')),
        const Offset(0, -500),
        900,
      );
      await tester.pumpAndSettle();
      expect(controller.focusedDay, DateTime(2026, 2, 28));

      await tester.fling(
        find.byKey(const ValueKey('calendar-vertical-pager')),
        const Offset(0, 500),
        900,
      );
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 1, 28));
    },
  );
}
