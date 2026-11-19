import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_components.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_data.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_page.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_scene_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/calendar/Lunar.dart';

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
        of: find.byType(HolidaySceneArtwork),
        matching: find.byType(RepaintBoundary),
      )
      .last;
  final boundary = tester.renderObject<RenderRepaintBoundary>(layer);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final result = Object.hashAll(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    image.dispose();
    return result;
  }))!;
}

void main() {
  for (final example in [
    (
      scene: HolidayScene.guyu,
      title: '谷雨',
      date: DateTime(2027, 4, 20),
      still: 3.78,
    ),
    (
      scene: HolidayScene.lixia,
      title: '立夏',
      date: DateTime(2027, 5, 6),
      still: 9.15,
    ),
    (
      scene: HolidayScene.xiaoman,
      title: '小满',
      date: DateTime(2027, 5, 21),
      still: 4.6,
    ),
    (
      scene: HolidayScene.mangzhong,
      title: '芒种',
      date: DateTime(2027, 6, 6),
      still: 2.5,
    ),
    (
      scene: HolidayScene.xiazhi,
      title: '夏至',
      date: DateTime(2027, 6, 21),
      still: 5.4,
    ),
    (
      scene: HolidayScene.xiaoshu,
      title: '小暑',
      date: DateTime(2027, 7, 7),
      still: 5.4,
    ),
    (
      scene: HolidayScene.dashu,
      title: '大暑',
      date: DateTime(2027, 7, 23),
      still: 6.75,
    ),
    (
      scene: HolidayScene.liqiu,
      title: '立秋',
      date: DateTime(2027, 8, 8),
      still: 4.5,
    ),
    (
      scene: HolidayScene.chushu,
      title: '处暑',
      date: DateTime(2027, 8, 23),
      still: 6.6,
    ),
    (
      scene: HolidayScene.bailu,
      title: '白露',
      date: DateTime(2027, 9, 8),
      still: 7.6,
    ),
    (
      scene: HolidayScene.qiufen,
      title: '秋分',
      date: DateTime(2027, 9, 23),
      still: 6.5,
    ),
    (
      scene: HolidayScene.hanlu,
      title: '寒露',
      date: DateTime(2027, 10, 8),
      still: 7.4,
    ),
    (
      scene: HolidayScene.shuangjiang,
      title: '霜降',
      date: DateTime(2027, 10, 23),
      still: 8.2,
    ),
    (
      scene: HolidayScene.lidong,
      title: '立冬',
      date: DateTime(2027, 11, 7),
      still: 7.1,
    ),
    (
      scene: HolidayScene.xiaoxue,
      title: '小雪',
      date: DateTime(2027, 11, 22),
      still: 7.75,
    ),
    (
      scene: HolidayScene.daxue,
      title: '大雪',
      date: DateTime(2026, 12, 7),
      still: 8.1,
    ),
  ]) {
    test('${example.title} follows yearly lunar solar-term data', () {
      for (final year in [2024, 2025, 2026, 2027, 2028]) {
        final solar = Lunar.fromYmd(year, 1, 1).getJieQiTable()[example.title]!;
        final date = DateTime(
          solar.getYear(),
          solar.getMonth(),
          solar.getDay(),
        );
        expect(HolidayCalendarData.eventOn(date)?.scene, example.scene);
        expect(
          HolidayCalendarData.eventsForYear(
            year,
          ).where((e) => e.scene == example.scene),
          hasLength(1),
        );
      }
      expect(example.scene.stillSeconds, example.still);
      expect(
        HolidayCalendarData.nearbyEvents(
          DateTime(2026, 12),
        ).map((event) => event.date),
        contains(example.date),
      );
    });
    for (final size in [
      const Size(320, 568),
      const Size(375, 812),
      const Size(812, 375),
    ]) {
      testWidgets(
        '${example.title} shortcut uses SDK grid and freezes with large text at $size',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(_demo(textScale: 2));
          await tester.pumpAndSettle();
          await selectHolidayShortcut(tester, example.scene, example.date);
          final calendar = _calendar(tester),
              frames =
                  (calendar.componentBuilder!
                          as HolidayCalendarComponentBuilder)
                      .frames!;
          expect(find.byType(CalendarView), findsOneWidget);
          expect(find.byType(HolidaySceneArtwork), findsOneWidget);
          expect(calendar.controller.selection.single, example.date);
          expect(frames.value.scene, example.scene);
          expect(frames.value.seconds, example.still);
          expect(find.byType(Image), findsNothing);
          final image = await _motionPixels(tester);
          await tester.pump(const Duration(seconds: 40));
          expect(await _motionPixels(tester), image);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
    testWidgets(
      '${example.title} animates across the 12-second clock, pauses, and leaves cleanly',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_demo(reduced: false));
        await tester.pump();
        final calendar = _calendar(tester);
        calendar.controller.selectDay(example.date);
        calendar.onDaySelected(example.date);
        await tester.pump();
        await tester.pump();
        final frames =
            (calendar.componentBuilder! as HolidayCalendarComponentBuilder)
                .frames!;
        final first = await _motionPixels(tester);
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(frames.value.seconds, greaterThanOrEqualTo(15));
        expect(await _motionPixels(tester), isNot(first));
        expect(calendar.controller.selection.single, example.date);
        await tester.tap(find.byTooltip('暂停动效'));
        await tester.pumpAndSettle();
        final paused = await _motionPixels(tester),
            seconds = frames.value.seconds;
        await tester.pump(const Duration(seconds: 25));
        expect(frames.value.seconds, seconds);
        expect(await _motionPixels(tester), paused);
        expect(tester.binding.hasScheduledFrame, isFalse);
        await tester.tap(find.byTooltip('继续动效'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(frames.value.seconds, greaterThan(seconds));
        await tester.pumpWidget(_demo());
        await tester.pumpAndSettle();
        expect(frames.value.seconds, example.still);
        expect(tester.binding.hasScheduledFrame, isFalse);
        final normal = example.date.add(const Duration(days: 1));
        calendar.controller.selectDay(normal);
        calendar.onDaySelected(normal);
        await tester.pumpAndSettle();
        expect(find.byType(HolidaySceneArtwork), findsNothing);
        expect(frames.value.scene, HolidayScene.ambient);
        calendar.controller.selectDay(example.date);
        calendar.onDaySelected(example.date);
        await tester.pumpAndSettle();
        expect(find.byType(HolidaySceneArtwork), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
