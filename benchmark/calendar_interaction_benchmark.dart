// Run on a device: flutter run --profile -d <device>
//   -t benchmark/calendar_interaction_benchmark.dart
// Results are printed as CALENDAR_BENCHMARK JSON lines. Compare the same device,
// refresh rate and build mode; widget-test timings do not measure device FPS.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/app.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

final _calendarKey = GlobalKey();
final _clock = Stopwatch()..start();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const onlyStyle = String.fromEnvironment('CALENDAR_BENCHMARK_STYLE');
  const onlyMotion = String.fromEnvironment('CALENDAR_BENCHMARK_MOTION');
  const androidSwipe = bool.fromEnvironment('CALENDAR_BENCHMARK_ANDROID_SWIPE');
  const logFrames = bool.fromEnvironment('CALENDAR_BENCHMARK_LOG_FRAMES');
  const trials = int.fromEnvironment(
    'CALENDAR_BENCHMARK_TRIALS',
    defaultValue: 3,
  );
  final styles = onlyStyle == 'home-page'
      ? ['home-page']
      : ['default', 'home', 'one-widget'];
  for (final style in styles) {
    if (onlyStyle.isNotEmpty && style != onlyStyle) continue;
    final realHome = style == 'home-page';
    late final CalendarController controller;
    late final CalendarInteractiveController interaction;
    late final DateTime start;
    late final RenderBox homeGrid;
    late final RenderBox homeViewport;
    if (realHome) {
      final appKey = GlobalKey();
      runApp(CalendarViewFlutterApp(key: appKey));
      await Future<void>.delayed(const Duration(seconds: 2));
      final root = appKey.currentContext! as Element;
      final calendar = _descendant<CalendarMonthYearView>(root);
      final home = calendar.widget as CalendarMonthYearView;
      homeGrid = _descendant<CalendarView>(calendar).renderObject! as RenderBox;
      homeViewport =
          _descendant<CalendarInteractiveView>(calendar).renderObject!
              as RenderBox;
      controller = home.controller;
      interaction = home.interactionController!;
      start = controller.focusedDay;
    } else {
      start = DateTime(2026, 2, 10);
      controller = CalendarController(
        focusedDay: start,
        minDate: DateTime(2025, 1, 1),
        maxDate: DateTime(2027, 12, 31),
      )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
      interaction = CalendarInteractiveController();
      runApp(
        MaterialApp(
          home: Scaffold(
            body: CalendarMonthYearView(
              key: ValueKey(style),
              controller: controller,
              interactionController: interaction,
              componentBuilder: switch (style) {
                'home' => const CustomCalendarComponentBuilder(),
                'one-widget' => _OneWidgetBuilder(controller),
                _ => const DefaultCalendarComponentBuilder(),
              },
              onDaySelected: (_) {},
              contentBuilder: (_, scrollController, physics) =>
                  ListView.builder(
                    key: _calendarKey,
                    controller: scrollController,
                    physics: physics,
                    itemCount: 60,
                    itemExtent: 70,
                    itemBuilder: (_, index) =>
                        ListTile(title: Text('Calendar item $index')),
                  ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    for (final motion
        in realHome
            ? ['stretch']
            : ['horizontal', 'collapse', 'stretch', 'week']) {
      if (onlyMotion.isNotEmpty && motion != onlyMotion) continue;
      final frames = <FrameTiming>[];
      void record(List<FrameTiming> timings) => frames.addAll(timings);
      for (var repeat = 0; repeat < trials; repeat++) {
        controller.jumpToDay(start);
        if (motion == 'week') {
          interaction.collapse();
        } else {
          interaction.expand();
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final sampleStart = frames.length;
        SchedulerBinding.instance.addTimingsCallback(record);
        final Offset dragStart;
        if (realHome) {
          dragStart = homeGrid.localToGlobal(homeGrid.size.center(Offset.zero));
        } else {
          final feed =
              _calendarKey.currentContext!.findRenderObject()! as RenderBox;
          final feedTop = feed.localToGlobal(Offset.zero).dy;
          final y = switch (motion) {
            'week' => feedTop - 24,
            'collapse' => feedTop + 24,
            _ => feedTop / 2,
          };
          dragStart = Offset(feed.size.width / 2, y);
        }
        if (realHome && androidSwipe) {
          await _awaitAndroidSwipe(dragStart, repeat + 1);
        } else {
          await _drag(dragStart, switch (motion) {
            'horizontal' || 'week' => const Offset(-300, 0),
            'collapse' => const Offset(0, -240),
            _ => const Offset(0, 400),
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 700));
        SchedulerBinding.instance.removeTimingsCallback(record);
        final reachedTarget = switch (motion) {
          'horizontal' => controller.focusedDay.month == start.month + 1,
          'week' =>
            controller.displayMode == CalendarDisplayMode.week &&
                controller.focusedDay.difference(start).inDays == 7,
          'collapse' => controller.displayMode == CalendarDisplayMode.week,
          _ =>
            interaction.isFullScreenExpanded &&
                (!realHome ||
                    (homeViewport.size.height - homeGrid.size.height).abs() <
                        0.01),
        };
        if (!reachedTarget) {
          // ignore: avoid_print
          print(
            'CALENDAR_BENCHMARK: $style $motion missed its target on trial ${repeat + 1}. '
            'Mode ${controller.displayMode}, focus ${controller.focusedDay}, '
            'progress ${interaction.collapseProgress}, expanded ${interaction.isFullScreenExpanded}.',
          );
          await Future<void>.delayed(const Duration(milliseconds: 200));
          exit(1);
        }
        if (logFrames) {
          final sample = frames.skip(sampleStart);
          // ignore: avoid_print
          print(
            'CALENDAR_BENCHMARK_FRAMES ${jsonEncode({'style': style, 'motion': motion, 'trial': repeat + 1, 'uiUs': sample.map((frame) => frame.buildDuration.inMicroseconds).toList(), 'rasterUs': sample.map((frame) => frame.rasterDuration.inMicroseconds).toList()})}',
          );
        }
        if (interaction.isFullScreenExpanded) {
          interaction.toggleFullScreen();
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
      }
      if (frames.isEmpty) {
        stderr.writeln(
          'CALENDAR_BENCHMARK: no rendered frames. Unlock the '
          'device and keep the benchmark in the foreground, then rerun.',
        );
        exit(1);
      }
      final builds = frames.map((f) => f.buildDuration.inMicroseconds).toList()
        ..sort();
      final rasters =
          frames.map((f) => f.rasterDuration.inMicroseconds).toList()..sort();
      final refreshRate = WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .display
          .refreshRate;
      final budget = 1000000 / (refreshRate > 0 ? refreshRate : 60);
      int percentile(List<int> values, double p) =>
          values[(values.length * p).floor().clamp(0, values.length - 1)];
      // ignore: avoid_print
      print(
        'CALENDAR_BENCHMARK ${jsonEncode({'style': style, 'motion': motion, 'profile': kProfileMode, 'frames': frames.length, 'refreshHz': refreshRate, 'buildP50us': percentile(builds, .5), 'buildP95us': percentile(builds, .95), 'rasterP95us': percentile(rasters, .95), 'overBudget': frames.where((f) => f.buildDuration.inMicroseconds > budget || f.rasterDuration.inMicroseconds > budget).length})}',
      );
    }
    runApp(const SizedBox.shrink());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!realHome) {
      controller.dispose();
      interaction.dispose();
    }
  }
  exit(0);
}

Element _descendant<T extends Widget>(Element root) {
  Element? result;
  void visit(Element element) {
    if (result != null) return;
    if (element.widget is T) {
      result = element;
    } else {
      element.visitChildElements(visit);
    }
  }

  visit(root);
  return result ?? (throw StateError('Missing $T on the demo home page'));
}

class _OneWidgetBuilder extends DefaultCalendarComponentBuilder {
  const _OneWidgetBuilder(this.controller);

  final CalendarController controller;

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    final day = super.buildDayCell(context, data);
    final useWidget = controller.displayMode == CalendarDisplayMode.week
        ? data.date.weekday == DateTime.wednesday
        : data.isCurrentMonth && data.date.day == 12;
    return useWidget ? SizedBox.expand(child: day) : day;
  }
}

Future<void> _awaitAndroidSwipe(Offset start, int trial) async {
  final done = Completer<void>();
  final router = GestureBinding.instance.pointerRouter;
  void onPointer(PointerEvent event) {
    if (event is PointerUpEvent && !done.isCompleted) done.complete();
  }

  final scale =
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final x = (start.dx * scale).round();
  final y = (start.dy * scale).round();
  final endY = ((start.dy + 400) * scale).round();
  router.addGlobalRoute(onPointer);
  try {
    // A host can forward these screen coordinates directly to adb shell input.
    // ignore: avoid_print
    print('CALENDAR_BENCHMARK_SWIPE $trial $x $y $endY');
    await done.future.timeout(const Duration(seconds: 30));
  } finally {
    router.removeGlobalRoute(onPointer);
  }
}

Future<void> _drag(Offset start, Offset distance) async {
  final binding = GestureBinding.instance;
  binding.handlePointerEvent(
    PointerDownEvent(pointer: 1, position: start, timeStamp: _clock.elapsed),
  );
  var previous = start;
  for (var step = 1; step <= 24; step++) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final position = start + distance * (step / 24);
    binding.handlePointerEvent(
      PointerMoveEvent(
        pointer: 1,
        position: position,
        delta: position - previous,
        timeStamp: _clock.elapsed,
      ),
    );
    previous = position;
  }
  binding.handlePointerEvent(
    PointerUpEvent(pointer: 1, position: previous, timeStamp: _clock.elapsed),
  );
}
