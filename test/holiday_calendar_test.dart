import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/app.dart';
import 'package:calendarview_flutter/src/calendar/date_utils_ext.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_components.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_data.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_page.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_demo_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'holiday_shortcut_test_support.dart';

// 1 - (1 - 65/500)^5 is approximately one half.
const _halfwayThroughSlide = Duration(milliseconds: 65);
const _slideSettled = Duration(milliseconds: 520);

Widget _demo({
  bool reducedMotion = true,
  double textScale = 1,
  TextDirection textDirection = TextDirection.ltr,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: Directionality(textDirection: textDirection, child: child!),
  ),
  home: const HolidayCalendarPage(),
);

CalendarView _calendar(WidgetTester tester) =>
    tester.widget<CalendarView>(find.byKey(const ValueKey('holiday-calendar')));

Future<void> _tapDay(
  WidgetTester tester,
  DateTime day, {
  bool settle = true,
}) async {
  final calendar = _calendar(tester);
  final days = CalendarDateUtils.visibleMonthDays(
    calendar.controller.focusedDay,
    firstWeekday: DateTime.monday,
    monthViewShowMode: MonthViewShowMode.fitMonth,
  );
  final index = days.indexOf(day);
  expect(index, greaterThanOrEqualTo(0));
  final calendarFinder = find.byKey(const ValueKey('holiday-calendar'));
  final box = tester.renderObject<RenderBox>(calendarFinder);
  final column = _visualColumn(tester, calendarFinder, index);
  await tester.tapAt(
    box.localToGlobal(
      Offset(
        (column + 0.5) * box.size.width / 7,
        calendar.weekBarHeight + (index ~/ 7 + 0.5) * calendar.calendarHeight,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

int _visualColumn(WidgetTester tester, Finder finder, int index) {
  final column = index % 7;
  return Directionality.of(tester.element(finder)) == TextDirection.rtl
      ? 6 - column
      : column;
}

/// Samples the area above a date number on the actual SDK grid.
Future<List<int>> _selectedDayTopPixels(
  WidgetTester tester, {
  DateTime? day,
  int offset = 0,
  int height = 11,
}) async {
  final view = _calendar(tester);
  final grid = find
      .descendant(
        of: find.byKey(const ValueKey('holiday-calendar')),
        matching: find.byKey(const ValueKey('calendar-canvas-grid')),
      )
      .hitTestable();
  expect(grid, findsOneWidget);
  RenderObject? render = tester.renderObject<RenderCustomPaint>(grid).parent;
  while (render != null && render is! RenderRepaintBoundary) {
    render = render.parent;
  }
  final boundary = render! as RenderRepaintBoundary;
  final dates = CalendarDateUtils.visibleMonthDays(
    view.controller.focusedDay,
    firstWeekday: DateTime.monday,
    monthViewShowMode: MonthViewShowMode.fitMonth,
  );
  expect(boundary.size.height, view.calendarHeight * (dates.length ~/ 7));
  final index = dates.indexOf(day ?? view.controller.selection.single!);
  expect(index, greaterThanOrEqualTo(0));
  final cellWidth = boundary.size.width / 7;
  final column = _visualColumn(tester, grid, index);
  final left = (column * cellWidth).ceil();
  final right = ((column + 1) * cellWidth).floor();
  final top = (index ~/ 7 * view.calendarHeight).round() + offset;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final pixels = <int>[];
    for (var y = top; y < top + height; y++) {
      for (var x = left; x < right; x++) {
        final offset = (y * image.width + x) * 4;
        for (var channel = 0; channel < 4; channel++) {
          pixels.add(bytes.getUint8(offset + channel));
        }
      }
    }
    image.dispose();
    return pixels;
  }))!;
}

Future<int> _snowCapWhitePixels(WidgetTester tester) async {
  final pixels = await _selectedDayTopPixels(tester);
  var white = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i] > 220 &&
        pixels[i + 1] > 220 &&
        pixels[i + 2] > 220 &&
        pixels[i + 3] > 0) {
      white++;
    }
  }
  return white;
}

Future<int> _highlightAlpha(
  WidgetTester tester,
  DateTime day, {
  int offset = 7,
}) async {
  final pixels = await _selectedDayTopPixels(
    tester,
    day: day,
    offset: offset,
    height: 1,
  );
  final centerPixel = pixels.length ~/ 8;
  return pixels[centerPixel * 4 + 3];
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('one date highlight slides across cells in ${direction.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _demo(reducedMotion: false, textDirection: direction),
      );
      final today = DateTime.now();
      final start =
          today.year == 2026 &&
              today.month == 12 &&
              const {8, 9, 10, 16}.contains(today.day)
          ? 15
          : 8;
      final first = DateTime(2026, 12, start);
      final middle = DateTime(2026, 12, start + 1);
      final target = DateTime(2026, 12, start + 2);
      final nextRow = DateTime(2026, 12, start + 8);

      await _tapDay(tester, first, settle: false);
      await tester.pump(_slideSettled);
      expect(await _highlightAlpha(tester, first), 255);
      expect(await _highlightAlpha(tester, target), 0);

      await _tapDay(tester, target, settle: false);
      expect(_calendar(tester).controller.selection.single, target);
      expect(await _highlightAlpha(tester, first), 255);
      expect(await _highlightAlpha(tester, target), 0);
      await tester.pump(_halfwayThroughSlide);
      expect(await _highlightAlpha(tester, middle), 255);
      expect(await _highlightAlpha(tester, first), lessThan(5));
      expect(await _highlightAlpha(tester, target), lessThan(5));

      await _tapDay(tester, nextRow, settle: false);
      expect(_calendar(tester).controller.selection.single, nextRow);
      expect(await _highlightAlpha(tester, middle), 255);
      expect(await _highlightAlpha(tester, nextRow), lessThan(5));
      await tester.pump(_halfwayThroughSlide);
      final rowHeight = _calendar(tester).calendarHeight.round();
      expect(await _highlightAlpha(tester, middle, offset: rowHeight - 1), 255);
      await tester.pump(_slideSettled);
      expect(await _highlightAlpha(tester, middle), 0);
      expect(await _highlightAlpha(tester, nextRow), 255);

      await _tapDay(tester, first, settle: false);
      await tester.pump(_halfwayThroughSlide);
      expect(await _highlightAlpha(tester, first), lessThan(255));
      await tester.pumpWidget(_demo(textDirection: direction));
      await tester.pumpAndSettle();
      expect(await _highlightAlpha(tester, first), 255);
      expect(await _highlightAlpha(tester, nextRow), 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }

  testWidgets('cross-month selection slides from the previous grid position', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_demo(reducedMotion: false));
    // December 25 and January 22 share the fourth row's Friday position.
    final target = DateTime(2027, 1, 1);
    final origin = DateTime(2027, 1, 22);
    await _tapDay(tester, target, settle: false);
    expect(_calendar(tester).controller.selection.single, target);
    expect(await _highlightAlpha(tester, origin), 255);
    expect(await _highlightAlpha(tester, target), 0);

    await tester.pump(_halfwayThroughSlide);
    final rowHeight = _calendar(tester).calendarHeight.round();
    expect(
      await _highlightAlpha(
        tester,
        DateTime(2027, 1, 8),
        offset: rowHeight - 1,
      ),
      255,
    );

    await tester.pump(_slideSettled);
    expect(await _highlightAlpha(tester, target), 255);
    expect(await _highlightAlpha(tester, origin), 0);
  });

  for (final example in [
    (scene: HolidayScene.fireworks, date: DateTime(2026, 12, 31)),
    (scene: HolidayScene.lanterns, date: DateTime(2027, 2, 6)),
    (scene: HolidayScene.yushui, date: DateTime(2027, 2, 19)),
    (scene: HolidayScene.jingzhe, date: DateTime(2027, 3, 6)),
    (scene: HolidayScene.chunfen, date: DateTime(2027, 3, 21)),
    (scene: HolidayScene.guyu, date: DateTime(2027, 4, 20)),
    (scene: HolidayScene.lixia, date: DateTime(2027, 5, 6)),
    (scene: HolidayScene.xiaoman, date: DateTime(2027, 5, 21)),
    (scene: HolidayScene.mangzhong, date: DateTime(2027, 6, 6)),
    (scene: HolidayScene.xiazhi, date: DateTime(2027, 6, 21)),
    (scene: HolidayScene.xiaoshu, date: DateTime(2027, 7, 7)),
    (scene: HolidayScene.dashu, date: DateTime(2027, 7, 23)),
    (scene: HolidayScene.liqiu, date: DateTime(2027, 8, 8)),
    (scene: HolidayScene.chushu, date: DateTime(2027, 8, 23)),
    (scene: HolidayScene.bailu, date: DateTime(2027, 9, 8)),
    (scene: HolidayScene.qiufen, date: DateTime(2027, 9, 23)),
    (scene: HolidayScene.hanlu, date: DateTime(2027, 10, 8)),
    (scene: HolidayScene.shuangjiang, date: DateTime(2027, 10, 23)),
    (scene: HolidayScene.lidong, date: DateTime(2027, 11, 7)),
    (scene: HolidayScene.xiaoxue, date: DateTime(2027, 11, 22)),
    (scene: HolidayScene.daxue, date: DateTime(2027, 12, 7)),
    (scene: HolidayScene.dongzhi, date: DateTime(2027, 12, 22)),
    (scene: HolidayScene.xiaohan, date: DateTime(2028, 1, 6)),
    (scene: HolidayScene.dahan, date: DateTime(2028, 1, 20)),
  ]) {
    testWidgets(
      '${example.scene.name} date badge animates, pauses, replays and respects reduced motion',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_demo(reducedMotion: false));
        await tester.pump();
        final view = _calendar(tester);
        view.controller.selectDay(example.date);
        view.onDaySelected(example.date);
        await tester.pump();
        await tester.pump();
        // Sample the settled badge at the same scene time as on replay.
        await tester.pump(_slideSettled);
        await _tapDay(tester, example.date, settle: false);
        Future<int> fingerprint() async => Object.hashAll(
          await _selectedDayTopPixels(
            tester,
            offset: example.scene == HolidayScene.yushui ? 48 : 0,
          ),
        );
        final initial = await fingerprint();
        await tester.pump(
          const {
                HolidayScene.daxue,
                HolidayScene.xiaohan,
                HolidayScene.dahan,
              }.contains(example.scene)
              ? const Duration(seconds: 3)
              : const Duration(milliseconds: 600),
        );
        final animated = await fingerprint();
        expect(
          animated,
          isNot(initial),
          reason:
              'The date decoration must appear and animate on the SDK grid.',
        );
        expect(view.controller.selection.single, example.date);

        await tester.tap(find.byTooltip('暂停动效'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        expect(await fingerprint(), animated);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.tap(find.byTooltip('继续动效'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1200));
        expect(await fingerprint(), isNot(animated));

        await _tapDay(tester, example.date, settle: false);
        expect(
          await fingerprint(),
          initial,
          reason:
              'Tapping the selected holiday must replay its date decoration.',
        );

        await tester.pumpWidget(_demo());
        await tester.pumpAndSettle();
        expect(_calendar(tester).controller.selection.single, example.date);
        final frozen = await fingerprint();
        expect(
          frozen,
          isNot(initial),
          reason: 'Reduced motion must retain a recognizable holiday badge.',
        );
        await tester.pump(const Duration(seconds: 20));
        expect(await fingerprint(), frozen);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('date fireworks disappear completely between repeating blooms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_demo(reducedMotion: false));
    await tester.pump();
    final view = _calendar(tester);
    final date = DateTime(2026, 12, 31);
    view.controller.selectDay(date);
    view.onDaySelected(date);
    await tester.pump();
    await tester.pump();
    await tester.pump(_slideSettled);
    await _tapDay(tester, date, settle: false);
    Future<List<int>> pixels() => _selectedDayTopPixels(
      tester,
      offset: -10,
      height: view.calendarHeight.ceil() + 10,
    );
    final empty = await pixels();
    await tester.pump(const Duration(milliseconds: 950));
    final bloom = await pixels();
    expect(bloom, isNot(orderedEquals(empty)));
    await tester.pump(const Duration(milliseconds: 1250));
    expect(
      await pixels(),
      orderedEquals(empty),
      reason: 'After the bloom, every spark and glow must be gone.',
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(await pixels(), orderedEquals(empty));

    await tester.tap(find.byTooltip('暂停动效'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(await pixels(), orderedEquals(empty));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.tap(find.byTooltip('继续动效'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    expect(
      await pixels(),
      isNot(orderedEquals(empty)),
      reason: 'The next launch must start after the empty interval.',
    );
    await tester.pump(const Duration(milliseconds: 1650));
    expect(await pixels(), orderedEquals(empty));

    // Cross the shared 12-second controller wrap while preserving the cycle.
    await tester.pump(const Duration(seconds: 7));
    expect(await pixels(), isNot(orderedEquals(empty)));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(await pixels(), orderedEquals(empty));
    await _tapDay(tester, date, settle: false);
    expect(await pixels(), orderedEquals(empty));
    await tester.pump(const Duration(milliseconds: 950));
    expect(await pixels(), orderedEquals(bloom));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Christmas snow cap builds up instead of appearing fully formed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_demo(reducedMotion: false));
    await tester.pump();
    final initial = await _snowCapWhitePixels(tester);
    expect(
      initial,
      0,
      reason:
          'A new Christmas selection must start without a completed snow cap.',
    );
    await tester.pump(const Duration(milliseconds: 900));
    final middle = await _snowCapWhitePixels(tester);
    expect(
      middle,
      greaterThan(initial),
      reason: 'Snow must accumulate as the scene clock advances.',
    );
    await tester.tap(find.byTooltip('暂停动效'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(await _snowCapWhitePixels(tester), middle);
    await tester.tap(find.byTooltip('继续动效'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    final complete = await _snowCapWhitePixels(tester);
    expect(complete, greaterThan(middle));

    await _tapDay(tester, DateTime(2026, 12, 8), settle: false);
    await _tapDay(tester, DateTime(2026, 12, 25), settle: false);
    expect(
      await _snowCapWhitePixels(tester),
      0,
      reason: 'Selecting Christmas again must restart accumulation.',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(await _snowCapWhitePixels(tester), complete);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reduced motion shows a completed Christmas snow cap without ticking',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo());
      await tester.pumpAndSettle();
      final complete = await _snowCapWhitePixels(tester);
      expect(complete, greaterThan(0));
      await tester.pump(const Duration(seconds: 20));
      expect(await _snowCapWhitePixels(tester), complete);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'holiday scenes follow selected dates and lunar new year changes by year',
    () {
      expect(
        HolidayCalendarData.eventOn(DateTime(2028, 12, 25))?.scene,
        HolidayScene.snow,
      );
      expect(
        HolidayCalendarData.eventOn(DateTime(2026, 12, 31))?.scene,
        HolidayScene.fireworks,
      );
      expect(
        HolidayCalendarData.eventOn(DateTime(2027, 2, 6))?.scene,
        HolidayScene.lanterns,
      );
      expect(HolidayCalendarData.eventOn(DateTime(2026, 2, 6)), isNull);
      expect(
        HolidayCalendarData.eventOn(DateTime(2026, 12, 7))?.scene,
        HolidayScene.daxue,
      );
      expect(HolidayCalendarData.eventOn(DateTime(2026, 12, 8)), isNull);
      for (final date in [DateTime(2026, 12, 22), DateTime(2028, 12, 21)]) {
        expect(
          HolidayCalendarData.eventsForYear(
            date.year,
          ).singleWhere((event) => event.scene == HolidayScene.dongzhi).date,
          date,
        );
        expect(HolidayCalendarData.eventOn(date)?.scene, HolidayScene.dongzhi);
      }
      expect(
        HolidayCalendarData.nearbyEvents(
          DateTime(2026, 12),
        ).map((event) => event.date),
        [
          DateTime(2026, 12, 7),
          DateTime(2026, 12, 22),
          DateTime(2026, 12, 25),
          DateTime(2026, 12, 31),
          DateTime(2027, 1, 1),
          DateTime(2027, 1, 5),
          DateTime(2027, 1, 20),
          DateTime(2027, 2, 4),
          DateTime(2027, 2, 5),
          DateTime(2027, 2, 6),
          DateTime(2027, 2, 19),
          DateTime(2027, 2, 20),
          DateTime(2027, 3, 6),
          DateTime(2027, 3, 21),
          DateTime(2027, 4, 5),
          DateTime(2027, 4, 20),
          DateTime(2027, 5, 1),
          DateTime(2027, 5, 6),
          DateTime(2027, 5, 21),
          DateTime(2027, 6, 6),
          DateTime(2027, 6, 9),
          DateTime(2027, 6, 21),
          DateTime(2027, 7, 7),
          DateTime(2027, 7, 23),
          DateTime(2027, 8, 8),
          DateTime(2027, 8, 23),
          DateTime(2027, 9, 8),
          DateTime(2027, 9, 15),
          DateTime(2027, 9, 23),
          DateTime(2027, 10, 1),
          DateTime(2027, 10, 8),
          DateTime(2027, 10, 23),
          DateTime(2027, 11, 7),
          DateTime(2027, 11, 22),
        ],
      );
    },
  );

  test('the added festivals follow the selected Gregorian and lunar year', () {
    for (final (year, eve, lantern, boat, moon) in [
      (2025, (1, 28), (2, 12), (5, 31), (10, 6)),
      (2026, (2, 16), (3, 3), (6, 19), (9, 25)),
      (2027, (2, 5), (2, 20), (6, 9), (9, 15)),
    ]) {
      final events = HolidayCalendarData.eventsForYear(year);
      for (final (scene, (month, day)) in [
        (HolidayScene.yuandan, (1, 1)),
        (HolidayScene.chuxi, eve),
        (HolidayScene.yuanxiao, lantern),
        (HolidayScene.laodong, (5, 1)),
        (HolidayScene.duanwu, boat),
        (HolidayScene.zhongqiu, moon),
        (HolidayScene.guoqing, (10, 1)),
      ]) {
        final date = DateTime(year, month, day);
        expect(events.singleWhere((event) => event.scene == scene).date, date);
        expect(HolidayCalendarData.eventOn(date, scene: scene)?.date, date);
      }
    }
  });

  testWidgets(
    'both festival shortcuts work when Mid-Autumn and National Day coincide',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo());
      await tester.pumpAndSettle();
      final view = _calendar(tester);
      final date = DateTime(2020, 10, 1);
      expect(view.controller.selectDay(date), isTrue);
      view.onDaySelected(date);
      await tester.pumpAndSettle();
      final frames =
          (view.componentBuilder! as HolidayCalendarComponentBuilder).frames!;
      for (final scene in [HolidayScene.guoqing, HolidayScene.zhongqiu]) {
        await selectHolidayShortcut(tester, scene, date);
        expect(view.controller.selection.single, date);
        expect(frames.value.scene, scene);
        expect(
          find.byKey(ValueKey('holiday-${scene.name}-artwork')),
          findsOneWidget,
        );
        expect(
          tester.widget<Semantics>(holidayShortcut(scene)).properties.selected,
          isTrue,
        );
      }
      expect(
        tester
            .widget<Semantics>(holidayShortcut(HolidayScene.guoqing))
            .properties
            .selected,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('the two January solar terms use their Gregorian year', () {
    for (final (year, minorCold, majorCold) in [
      (2004, 6, 21),
      (2027, 5, 20),
      (2028, 6, 20),
      (2099, 5, 20),
    ]) {
      final events = HolidayCalendarData.eventsForYear(year);
      for (final (scene, day) in [
        (HolidayScene.xiaohan, minorCold),
        (HolidayScene.dahan, majorCold),
      ]) {
        final date = DateTime(year, 1, day);
        expect(events.singleWhere((event) => event.scene == scene).date, date);
        expect(HolidayCalendarData.eventOn(date)?.scene, scene);
      }
    }
  });

  test(
    'Lichun uses its actual yearly date and keeps the events chronological',
    () {
      expect(
        HolidayCalendarData.eventOn(DateTime(2025, 2, 3))?.scene,
        HolidayScene.lichun,
      );
      expect(HolidayCalendarData.eventOn(DateTime(2025, 2, 4)), isNull);
      expect(
        HolidayCalendarData.eventOn(DateTime(2027, 2, 4))?.scene,
        HolidayScene.lichun,
      );
      final events = HolidayCalendarData.eventsForYear(2025);
      expect(events.take(6).map((event) => event.scene), [
        HolidayScene.yuandan,
        HolidayScene.xiaohan,
        HolidayScene.dahan,
        HolidayScene.chuxi,
        HolidayScene.lanterns,
        HolidayScene.lichun,
      ]);
      expect(
        events.where((event) => event.scene == HolidayScene.lichun),
        hasLength(1),
      );
      for (var i = 1; i < events.length; i++) {
        expect(events[i].date.isAfter(events[i - 1].date), isTrue);
      }
    },
  );

  test(
    'Rain Water uses the solar-term date rather than a fixed yearly day',
    () {
      expect(
        HolidayCalendarData.eventOn(DateTime(2027, 2, 19))?.scene,
        HolidayScene.yushui,
      );
      expect(
        HolidayCalendarData.eventOn(DateTime(2026, 2, 18))?.scene,
        HolidayScene.yushui,
      );
      expect(HolidayCalendarData.eventOn(DateTime(2027, 2, 18)), isNull);
      expect(
        HolidayCalendarData.eventsForYear(
          2027,
        ).where((event) => event.scene == HolidayScene.yushui),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'Rain Water shortcut uses the SDK selection and supports reduced motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo());
      await tester.pumpAndSettle();
      await selectHolidayShortcut(
        tester,
        HolidayScene.yushui,
        DateTime(2027, 2, 19),
      );
      final view = _calendar(tester);
      expect(view.controller.selection.single, DateTime(2027, 2, 19));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '雨水',
      );
      expect(
        (view.componentBuilder! as HolidayCalendarComponentBuilder)
            .frames!
            .value
            .scene,
        HolidayScene.yushui,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await _tapDay(tester, DateTime(2027, 2, 18));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '2月18日',
      );
      await _tapDay(tester, DateTime(2027, 2, 19));
      expect(view.controller.selection.single, DateTime(2027, 2, 19));
      await tester.pump(const Duration(seconds: 30));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home entry opens one SDK calendar and returns cleanly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();
    expect(find.byType(HolidayDemoIcon), findsOneWidget);
    expect(find.text('飘雪烟花 · 春雨新芽 · 万物初醒'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('节日光影')).dy,
      lessThan(tester.getTopLeft(find.text('iOS日历')).dy),
    );
    await tester.tap(find.text('节日光影'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final calendars = find.descendant(
      of: find.byType(HolidayCalendarPage),
      matching: find.byType(CalendarView),
    );
    expect(calendars, findsOneWidget);
    expect(
      tester.widget<CalendarView>(calendars).componentBuilder,
      isA<HolidayCalendarComponentBuilder>(),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HolidayCalendarPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month shortcuts are compact and the picker browses separately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_demo());
    await tester.pumpAndSettle();

    final snow = holidayShortcut(HolidayScene.snow);
    expect(tester.widget<Semantics>(snow).properties.selected, isTrue);
    expect(
      tester.getTopLeft(holidayShortcut(HolidayScene.daxue)).dy,
      tester.getTopLeft(holidayShortcut(HolidayScene.dongzhi)).dy,
    );
    expect(
      tester.getTopLeft(snow).dy,
      tester.getTopLeft(holidayShortcut(HolidayScene.fireworks)).dy,
    );
    expect(holidayShortcut(HolidayScene.xiaohan), findsNothing);

    await openHolidayPicker(tester);
    await tester.tap(find.byKey(const ValueKey('holiday-picker-month-2027-1')));
    await tester.pumpAndSettle();
    expect(holidayShortcut(HolidayScene.xiaohan), findsOneWidget);
    expect(holidayShortcut(HolidayScene.dahan), findsOneWidget);
    expect(holidayShortcut(HolidayScene.lichun), findsNothing);
    expect(
      _calendar(tester).controller.selection.single,
      DateTime(2026, 12, 25),
    );
    expect(_calendar(tester).controller.focusedDay.month, 12);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(holidayShortcut(HolidayScene.xiaohan), findsNothing);
    final next = find.byTooltip('下个月');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(holidayShortcut(HolidayScene.xiaohan), findsOneWidget);
    expect(snow, findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Jingzhe follows its yearly solar term with a gentle thunder pulse', () {
    expect(
      HolidayCalendarData.eventOn(DateTime(2026, 3, 5))?.scene,
      HolidayScene.jingzhe,
    );
    expect(
      HolidayCalendarData.eventOn(DateTime(2027, 3, 6))?.scene,
      HolidayScene.jingzhe,
    );
    expect(HolidayCalendarData.eventOn(DateTime(2027, 3, 5)), isNull);
    for (final year in [2004, 2025, 2026, 2027, 2028, 2099]) {
      final events = HolidayCalendarData.eventsForYear(year);
      final event = events.singleWhere(
        (event) => event.scene == HolidayScene.jingzhe,
      );
      expect(event.date.year, year);
      expect(event.date.month, 3);
    }
    expect(holidayThunderPulse(0), 0);
    expect(holidayThunderPulse(1), closeTo(1, 0.0001));
    expect(holidayThunderPulse(2), 0);
    expect(holidayThunderPulse(11.5), closeTo(1, 0.0001));
    expect(
      const HolidaySceneFrame(scene: HolidayScene.jingzhe, seconds: 1).flash,
      closeTo(0.18, 0.0001),
    );
  });

  test(
    'Spring Equinox follows its yearly date and uses the approved still frame',
    () {
      expect(
        HolidayCalendarData.eventOn(DateTime(2026, 3, 20))?.scene,
        HolidayScene.chunfen,
      );
      expect(
        HolidayCalendarData.eventOn(DateTime(2027, 3, 21))?.scene,
        HolidayScene.chunfen,
      );
      expect(HolidayCalendarData.eventOn(DateTime(2027, 3, 20)), isNull);
      expect(
        HolidayCalendarData.eventOn(DateTime(2028, 3, 20))?.scene,
        HolidayScene.chunfen,
      );
      expect(HolidayScene.chunfen.stillSeconds, 5.5);
    },
  );

  for (final example in [
    (scene: HolidayScene.jingzhe, date: DateTime(2027, 3, 6), title: '惊蛰'),
    (scene: HolidayScene.chunfen, date: DateTime(2027, 3, 21), title: '春分'),
  ]) {
    for (final size in [
      const Size(320, 568),
      const Size(375, 812),
      const Size(812, 375),
    ]) {
      testWidgets(
        '${example.scene.name} shortcut works at $size with large text and reduced motion',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(_demo(textScale: 2));
          await tester.pumpAndSettle();
          await selectHolidayShortcut(tester, example.scene, example.date);
          final view = _calendar(tester);
          final frames =
              (view.componentBuilder! as HolidayCalendarComponentBuilder)
                  .frames!;
          expect(view.controller.selection.single, example.date);
          expect(view.controller.focusedDay.month, 3);
          expect(frames.value.scene, example.scene);
          expect(frames.value.seconds, example.scene.stillSeconds);
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('holiday-selected-title')),
                )
                .data,
            example.title,
          );
          await tester.pump(const Duration(seconds: 30));
          expect(frames.value.seconds, example.scene.stillSeconds);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('scene animation never changes the selected date or month', (
    tester,
  ) async {
    await tester.pumpWidget(_demo(reducedMotion: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(
      _calendar(tester).controller.selection.single,
      DateTime(2026, 12, 25),
    );
    expect(find.text('2026年12月'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
          .data,
      '圣诞节',
    );
    await tester.tap(find.byTooltip('暂停动效'));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(
      _calendar(tester).controller.selection.single,
      DateTime(2026, 12, 25),
    );
    expect(find.byTooltip('继续动效'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'finger selection, normal month buttons, swipe and today use the SDK',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo());
      await tester.pumpAndSettle();
      final view = _calendar(tester);
      expect(view.handleDaySelection, isTrue);
      expect(
        tester.getSize(find.byKey(const ValueKey('holiday-calendar'))).width /
            7,
        greaterThanOrEqualTo(48),
      );
      await _tapDay(tester, DateTime(2026, 12, 31));
      expect(view.controller.selection.single, DateTime(2026, 12, 31));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '跨年夜',
      );
      await _tapDay(tester, DateTime(2026, 12, 8));
      expect(view.controller.selection.single, DateTime(2026, 12, 8));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '12月8日',
      );

      await tester.tap(find.byTooltip('下个月'));
      await tester.pumpAndSettle();
      expect(find.text('2027年1月'), findsOneWidget);
      await tester.tap(find.byTooltip('下个月'));
      await tester.pumpAndSettle();
      expect(find.text('2027年2月'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('holiday-calendar'))).height,
        view.weekBarHeight + view.calendarHeight * 4,
      );
      await _tapDay(tester, DateTime(2027, 2, 4));
      expect(view.controller.selection.single, DateTime(2027, 2, 4));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '立春',
      );
      final components =
          _calendar(tester).componentBuilder!
              as HolidayCalendarComponentBuilder;
      expect(components.frames!.value.scene, HolidayScene.lichun);
      expect(components.frames!.value.seconds, 2.4);
      await _tapDay(tester, DateTime(2027, 2, 6));
      expect(view.controller.selection.single, DateTime(2027, 2, 6));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '春节',
      );

      await tester.drag(
        find.byKey(const ValueKey('holiday-calendar')),
        const Offset(-270, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2027年3月'), findsOneWidget);
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();
      expect(
        view.controller.selection.single,
        CalendarDateUtils.stripTime(DateTime.now()),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final example in [
    (scene: HolidayScene.lichun, date: DateTime(2027, 2, 4)),
    (scene: HolidayScene.chunfen, date: DateTime(2027, 3, 21)),
  ]) {
    testWidgets(
      '${example.scene.name} continues across clock cycles and pauses without changing dates',
      (tester) async {
        await tester.pumpWidget(_demo(reducedMotion: false));
        await tester.pump();
        final view = _calendar(tester);
        final date = example.date;
        view.controller.selectDay(date);
        view.onDaySelected(date);
        await tester.pump();
        final frames =
            (view.componentBuilder! as HolidayCalendarComponentBuilder).frames!;
        await tester.pump(const Duration(seconds: 11));
        final beforeWrap = frames.value.seconds;
        await tester.pump(const Duration(seconds: 2));
        expect(frames.value.seconds, greaterThan(beforeWrap));
        expect(frames.value.seconds, greaterThanOrEqualTo(13));
        expect(frames.value.scene, example.scene);
        expect(view.controller.selection.single, date);
        await tester.tap(find.byTooltip('暂停动效'));
        await tester.pumpAndSettle();
        final paused = frames.value.seconds;
        await tester.pump(const Duration(seconds: 30));
        expect(frames.value.seconds, paused);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.tap(find.byTooltip('继续动效'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(frames.value.seconds, greaterThan(paused));
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Lichun shortcut selects the SDK day and stays still with reduced motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_demo());
      await tester.pumpAndSettle();
      await selectHolidayShortcut(
        tester,
        HolidayScene.lichun,
        DateTime(2027, 2, 4),
      );
      expect(
        _calendar(tester).controller.selection.single,
        DateTime(2027, 2, 4),
      );
      expect(find.text('2027年2月'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('holiday-selected-title')))
            .data,
        '立春',
      );
      await tester.pump(const Duration(seconds: 20));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('six-week months show and select their final row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_demo());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('上个月'));
      await tester.pumpAndSettle();
    }
    expect(find.text('2026年8月'), findsOneWidget);
    final view = _calendar(tester);
    expect(
      tester.getSize(find.byKey(const ValueKey('holiday-calendar'))).height,
      view.weekBarHeight + view.calendarHeight * 6,
    );
    await _tapDay(tester, DateTime(2026, 8, 31));
    expect(view.controller.selection.single, DateTime(2026, 8, 31));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone, landscape and large text scroll without scaling down the calendar',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in [
        const Size(320, 568),
        const Size(375, 812),
        const Size(812, 375),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(_demo(textScale: 2));
        await tester.pumpAndSettle();
        expect(_calendar(tester).calendarHeight, greaterThanOrEqualTo(80));
        expect(
          tester
              .getSize(find.byKey(const ValueKey('holiday-calendar-card')))
              .width,
          greaterThanOrEqualTo(size.width < 600 ? size.width - 24 : 576),
        );
        await selectHolidayShortcut(
          tester,
          HolidayScene.lanterns,
          DateTime(2027, 2, 6),
        );
        expect(
          _calendar(tester).controller.selection.single,
          DateTime(2027, 2, 6),
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('holiday-selected-title')),
              )
              .data,
          '春节',
        );
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}
