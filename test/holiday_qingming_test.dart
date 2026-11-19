import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/date_utils_ext.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_components.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_data.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_page.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_qingming.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'holiday_shortcut_test_support.dart';

Widget _demo({bool reduced = true, double textScale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: const HolidayCalendarPage(),
);
CalendarView _calendar(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('holiday-calendar')));
Future<int> _motionPixels(WidgetTester tester) async {
  final layer = find
      .descendant(
        of: find.byType(HolidayQingmingArtwork),
        matching: find.byType(RepaintBoundary),
      )
      .last;
  final boundary = tester.renderObject<RenderRepaintBoundary>(layer);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final fingerprint = Object.hashAll(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    image.dispose();
    return fingerprint;
  }))!;
}

void main() {
  test(
    'Qingming follows the yearly solar term and is reachable from Christmas',
    () {
      for (final (year, day) in [
        (2024, 4),
        (2025, 4),
        (2026, 5),
        (2027, 5),
        (2028, 4),
      ]) {
        final event = HolidayCalendarData.eventOn(DateTime(year, 4, day));
        expect(event?.scene, HolidayScene.qingming);
        expect(
          HolidayCalendarData.eventsForYear(
            year,
          ).where((e) => e.scene == HolidayScene.qingming),
          hasLength(1),
        );
      }
      expect(HolidayScene.qingming.stillSeconds, 12);
      expect(
        HolidayCalendarData.nearbyEvents(
          DateTime(2026, 12),
        ).firstWhere((event) => event.scene == HolidayScene.qingming).date,
        DateTime(2027, 4, 5),
      );
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(812, 375),
  ]) {
    testWidgets(
      'Qingming shortcut and still artwork at $size with large text',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_demo(textScale: 2));
        await tester.pumpAndSettle();
        await selectHolidayShortcut(
          tester,
          HolidayScene.qingming,
          DateTime(2027, 4, 5),
        );
        final calendar = _calendar(tester);
        final frames =
            (calendar.componentBuilder! as HolidayCalendarComponentBuilder)
                .frames!;
        expect(calendar.controller.selection.single, DateTime(2027, 4, 5));
        expect(calendar.controller.focusedDay.month, 4);
        expect(find.byType(CalendarView), findsOneWidget);
        expect(find.byType(HolidayQingmingArtwork), findsOneWidget);
        expect(find.text('清明时节雨纷纷'), findsNothing);
        expect(frames.value.scene, HolidayScene.qingming);
        expect(frames.value.seconds, 12);
        final still = await _motionPixels(tester);
        await tester.pump(const Duration(seconds: 40));
        expect(await _motionPixels(tester), still);
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'Qingming animates past clock wraps, pauses, and releases cached artwork',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo(reduced: false));
      await tester.pump();
      final calendar = _calendar(tester), date = DateTime(2027, 4, 5);
      calendar.controller.selectDay(date);
      calendar.onDaySelected(date);
      await tester.pump();
      await tester.pump();
      final frames =
          (calendar.componentBuilder! as HolidayCalendarComponentBuilder)
              .frames!;
      final initial = await _motionPixels(tester);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(await _motionPixels(tester), isNot(initial));
      for (var i = 0; i < 23; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(frames.value.seconds, greaterThanOrEqualTo(35));
      expect(calendar.controller.selection.single, date);
      await tester.tap(find.byTooltip('暂停动效'));
      await tester.pumpAndSettle();
      final paused = await _motionPixels(tester),
          seconds = frames.value.seconds;
      await tester.pump(const Duration(seconds: 40));
      expect(frames.value.seconds, seconds);
      expect(await _motionPixels(tester), paused);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(find.byTooltip('继续动效'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(frames.value.seconds, greaterThan(seconds));
      await tester.tap(find.byTooltip('暂停动效'));
      await tester.pumpAndSettle();
      // Touch a normal day on the actual SDK grid, then re-enter Qingming.
      final dates = CalendarDateUtils.visibleMonthDays(
        calendar.controller.focusedDay,
        firstWeekday: DateTime.monday,
        monthViewShowMode: MonthViewShowMode.fitMonth,
      );
      final index = dates.indexOf(DateTime(2027, 4, 6));
      final box = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('holiday-calendar')),
      );
      await tester.tapAt(
        box.localToGlobal(
          Offset(
            (index % 7 + 0.5) * box.size.width / 7,
            calendar.weekBarHeight +
                (index ~/ 7 + 0.5) * calendar.calendarHeight,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HolidayQingmingArtwork), findsNothing);
      expect(calendar.controller.selection.single, DateTime(2027, 4, 6));
      calendar.controller.selectDay(date);
      calendar.onDaySelected(date);
      await tester.pumpAndSettle();
      expect(find.byType(HolidayQingmingArtwork), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
