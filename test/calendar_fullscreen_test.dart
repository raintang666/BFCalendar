import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month rows use only drag beyond the expanded viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = CalendarController(
      focusedDay: DateTime(2026, 2, 10),
      minDate: DateTime(2026, 2),
      maxDate: DateTime(2026, 2, 28),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarInteractiveView(
          controller: controller,
          onDaySelected: (_) {},
          contentBuilder: (_, __, ___) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final grid = find.byKey(const ValueKey('calendar-canvas-grid'));
    final calendar = find.byType(CalendarView);
    final headerHeight =
        tester.getSize(calendar).height - tester.getSize(grid).height;
    final drag = await tester.startGesture(
      tester.getTopLeft(grid) + const Offset(80, 25),
    );
    await drag.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(
      tester.getSize(grid).height,
      closeTo(tester.getSize(calendar).height - headerHeight, .01),
    );
    await drag.moveBy(const Offset(0, 570));
    await tester.pump();
    final resting = 844 - headerHeight;
    expect(tester.getSize(calendar).height, 844);
    expect(tester.getSize(grid).height, greaterThan(resting));
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(grid).height, closeTo(resting, .01));
    expect(controller.displayMode, CalendarDisplayMode.month);
  });

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

      expect(find.semantics.byLabel('2月'), findsOne);

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

  for (final fromList in [false, true]) {
    testWidgets(
      'short vertical flings settle all calendar heights from the ${fromList ? 'list' : 'calendar'}',
      (tester) async {
        const viewport = Size(390, 844);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = CalendarController(
          focusedDay: DateTime(2026, 2, 10),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CalendarInteractiveView(
                controller: controller,
                onDaySelected: (_) {},
                contentBuilder: (_, scroll, physics) => ListView.builder(
                  controller: scroll,
                  physics: physics,
                  itemCount: 40,
                  itemExtent: 50,
                  itemBuilder: (_, index) => Text('Item $index'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final calendar = find.byType(CalendarView);
        final list = find.byType(ListView);
        double height() => tester.getSize(calendar).height;
        final monthHeight = height();
        Future<void> fling(double dy) async {
          await tester.fling(
            fromList && height() < viewport.height ? list : calendar,
            Offset(0, dy),
            1100,
          );
          await tester.pumpAndSettle();
        }

        await fling(-64);
        expect(controller.displayMode, CalendarDisplayMode.week);
        await fling(64);
        expect(height(), closeTo(monthHeight, 0.1));
        await fling(64);
        expect(height(), closeTo(viewport.height, 0.1));
        await fling(-64);
        expect(height(), closeTo(monthHeight, 0.1));
        final surface = fromList ? list : calendar;
        await tester.timedDrag(
          surface,
          const Offset(0, -64),
          const Duration(milliseconds: 600),
        );
        await tester.pumpAndSettle();
        expect(height(), closeTo(monthHeight, 0.1));

        // Drag most of the way to the other mode, then flick back at release.
        Future<void> reverseFling(double travel) async {
          final gesture = await tester.startGesture(tester.getCenter(surface));
          await gesture.moveBy(Offset(0, 24 * travel.sign));
          await tester.pump();
          await gesture.moveBy(Offset(0, travel * 0.84 - 24 * travel.sign));
          await tester.pump();
          for (var i = 0; i < 6; i++) {
            await gesture.moveBy(
              Offset(0, -6 * travel.sign),
              timeStamp: Duration(milliseconds: 200 + 6 * i),
            );
            await tester.pump(const Duration(milliseconds: 6));
          }
          await gesture.up(timeStamp: const Duration(milliseconds: 232));
          await tester.pumpAndSettle();
        }

        controller.setDisplayMode(CalendarDisplayMode.week);
        await tester.pumpAndSettle();
        final weekHeight = height();
        final travel = monthHeight - weekHeight;
        await reverseFling(travel);
        expect(height(), closeTo(weekHeight, 0.1));
        await fling(64);
        await reverseFling(-travel);
        expect(height(), closeTo(monthHeight, 0.1));
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  for (final (fromList, duringSnap) in [
    (false, false),
    (true, false),
    (true, true),
  ]) {
    testWidgets(
      'one drag from ${fromList ? 'list' : 'calendar'}${duringSnap ? ' during snap' : ''} '
      'scrolls the list as soon as the calendar folds',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = CalendarController(focusedDay: DateTime(2026, 2, 10))
          ..setDisplayMode(CalendarDisplayMode.week);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CalendarInteractiveView(
                controller: controller,
                onDaySelected: (_) {},
                contentBuilder: (_, scroll, physics) => ListView.builder(
                  controller: scroll,
                  physics: physics,
                  itemExtent: 50,
                  itemCount: 40,
                  itemBuilder: (_, index) => Text('Item $index'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final calendar = find.byType(CalendarView);
        final list = find.byType(ListView);
        double height() => tester.getSize(calendar).height;
        double offset() => tester.widget<ListView>(list).controller!.offset;
        final weekHeight = height();
        controller.setDisplayMode(CalendarDisplayMode.month);
        await tester.pumpAndSettle();
        if (duringSnap) {
          // Catch the calendar during its snap to week and continue folding it.
          await tester.drag(list, Offset(0, -(height() - weekHeight) * 0.55));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(height(), greaterThan(weekHeight));
        }
        final gesture = await tester.startGesture(
          fromList ? tester.getCenter(list) : tester.getCenter(calendar),
        );
        var time = Duration.zero;
        Future<void> move(double dy) async {
          const frame = Duration(milliseconds: 16);
          time += frame;
          await gesture.moveBy(Offset(0, dy), timeStamp: time);
          await tester.pump(frame);
        }

        await move(-30);
        await move(-30);
        expect(offset(), 0);
        await move(-(height() - weekHeight + 25));
        expect(height(), closeTo(weekHeight, 0.1));
        expect(offset(), closeTo(25, 0.1));
        await move(-50);
        expect(offset(), closeTo(75, 0.1));
        await move(40);
        expect(offset(), closeTo(35, 0.1));
        expect(height(), closeTo(weekHeight, 0.1));
        await move(55);
        expect(offset(), closeTo(0, 0.1));
        expect(height(), closeTo(weekHeight + 20, 0.1));

        for (var i = 0; i < 6; i++) {
          await move(-16);
        }
        final atRelease = offset();
        expect(atRelease, closeTo(76, 0.1));
        await gesture.up(timeStamp: time);
        await tester.pumpAndSettle();
        expect(controller.displayMode, CalendarDisplayMode.week);
        expect(offset(), greaterThan(atRelease));
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      },
    );
  }

  for (final fromList in [false, true]) {
    for (final settleFullScreen in [false, true]) {
      testWidgets(
        'one drag from ${fromList ? 'list top' : 'calendar'} crosses month '
        'height and settles at ${settleFullScreen ? 'fullscreen' : 'month'}',
        (tester) async {
          const viewport = Size(390, 844);
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final controller = CalendarController(
            focusedDay: DateTime(2026, 2, 10),
          );
          final interaction = CalendarInteractiveController();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CalendarInteractiveView(
                  controller: controller,
                  interactionController: interaction,
                  onDaySelected: (_) {},
                  contentBuilder: (_, scroll, physics) => ListView.builder(
                    controller: scroll,
                    physics: physics,
                    itemExtent: 50,
                    itemCount: 30,
                    itemBuilder: (_, index) => Text('Item $index'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final calendar = find.byType(CalendarView);
          double calendarHeight() => tester.getSize(calendar).height;
          final monthHeight = calendarHeight();
          controller.setDisplayMode(CalendarDisplayMode.week);
          await tester.pumpAndSettle();
          final weekHeight = calendarHeight();
          final start = fromList
              ? tester.getTopLeft(find.byType(ListView)) + const Offset(30, 15)
              : tester.getCenter(calendar);
          final gesture = await tester.startGesture(start);
          Future<void> move(double dy) async {
            await gesture.moveBy(Offset(0, dy));
            await tester.pump();
          }

          await move(24);
          await move(30);
          final previewHeight = calendarHeight();
          expect(previewHeight, inExclusiveRange(weekHeight, monthHeight));
          await move(monthHeight - previewHeight + 40);
          expect(calendarHeight(), closeTo(monthHeight + 40, 0.1));
          expect(controller.displayMode, CalendarDisplayMode.week);
          await move(-60);
          expect(calendarHeight(), closeTo(monthHeight - 20, 0.1));

          final stretch =
              (viewport.height - monthHeight) *
              (settleFullScreen ? 0.75 : 0.25);
          await move(20 + stretch);
          expect(calendarHeight(), closeTo(monthHeight + stretch, 0.1));
          if (!fromList && settleFullScreen) {
            await move(viewport.height - calendarHeight());
            expect(calendarHeight(), closeTo(viewport.height, 0.1));
          }
          await gesture.up();
          await tester.pumpAndSettle();
          expect(controller.displayMode, CalendarDisplayMode.month);
          expect(interaction.isFullScreenExpanded, settleFullScreen);
          expect(
            calendarHeight(),
            closeTo(settleFullScreen ? viewport.height : monthHeight, 0.1),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          interaction.dispose();
        },
      );
    }
  }

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

  testWidgets('vertical fullscreen reports the leading month once per change', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 340));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selected = DateTime(2026, 2, 8);
    final controller = CalendarController(
      focusedDay: selected,
      minDate: DateTime(2026, 1, 12),
      maxDate: DateTime(2026, 12, 31),
    );
    final interaction = CalendarInteractiveController(
      pageOrientation: CalendarPageOrientation.vertical,
    );
    final changes = <DateTime>[];
    final focusAtNotification = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarInteractiveView(
            controller: controller,
            interactionController: interaction,
            calendarHeight: 40,
            onDaySelected: (_) {},
            onFocusedDayChanged: (day) {
              changes.add(day);
              focusAtNotification.add(controller.focusedDay);
            },
            contentBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    interaction.toggleFullScreen();
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(CalendarMonthListView),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    Future<void> scrollTo(double pixels) async {
      position.jumpTo(pixels);
      await tester.pumpAndSettle();
    }

    // February has four 40-pixel rows and a 28-pixel label; March has five rows.
    await scrollTo(187);
    expect(changes, isEmpty);
    await scrollTo(188);
    await scrollTo(300);
    expect(changes, [DateTime(2026, 3)]);
    await scrollTo(416);
    await scrollTo(-10);
    await scrollTo(-20);
    await scrollTo(0);
    expect(changes, [
      DateTime(2026, 3),
      DateTime(2026, 4),
      DateTime(2026, 1, 12),
      DateTime(2026, 2),
    ]);
    expect(focusAtNotification, changes);
    expect(controller.selection.single, selected);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    interaction.dispose();
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
      expect(controller.selection.single, DateTime(2026, 2, 28));
    },
  );

  testWidgets(
    'vertical month paging clamps and restores the selected day of month',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = CalendarController(
        focusedDay: DateTime(2026, 1, 31),
        minDate: DateTime(2026, 1, 1),
        maxDate: DateTime(2026, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      controller.selectDay(DateTime(2026, 1, 31));
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

      final pager = find.byKey(const ValueKey('calendar-vertical-pager'));
      await tester.fling(pager, const Offset(0, -500), 900);
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 2, 28));
      expect(controller.selection.single, DateTime(2026, 2, 28));

      await tester.drag(pager, Offset(0, -tester.getSize(pager).height * .8));
      await tester.pumpAndSettle();

      expect(controller.focusedDay, DateTime(2026, 3, 31));
      expect(controller.selection.single, DateTime(2026, 3, 31));
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
