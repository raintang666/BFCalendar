// Run on a device: flutter run --profile -d <device>
//   -t benchmark/calendar_interaction_benchmark.dart
// Results are printed as CALENDAR_BENCHMARK JSON lines. Compare the same device,
// refresh rate and build mode; widget-test timings do not measure device FPS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

final _calendarKey = GlobalKey();
final _clock = Stopwatch()..start();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final start = DateTime(2026, 2, 10);
  const onlyStyle = String.fromEnvironment('CALENDAR_BENCHMARK_STYLE');
  for (final style in ['default', 'home', 'one-widget']) {
    if (onlyStyle.isNotEmpty && style != onlyStyle) continue;
    final controller = CalendarController(
      focusedDay: start,
      minDate: DateTime(2025, 1, 1),
      maxDate: DateTime(2027, 12, 31),
    )..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
    final interaction = CalendarInteractiveController();
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
            contentBuilder: (_, scrollController, physics) => ListView.builder(
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
    for (final motion in ['horizontal', 'collapse', 'stretch', 'week']) {
      final frames = <FrameTiming>[];
      void record(List<FrameTiming> timings) => frames.addAll(timings);
      for (var repeat = 0; repeat < 3; repeat++) {
        controller.jumpToDay(start);
        if (motion == 'week') {
          interaction.collapse();
        } else {
          interaction.expand();
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
        SchedulerBinding.instance.addTimingsCallback(record);
        final feed =
            _calendarKey.currentContext!.findRenderObject()! as RenderBox;
        final feedTop = feed.localToGlobal(Offset.zero).dy;
        final dragStartY = switch (motion) {
          'week' => feedTop - 24,
          'collapse' => feedTop + 24,
          _ => feedTop / 2,
        };
        await _drag(Offset(feed.size.width / 2, dragStartY), switch (motion) {
          'horizontal' || 'week' => const Offset(-300, 0),
          'collapse' => const Offset(0, -240),
          _ => const Offset(0, 400),
        });
        await Future<void>.delayed(const Duration(milliseconds: 700));
        SchedulerBinding.instance.removeTimingsCallback(record);
        final reachedTarget = switch (motion) {
          'horizontal' => controller.focusedDay.month == start.month + 1,
          'week' =>
            controller.displayMode == CalendarDisplayMode.week &&
                controller.focusedDay.difference(start).inDays == 7,
          'collapse' => controller.displayMode == CalendarDisplayMode.week,
          _ => interaction.isFullScreenExpanded,
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
        'CALENDAR_BENCHMARK ${jsonEncode({'style': style, 'motion': motion, 'frames': frames.length, 'refreshHz': refreshRate, 'buildP50us': percentile(builds, .5), 'buildP95us': percentile(builds, .95), 'rasterP95us': percentile(rasters, .95), 'overBudget': frames.where((f) => f.buildDuration.inMicroseconds > budget || f.rasterDuration.inMicroseconds > budget).length})}',
      );
    }
    runApp(const SizedBox.shrink());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    controller.dispose();
    interaction.dispose();
  }
  exit(0);
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
