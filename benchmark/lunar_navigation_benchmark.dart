// Run in a fresh process with flutter run --profile -d <device>
//   -t benchmark/lunar_navigation_benchmark.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/lunar_service.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:flutter/foundation.dart' show kProfileMode;
import 'package:flutter/material.dart';

Future<void> main() async {
  final dartEntryUs = DateTime.now().microsecondsSinceEpoch;
  final cold = Stopwatch()..start();
  if (!kProfileMode) throw StateError('Run this benchmark in profile mode.');
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (LunarService.cacheSize != 0) throw StateError('Expected a cold cache.');

  final firstTiming = Completer<FrameTiming>();
  late int timingReceivedUs;
  void onTimings(List<FrameTiming> frames) {
    if (!firstTiming.isCompleted && frames.isNotEmpty) {
      timingReceivedUs = DateTime.now().microsecondsSinceEpoch;
      firstTiming.complete(frames.first);
    }
  }

  binding.addTimingsCallback(onTimings);
  final controller = CalendarController(focusedDay: DateTime(2026, 7, 15))
    ..setMonthViewShowMode(MonthViewShowMode.onlyCurrentMonth);
  runApp(
    MaterialApp(
      home: Scaffold(
        body: CalendarView(
          controller: controller,
          componentBuilder: const CustomCalendarComponentBuilder(),
          pageOrientation: CalendarPageOrientation.horizontal,
          onDaySelected: (_) {},
        ),
      ),
    ),
  );
  await binding.waitUntilFirstFrameRasterized;
  cold.stop();
  final coldCache = LunarService.cacheSize;
  final first = await firstTiming.future;
  final rasterFinishUs = first.timestampInMicroseconds(
    FramePhase.rasterFinishWallTime,
  );
  binding.removeTimingsCallback(onTimings);

  void verifyJuly(int year) {
    final target = DateTime(year, 7, 15);
    if (controller.focusedDay != target || !LunarService.isDateCached(target)) {
      throw StateError('July $year did not finish building.');
    }
  }

  verifyJuly(2026);
  final burst = Stopwatch()..start();
  for (var year = 2027; year <= 2038; year++) {
    controller.jumpToDay(DateTime(year, 7, 15));
  }
  await binding.endOfFrame;
  burst.stop();
  verifyJuly(2038);
  final burstCache = LunarService.cacheSize;

  final perFrameUs = <int>[];
  for (var year = 2039; year <= 2062; year++) {
    final timer = Stopwatch()..start();
    controller.jumpToDay(DateTime(year, 7, 15));
    await binding.endOfFrame;
    perFrameUs.add(timer.elapsedMicroseconds);
    verifyJuly(year);
  }
  final result = {
    'dartEntryToFirstRasterFinishUs': rasterFinishUs - dartEntryUs,
    'firstRasterFinishToTimingCallbackUs': timingReceivedUs - rasterFinishUs,
    'coldFirstRasterNotificationUs': cold.elapsedMicroseconds,
    'firstBuildUs': first.buildDuration.inMicroseconds,
    'firstRasterUs': first.rasterDuration.inMicroseconds,
    'firstFrameSpanUs': first.totalSpan.inMicroseconds,
    'coldCache': coldCache,
    'burstToEndOfFrameUs': burst.elapsedMicroseconds,
    'burstCache': burstCache,
    'yearlyJumpToEndOfFrameUs': perFrameUs,
    'finalCache': LunarService.cacheSize,
    'disabled42LookupBatchUs': _measureDisabledLookups(),
  };
  // ignore: avoid_print
  print('CALENDAR_DATA_PROFILE ${jsonEncode(result)}');
}

// 10,000 dates, with 21 hits distributed across insertion order and 21 misses.
// Each timed batch scans the same 42-date grid ten times.
List<int> _measureDisabledLookups() {
  final grid = List.generate(42, (i) => DateTime(2026, 7, i + 1));
  final dates = {
    for (var i = 0; i < 10000; i++)
      if (i % 480 == 0 && i ~/ 480 < 21)
        grid[2 * (i ~/ 480)]
      else
        DateTime(1900, 1, i + 1),
  };
  final controller = CalendarController(disabledDates: dates)
    ..setInterceptBlocked(false);
  final samples = <int>[];
  for (var batch = 0; batch < 6; batch++) {
    var hits = 0;
    final timer = Stopwatch()..start();
    for (var repeat = 0; repeat < 10; repeat++) {
      for (final day in grid) {
        if (controller.isDisabled(day)) hits++;
      }
    }
    timer.stop();
    if (hits != 210) throw StateError('Unexpected disabled count: $hits');
    if (batch > 0) samples.add(timer.elapsedMicroseconds);
  }
  controller.dispose();
  return samples;
}
