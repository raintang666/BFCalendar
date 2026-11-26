import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/calendar_retained_day_painter.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final hasCustomCell in [false, true]) {
    for (final motion in ['horizontal', 'collapse', 'expand', 'stretch']) {
      testWidgets(
        '$motion ${hasCustomCell ? 'mixed' : 'Canvas'} frames reuse calendar chrome and feed',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final controller = CalendarController(
            focusedDay: DateTime(2026, 2, 10),
            minDate: DateTime(2026, 1, 1),
            maxDate: DateTime(2026, 12, 31),
          )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
          if (motion == 'expand') {
            controller.setDisplayMode(CalendarDisplayMode.week);
          }
          final interactionController = CalendarInteractiveController();
          final builder = _CountingBuilder(hasCustomCell: hasCustomCell);
          var feedBuilds = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CalendarMonthYearView(
                  controller: controller,
                  interactionController: interactionController,
                  componentBuilder: builder,
                  onDaySelected: (_) {},
                  contentBuilder: (_, scrollController, physics) {
                    feedBuilds++;
                    return ListView.builder(
                      key: const ValueKey('feed'),
                      controller: scrollController,
                      physics: physics,
                      itemCount: 30,
                      itemExtent: 60,
                      itemBuilder: (_, index) => Text('Item $index'),
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(PageView)),
          );
          final delta = switch (motion) {
            'horizontal' => const Offset(-10, 0),
            'collapse' => const Offset(0, -10),
            _ => const Offset(0, 10),
          };
          await gesture.moveBy(delta * 3);
          await tester.pump();
          if (motion == 'expand') {
            // The first move wins the gesture arena; the next move exposes the
            // month grid and changes feed physics before measuring reuse.
            await gesture.moveBy(delta);
            await tester.pump();
          }
          await tester.pump();
          final initialHeaders = builder.headers;
          final initialWeeks = builder.weeks;
          final initialCells = builder.cells;
          final initialPaints = builder.paints;
          final initialFeeds = feedBuilds;
          var dayTextBuilds = 0;
          final previousRebuildCallback = debugOnRebuildDirtyWidget;
          debugOnRebuildDirtyWidget = (element, builtOnce) {
            previousRebuildCallback?.call(element, builtOnce);
            final child = element.widget;
            if (child is Text &&
                RegExp(r'^\d{1,2}$').hasMatch(child.data ?? '')) {
              dayTextBuilds++;
            }
          };
          addTearDown(
            () => debugOnRebuildDirtyWidget = previousRebuildCallback,
          );
          final timer = Stopwatch()..start();
          for (var frame = 0; frame < 8; frame++) {
            await gesture.moveBy(delta);
            await tester.pump(const Duration(milliseconds: 16));
            expect(
              tester.getTopLeft(find.byKey(const ValueKey('feed'))).dy,
              closeTo(tester.getBottomLeft(find.byType(CalendarView)).dy, 0.01),
              reason: 'Feed must follow calendar in the same frame',
            );
          }
          timer.stop();
          debugOnRebuildDirtyWidget = previousRebuildCallback;
          final headers = builder.headers - initialHeaders;
          final weeks = builder.weeks - initialWeeks;
          final cells = builder.cells - initialCells;
          final paints = builder.paints - initialPaints;
          final feeds = feedBuilds - initialFeeds;
          debugPrint(
            'PERF $motion: 8 frames, header=$headers week=$weeks '
            'cells=$cells text=$dayTextBuilds paint=$paints feed=$feeds elapsed=${timer.elapsedMicroseconds}us',
          );
          await gesture.up();
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
          interactionController.dispose();
          expect(
            headers,
            0,
            reason: 'Static month header rebuilt during $motion',
          );
          expect(weeks, 0, reason: 'Static week bar rebuilt during $motion');
          expect(
            dayTextBuilds,
            0,
            reason: 'Date text rebuilt while only geometry changed',
          );
          if (motion == 'collapse' || motion == 'expand') {
            expect(
              paints,
              0,
              reason: 'Unchanged date grid repainted during $motion',
            );
          } else if (motion == 'stretch') {
            expect(
              paints,
              hasCustomCell ? 8 : 0,
              reason:
                  'Only the custom Widget should repaint as its height changes',
            );
          } else if (motion == 'horizontal') {
            expect(
              paints,
              lessThanOrEqualTo(42),
              reason: 'Only a newly exposed month should need painting',
            );
          }
          expect(
            cells,
            0,
            reason: 'Unchanged day cells rebuilt during $motion',
          );
          expect(
            feeds,
            0,
            reason: 'Unchanged contentBuilder rerun during $motion',
          );
        },
      );
    }
  }

  testWidgets(
    'stretched home artwork follows width, direction and calendar updates',
    (tester) async {
      final day = DateTime(2026, 2, 10);
      final controller = CalendarController(
        focusedDay: day,
        minDate: DateTime(2026, 2),
        maxDate: DateTime(2026, 2, 28),
      );
      final builder = _CountingBuilder(
        hasCustomCell: false,
        style: const CustomCalendarComponentBuilder(),
      );

      Future<void> show(
        double width,
        double height,
        TextDirection direction,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Directionality(
                textDirection: direction,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: CalendarView(
                      controller: controller,
                      componentBuilder: builder,
                      monthBodyHeightOverride: height,
                      pageOrientation: CalendarPageOrientation.horizontal,
                      onDaySelected: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(390, 320, TextDirection.ltr);
      final initial = builder.paints;
      expect(initial, greaterThan(0));
      await show(390, 340, TextDirection.ltr);
      expect(builder.paints, initial);
      await show(370, 340, TextDirection.ltr);
      final resized = builder.paints;
      expect(resized, greaterThan(initial));
      await show(370, 340, TextDirection.rtl);
      final mirrored = builder.paints;
      expect(mirrored, greaterThan(resized));
      controller.setMarkers({
        day: [const CalendarMarker(label: 'new', color: Colors.orange)],
      });
      await tester.pumpAndSettle();
      expect(builder.paints, greaterThan(mirrored));
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'home stretch reuses device-resolution pixels and releases them on memory pressure',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(720, 1640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = CalendarController(
        focusedDay: DateTime(2026, 2, 10),
        minDate: DateTime(2026, 2),
        maxDate: DateTime(2026, 2, 28),
      );
      final interaction = CalendarInteractiveController();
      final created = <ui.Image>[];
      final previous = ui.Image.onCreate;
      ui.Image.onCreate = (image) {
        previous?.call(image);
        if (image.width >= 600) {
          created.add(image);
        }
      };
      addTearDown(() => ui.Image.onCreate = previous);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarMonthYearView(
              controller: controller,
              interactionController: interaction,
              componentBuilder: const CustomCalendarComponentBuilder(),
              onDaySelected: (_) {},
              contentBuilder: (_, scroll, physics) =>
                  ListView(controller: scroll, physics: physics),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gridWidth = tester
          .getSize(find.byKey(const ValueKey('calendar-canvas-grid')).first)
          .width;
      expect(
        created.length,
        1,
        reason: 'The first visible month is prepared before pointer input',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      expect(created.length, 1);
      expect(created.single.width, gridWidth * 2);
      expect(created.single.debugDisposed, isFalse);

      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1080, 2460);
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(created.length, 2);
      expect(created.first.debugDisposed, isTrue);
      expect(created.last.width, gridWidth * 3);
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(created.length, 2);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(interaction.isFullScreenExpanded, isTrue);
      expect(created.last.debugDisposed, isFalse);
      tester.binding.handleMemoryPressure();
      expect(created.last.debugDisposed, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      interaction.dispose();
    },
  );

  testWidgets('dragging beyond full height avoids rebuilding the same grid', (
    tester,
  ) async {
    final controller = CalendarController(focusedDay: DateTime(2026, 2, 10));
    final interaction = CalendarInteractiveController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarMonthYearView(
            controller: controller,
            interactionController: interaction,
            onDaySelected: (_) {},
            contentBuilder: (_, scroll, physics) =>
                ListView(controller: scroll, physics: physics),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 350));
    await tester.pumpAndSettle();
    final finder = find.byType(CalendarView);
    final atLimit = tester.widget<CalendarView>(finder);
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(tester.widget<CalendarView>(finder), same(atLimit));
    await gesture.moveBy(const Offset(0, -400));
    await tester.pump();
    expect(
      tester.widget<CalendarView>(finder).monthBodyHeightOverride,
      lessThan(atLimit.monthBodyHeightOverride!),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    interaction.dispose();
  });

  testWidgets('paging reuses its controller through both date boundaries', (
    tester,
  ) async {
    final controller = CalendarController(
      focusedDay: DateTime(2026, 2, 10),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 3, 31),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            controller: controller,
            onDaySelected: (_) {},
            pageOrientation: CalendarPageOrientation.horizontal,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pager = tester.widget<PageView>(find.byType(PageView)).controller;
    for (final month in [3, 2, 1, 2, 3]) {
      await tester.fling(
        find.byType(PageView),
        Offset(month > controller.focusedDay.month ? -600 : 600, 0),
        900,
      );
      await tester.pumpAndSettle();
      expect(controller.focusedDay.month, month);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller,
        same(pager),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('cached builders update for inherited theme and controller data', (
    tester,
  ) async {
    final brightness = ValueNotifier(Brightness.light);
    final controller = CalendarController(
      focusedDay: DateTime(2026, 2, 10),
      minDate: DateTime(2026, 2, 1),
      maxDate: DateTime(2026, 2, 28),
    )..setInterceptBlocked(false);
    final child = Scaffold(
      body: CalendarInteractiveView(
        controller: controller,
        onDaySelected: (_) {},
        componentBuilder: const _ThemeAwareBuilder(),
        contentBuilder: (context, _, physics) {
          expect(
            context.findAncestorWidgetOfExactType<CalendarInteractiveView>(),
            isNotNull,
          );
          return Text(
            'feed-${Theme.of(context).brightness.name}-${controller.focusedDay.day}'
            '-${physics is AlwaysScrollableScrollPhysics}',
          );
        },
      ),
    );
    await tester.pumpWidget(
      ValueListenableBuilder<Brightness>(
        valueListenable: brightness,
        child: child,
        builder: (_, value, child) => MaterialApp(
          theme: ThemeData(brightness: value),
          themeAnimationDuration: Duration.zero,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('header-light'), findsOneWidget);
    expect(find.text('week-light'), findsOneWidget);
    expect(find.text('feed-light-10-false'), findsOneWidget);
    brightness.value = Brightness.dark;
    await tester.pumpAndSettle();
    expect(find.text('header-dark'), findsOneWidget);
    expect(find.text('week-dark'), findsOneWidget);
    expect(find.text('feed-dark-10-false'), findsOneWidget);
    controller.selectDay(DateTime(2026, 2, 11));
    controller.setMarkers({
      DateTime(2026, 2, 11): [
        const CalendarMarker(label: 'event', color: Colors.red),
      ],
    });
    await tester.pumpAndSettle();
    expect(find.text('day-11-dark-true-event'), findsOneWidget);
    expect(find.text('feed-dark-11-false'), findsOneWidget);
    controller.setDisplayMode(CalendarDisplayMode.week);
    await tester.pumpAndSettle();
    expect(find.text('feed-dark-11-true'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    brightness.dispose();
    controller.dispose();
  });

  testWidgets('week paging works after switching to vertical month paging', (
    tester,
  ) async {
    final controller = CalendarController(focusedDay: DateTime(2026, 2, 10))
      ..setDisplayMode(CalendarDisplayMode.week);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            controller: controller,
            onDaySelected: (_) {},
            pageOrientation: CalendarPageOrientation.vertical,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final day in [17, 24]) {
      await tester.fling(find.byType(PageView), const Offset(-600, 0), 900);
      await tester.pumpAndSettle();
      expect(controller.focusedDay, DateTime(2026, 2, day));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

class _ThemeAwareBuilder extends DefaultCalendarComponentBuilder {
  const _ThemeAwareBuilder();

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    expect(context.findAncestorWidgetOfExactType<CalendarView>(), isNotNull);
    return SizedBox(
      height: height,
      child: Text('header-${Theme.of(context).brightness.name}'),
    );
  }

  @override
  Widget buildWeekBar(BuildContext context, CalendarWeekBarData data) {
    expect(context.findAncestorWidgetOfExactType<CalendarView>(), isNotNull);
    return SizedBox(
      height: data.height,
      child: Text('week-${Theme.of(context).brightness.name}'),
    );
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) => Text(
    'day-${data.date.day}-${Theme.of(context).brightness.name}'
    '-${data.isSelected}-${data.primaryMarker?.label ?? ''}',
    style: const TextStyle(fontSize: 6),
  );
}

class _CountingBuilder extends DefaultCalendarComponentBuilder {
  _CountingBuilder({
    required this.hasCustomCell,
    this.style = const DefaultCalendarComponentBuilder(),
  });
  final CalendarComponentBuilder style;
  final bool hasCustomCell;
  int headers = 0;
  int weeks = 0;
  int cells = 0;
  int paints = 0;

  @override
  Widget buildMonthHeader(BuildContext context, DateTime month, double height) {
    headers++;
    return super.buildMonthHeader(context, month, height);
  }

  @override
  Widget buildWeekBar(BuildContext context, CalendarWeekBarData data) {
    weeks++;
    return super.buildWeekBar(context, data);
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    cells++;
    final child = style.buildDayCell(context, data) as CustomPaint;
    return CustomPaint(
      painter: _CountingPainter(
        onPaint: () => paints++,
        delegate: child.painter! as CalendarRetainedDayPainter,
      ),
      child: hasCustomCell && data.date.day == 10
          ? const Center(child: Text('10'))
          : null,
    );
  }
}

class _CountingPainter extends CalendarRetainedDayPainter {
  _CountingPainter({required this.onPaint, required this.delegate});
  final VoidCallback onPaint;
  final CalendarRetainedDayPainter delegate;

  @override
  double contentHeight(double width) => delegate.contentHeight(width);

  @override
  Alignment get contentAlignment => delegate.contentAlignment;

  @override
  double get footerHeight => delegate.footerHeight;

  @override
  void paintFooter(Canvas canvas, Size size) {
    onPaint();
    delegate.paintFooter(canvas, size);
  }

  @override
  void paintContent(Canvas canvas, Size size) {
    onPaint();
    delegate.paintContent(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _CountingPainter oldDelegate) => true;
}
