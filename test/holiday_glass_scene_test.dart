import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_data.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_calendar_page.dart';
import 'package:calendarview_flutter/src/features/holiday/holiday_glass_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _glassScenes = [
  HolidayScene.qingming,
  HolidayScene.guyu,
  HolidayScene.lixia,
  HolidayScene.xiaoman,
  HolidayScene.mangzhong,
  HolidayScene.xiazhi,
  HolidayScene.xiaoshu,
  HolidayScene.dashu,
  HolidayScene.liqiu,
  HolidayScene.chushu,
  HolidayScene.bailu,
  HolidayScene.qiufen,
  HolidayScene.hanlu,
  HolidayScene.shuangjiang,
  HolidayScene.lidong,
  HolidayScene.xiaoxue,
  HolidayScene.daxue,
  HolidayScene.dongzhi,
  HolidayScene.xiaohan,
  HolidayScene.dahan,
  HolidayScene.yuandan,
  HolidayScene.chuxi,
  HolidayScene.yuanxiao,
  HolidayScene.laodong,
  HolidayScene.duanwu,
  HolidayScene.zhongqiu,
  HolidayScene.guoqing,
];

Future<Uint8List> _render(HolidayScene scene, double seconds) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final background = recordHolidayGlassBackdrop(scene);
  final initialSaves = canvas.getSaveCount();
  canvas.drawPicture(background);
  paintHolidayGlassMotion(canvas, scene, seconds);
  expect(canvas.getSaveCount(), initialSaves);
  final picture = recorder.endRecording();
  final image = await picture.toImage(584, 440);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final pixels = Uint8List.fromList(bytes.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  background.dispose();
  return pixels;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final scene in _glassScenes) {
    test(
      '${scene.name} is deterministic, transparent and repeats after 13 seconds',
      () async {
        final first = await _render(scene, 2.75);
        expect(await _render(scene, 15.75), orderedEquals(first));
        expect(await _render(scene, 4.25), isNot(orderedEquals(first)));
        expect(first[(439 * 584) * 4 + 3], 0);
      },
    );
    testWidgets(
      '${scene.name} keeps native selection and paints the approved card',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const HolidayCalendarPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final calendar = tester.widget<CalendarView>(
          find.byKey(const ValueKey('holiday-calendar')),
        );
        final date = HolidayCalendarData.eventsForYear(
          2027,
        ).singleWhere((event) => event.scene == scene).date;
        expect(calendar.controller.selectDay(date), isTrue);
        calendar.onDaySelected(date);
        await tester.pumpAndSettle();
        expect(calendar.controller.selection.single, date);
        if (scene.usesFestivalArtwork) {
          expect(
            find.byKey(ValueKey('holiday-${scene.name}-artwork')),
            findsOneWidget,
          );
        }
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.foregroundPainter is HolidayGlassCardOverlayPainter,
          ),
          findsOneWidget,
        );
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
        const outputDir = String.fromEnvironment('HOLIDAY_QA_DIR');
        if (outputDir.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('holiday-calendar-card')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            await Directory(outputDir).create(recursive: true);
            await File(
              '$outputDir/${scene.name}.png',
            ).writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test('the approved scenes have distinct drawings', () async {
    final fingerprints = <int>{};
    for (final scene in _glassScenes) {
      fingerprints.add(Object.hashAll(await _render(scene, 2.75)));
    }
    expect(fingerprints, hasLength(_glassScenes.length));
  });

  test(
    'the crane carries the beam and the windows illuminate after landing',
    () async {
      const scene = HolidayScene.laodong;
      final hoisting = await _render(scene, 2);
      final carrying = await _render(scene, 5.4);
      final seated = await _render(scene, 8.13);
      final lit = await _render(scene, 10.7);
      int brightPixels(Uint8List frame, Rect bounds, {bool warm = false}) {
        var count = 0;
        for (var y = bounds.top.toInt(); y < bounds.bottom.toInt(); y++) {
          for (var x = bounds.left.toInt(); x < bounds.right.toInt(); x++) {
            final i = (y * 584 + x) * 4;
            if (frame[i + 3] > 184 &&
                frame[i] > 155 &&
                (warm ? frame[i] - frame[i + 2] > 60 : frame[i + 2] > 135)) {
              count++;
            }
          }
        }
        return count;
      }

      const start = Rect.fromLTWH(271, 132, 80, 18);
      const overFrame = Rect.fromLTWH(394, 118, 86, 15);
      const roof = Rect.fromLTWH(393, 142, 90, 13);
      const windows = Rect.fromLTWH(395, 165, 88, 39);
      expect(
        brightPixels(hoisting, start),
        greaterThan(brightPixels(carrying, start) + 100),
      );
      expect(
        brightPixels(carrying, overFrame),
        greaterThan(brightPixels(hoisting, overFrame) + 400),
      );
      expect(
        brightPixels(seated, roof),
        greaterThan(brightPixels(carrying, roof) + 400),
      );
      expect(
        brightPixels(lit, windows, warm: true),
        greaterThan(brightPixels(seated, windows, warm: true) + 250),
      );
      expect(
        const HolidaySceneFrame(scene: scene, seconds: 8.3).glassLight,
        greaterThan(.1),
      );
    },
  );

  test('the three replacement badges render distinct artwork', () async {
    final signatures = <int>{};
    for (final scene in [
      HolidayScene.yuandan,
      HolidayScene.laodong,
      HolidayScene.guoqing,
    ]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      paintHolidayGlassDate(
        canvas,
        scene,
        const Offset(62, 48),
        scale: 2,
        seconds: scene.stillSeconds,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(64, 64);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      var opaquePixels = 0;
      for (var i = 3; i < pixels.length; i += 4) {
        if (pixels[i] > 190) opaquePixels++;
      }
      expect(opaquePixels, greaterThan(30));
      signatures.add(Object.hashAll(pixels));
      image.dispose();
      picture.dispose();
    }
    expect(signatures, hasLength(3));
  });

  test('wintersweet opens and brings warm color to the glass', () async {
    int blossomPixels(Uint8List frame) {
      var total = 0;
      for (var y = 80; y < 136; y++) {
        for (var x = 395; x < 467; x++) {
          final i = (y * 584 + x) * 4;
          final r = frame[i], g = frame[i + 1], b = frame[i + 2];
          if (frame[i + 3] > 160 && r > 175 && r - g > 10 && g - b > 24) {
            total++;
          }
        }
      }
      return total;
    }

    const scene = HolidayScene.xiaohan;
    final buds = await _render(scene, 0);
    final flowers = await _render(scene, scene.stillSeconds);
    expect(blossomPixels(flowers), greaterThan(blossomPixels(buds) * 3));
    final open = HolidaySceneFrame(scene: scene, seconds: scene.stillSeconds);
    const closed = HolidaySceneFrame(scene: scene, seconds: 0);
    expect(open.tint.r, greaterThan(closed.tint.r));
    expect(open.glassLight, greaterThan(closed.glassLight));
  });

  test(
    'icicles grow under the roof while large flakes pass the house',
    () async {
      int coldPixels(Uint8List frame, Rect bounds) {
        var total = 0;
        for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
          for (var x = bounds.left.toInt(); x < bounds.right; x++) {
            final i = (y * 584 + x) * 4;
            final r = frame[i], b = frame[i + 2], a = frame[i + 3];
            if (a > 105 && b * 255 > 197 * a && b - r > .025 * a) total++;
          }
        }
        return total;
      }

      const scene = HolidayScene.dahan;
      final early = await _render(scene, 0);
      final grown = await _render(scene, scene.stillSeconds);
      const underEaves = Rect.fromLTWH(429, 143, 85, 59);
      expect(
        coldPixels(grown, underEaves),
        greaterThan(coldPixels(early, underEaves) + 700),
      );
      const openSky = Rect.fromLTWH(200, 25, 104, 143);
      final flurries = [
        for (final time in [1.0, 3.5, 6.0, 8.7])
          coldPixels(await _render(scene, time), openSky),
      ];
      expect(flurries, everyElement(greaterThan(135)));
      expect(flurries.toSet(), hasLength(greaterThanOrEqualTo(3)));
    },
  );

  test('the chopsticks lift a dumpling and return it to the plate', () async {
    int dumplingPixels(Uint8List frame, Rect bounds) {
      var count = 0;
      for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
        for (var x = bounds.left.toInt(); x < bounds.right; x++) {
          final index = (y * 584 + x) * 4;
          if (frame[index] > 195 &&
              frame[index + 1] > 175 &&
              frame[index + 2] > 145 &&
              frame[index + 3] > 225) {
            count++;
          }
        }
      }
      return count;
    }

    const scene = HolidayScene.dongzhi;
    const abovePlate = Rect.fromLTWH(411, 95, 74, 50);
    const frontOfPlate = Rect.fromLTWH(443, 202, 60, 34);
    final resting = await _render(scene, 0);
    final held = await _render(scene, scene.stillSeconds);
    final returned = await _render(scene, 12.9);
    expect(dumplingPixels(resting, abovePlate), 0);
    expect(dumplingPixels(held, abovePlate), greaterThan(950));
    expect(dumplingPixels(held, frontOfPlate), lessThan(100));
    expect(dumplingPixels(returned, frontOfPlate), greaterThan(950));
    expect(dumplingPixels(returned, abovePlate), 0);
  });

  test(
    'the wind-driven snow thickens on the roof as the cabin lights up',
    () async {
      int snowPixels(
        Uint8List frame,
        Rect bounds, {
        bool warm = false,
        int minAlpha = 160,
      }) {
        var count = 0;
        for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
          for (var x = bounds.left.toInt(); x < bounds.right; x++) {
            final index = (y * 584 + x) * 4;
            final r = frame[index], g = frame[index + 1], b = frame[index + 2];
            final alpha = frame[index + 3];
            if (alpha <= minAlpha) continue;
            if (warm
                ? r > 198 && g > 127 && r - b > 62
                : r * 255 > 150 * alpha &&
                      b * 255 > 193 * alpha &&
                      g * 255 > 170 * alpha) {
              count++;
            }
          }
        }
        return count;
      }

      const scene = HolidayScene.daxue;
      const roof = Rect.fromLTWH(365, 60, 158, 98);
      const field = Rect.fromLTWH(180, 15, 181, 230);
      const window = Rect.fromLTWH(391, 171, 29, 29);
      final early = await _render(scene, 1);
      final windy = await _render(scene, 4.5);
      final filled = await _render(scene, scene.stillSeconds);
      expect(
        snowPixels(windy, field, minAlpha: 100),
        greaterThan(snowPixels(early, field, minAlpha: 100) + 100),
      );
      expect(
        snowPixels(filled, roof),
        greaterThan(snowPixels(windy, roof) + 2000),
      );
      expect(
        snowPixels(filled, window, warm: true),
        greaterThan(snowPixels(early, window, warm: true) + 300),
      );
    },
  );

  test('snow settles on the pine and a gust shakes some below it', () async {
    int snowPixels(Uint8List frame, Rect bounds) {
      var count = 0;
      for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
        for (var x = bounds.left.toInt(); x < bounds.right; x++) {
          final index = (y * 584 + x) * 4;
          final alpha = frame[index + 3];
          if (alpha > 145 &&
              frame[index] * 255 > 167 * alpha &&
              frame[index + 2] * 255 > 203 * alpha) {
            count++;
          }
        }
      }
      return count;
    }

    const scene = HolidayScene.xiaoxue;
    const bough = Rect.fromLTWH(278, 71, 302, 102);
    const belowBough = Rect.fromLTWH(330, 175, 191, 78);
    final early = await _render(scene, 1);
    final settled = await _render(scene, scene.stillSeconds);
    final gust = await _render(scene, 8.8);
    expect(
      snowPixels(settled, bough),
      greaterThan(snowPixels(early, bough) + 500),
    );
    expect(snowPixels(gust, bough), lessThan(snowPixels(settled, bough)));
    expect(
      snowPixels(gust, belowBough),
      greaterThan(snowPixels(settled, belowBough) + 24),
    );
  });

  test(
    'the winter stove brightens before the kettle starts steaming',
    () async {
      int countPixels(Uint8List pixels, Rect bounds, {required bool steam}) {
        var count = 0;
        for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
          for (var x = bounds.left.toInt(); x < bounds.right; x++) {
            final index = (y * 584 + x) * 4;
            final r = pixels[index],
                g = pixels[index + 1],
                b = pixels[index + 2];
            final a = pixels[index + 3];
            if (steam
                ? a > 48 && r * 255 > 187 * a && b * 255 > 210 * a
                : a > 160 && r > 172 && g > 85 && r - b > 80) {
              count++;
            }
          }
        }
        return count;
      }

      const scene = HolidayScene.lidong;
      const firebox = Rect.fromLTWH(403, 196, 52, 43);
      const aboveSpout = Rect.fromLTWH(282, 21, 67, 77);
      final embers = await _render(scene, 1);
      final heating = await _render(scene, 3.5);
      final boiling = await _render(scene, scene.stillSeconds);
      expect(
        countPixels(heating, firebox, steam: false),
        greaterThan(countPixels(embers, firebox, steam: false) + 100),
      );
      expect(
        countPixels(boiling, aboveSpout, steam: true),
        greaterThan(countPixels(heating, aboveSpout, steam: true) + 100),
      );
      expect(countPixels(embers, aboveSpout, steam: true), 0);
      const cold = HolidaySceneFrame(scene: scene, seconds: 1);
      const hot = HolidaySceneFrame(scene: scene, seconds: 7.1);
      expect(cold.tint.b, greaterThan(cold.tint.r));
      expect(hot.tint.r, greaterThan(hot.tint.b));
    },
  );

  test(
    'frost spreads over the persimmon shoulders while the fruit stays warm',
    () async {
      ({int rime, int fruit}) fruitPixels(Uint8List frame) {
        var rime = 0, fruit = 0;
        for (var y = 124; y < 226; y++) {
          for (var x = 347; x < 530; x++) {
            final index = (y * 584 + x) * 4;
            final r = frame[index], g = frame[index + 1], b = frame[index + 2];
            if (frame[index + 3] < 160) continue;
            if (b > 145 && g > 130 && b - r > 7) rime++;
            if (r > 160 && r - b > 65) fruit++;
          }
        }
        return (rime: rime, fruit: fruit);
      }

      const scene = HolidayScene.shuangjiang;
      final clear = fruitPixels(await _render(scene, 1));
      final early = fruitPixels(await _render(scene, 5.6));
      final frozen = fruitPixels(await _render(scene, scene.stillSeconds));
      expect(clear.rime, 0);
      expect(early.rime, greaterThan(clear.rime));
      expect(frozen.rime, greaterThan(early.rime + 140));
      expect(frozen.fruit, greaterThan(clear.fruit * .55));
    },
  );

  test(
    'cold dew opens the chrysanthemum before its petal tips glint',
    () async {
      ({int petals, int dew}) flowerPixels(Uint8List frame) {
        var petals = 0, dew = 0;
        for (var y = 43; y < 193; y++) {
          for (var x = 319; x < 517; x++) {
            final index = (y * 584 + x) * 4;
            final r = frame[index], g = frame[index + 1], b = frame[index + 2];
            final alpha = frame[index + 3];
            if (alpha > 175 && r > 160 && g > 90 && r - b > 65) petals++;
            if (alpha > 130 &&
                r > 148 &&
                g > 157 &&
                b > 161 &&
                (r - b).abs() < 35) {
              dew++;
            }
          }
        }
        return (petals: petals, dew: dew);
      }

      const scene = HolidayScene.hanlu;
      final bud = flowerPixels(await _render(scene, 1));
      final opening = flowerPixels(await _render(scene, 4));
      final bloomed = flowerPixels(await _render(scene, scene.stillSeconds));
      expect(opening.petals, greaterThan(bud.petals * 2));
      expect(bloomed.petals, greaterThan(opening.petals * 1.25));
      expect(opening.dew, bud.dew);
      expect(bloomed.dew, greaterThan(opening.dew + 12));
    },
  );

  test('the equinox sun sets as the moon rises and cools the glass', () async {
    ({int count, double height}) findDisc(
      Uint8List frame, {
      required bool sun,
    }) {
      var count = 0, sum = 0;
      for (var y = 25; y < 183; y++) {
        for (var x = sun ? 260 : 397; x < (sun ? 349 : 528); x++) {
          final index = (y * 584 + x) * 4;
          final r = frame[index], b = frame[index + 2];
          if (frame[index + 3] < 178) continue;
          if (sun ? r > 203 && r - b > 37 : b > 210 && b - r > 15) {
            count++;
            sum += y;
          }
        }
      }
      return (count: count, height: count == 0 ? 0 : sum / count);
    }

    const scene = HolidayScene.qiufen;
    const sunset = HolidaySceneFrame(scene: scene, seconds: 2.5);
    const moonrise = HolidaySceneFrame(scene: scene, seconds: 10.5);
    final early = await _render(scene, sunset.seconds);
    final middle = await _render(scene, scene.stillSeconds);
    final late = await _render(scene, moonrise.seconds);
    final balancedSun = findDisc(middle, sun: true);
    final balancedMoon = findDisc(middle, sun: false);
    expect(balancedSun.count, greaterThan(900));
    expect(balancedMoon.count, greaterThan(450));
    expect((balancedSun.height - balancedMoon.height).abs(), lessThan(12));
    expect(
      balancedSun.height - findDisc(early, sun: true).height,
      greaterThan(50),
    );
    expect(
      balancedMoon.height - findDisc(late, sun: false).height,
      greaterThan(50),
    );
    expect(findDisc(late, sun: true).count, 0);
    expect(sunset.tint.r, greaterThan(sunset.tint.b));
    expect(moonrise.tint.b, greaterThan(moonrise.tint.r));
  });

  test(
    'white dew detaches from the leaf and drops through clear space',
    () async {
      int brightDew(Uint8List pixels, int top, int bottom) {
        var count = 0;
        for (var y = top; y < bottom; y++) {
          for (var x = 520; x < 545; x++) {
            final index = (y * 584 + x) * 4;
            if (pixels[index + 3] > 160 &&
                pixels[index] > 120 &&
                pixels[index + 2] > 135) {
              count++;
            }
          }
        }
        return count;
      }

      final tip = await _render(HolidayScene.bailu, 7.15);
      final falling = await _render(HolidayScene.bailu, 7.85);
      final finished = await _render(HolidayScene.bailu, 8.25);
      expect(brightDew(tip, 176, 200), greaterThan(35));
      expect(brightDew(tip, 208, 237), 0);
      expect(brightDew(falling, 176, 200), 0);
      expect(brightDew(falling, 208, 237), greaterThan(35));
      expect(brightDew(finished, 208, 237), 0);
    },
  );

  test(
    'the solstice dial is lit where the morning shadow has moved away',
    () async {
      const scene = HolidayScene.xiazhi;
      final morning = await _render(scene, 0);
      final noon = await _render(scene, scene.stillSeconds);
      const shadowPixel = (157 * 584 + 480) * 4;
      int brightness(Uint8List pixels) =>
          pixels[shadowPixel] +
          pixels[shadowPixel + 1] +
          pixels[shadowPixel + 2];
      expect(brightness(noon), greaterThan(brightness(morning) + 130));
    },
  );

  test(
    'autumn leaves move from the tree into the space under the canopy',
    () async {
      int leavesBelowCanopy(Uint8List pixels) {
        var count = 0;
        for (var y = 146; y < 226; y++) {
          for (var x = 270; x < 386; x++) {
            final index = (y * 584 + x) * 4;
            if (pixels[index + 3] > 120 &&
                pixels[index] > pixels[index + 1] + 28) {
              count++;
            }
          }
        }
        return count;
      }

      final beforeDrop = await _render(HolidayScene.liqiu, 0);
      final inFlight = await _render(HolidayScene.liqiu, 3.1);
      expect(
        leavesBelowCanopy(inFlight),
        greaterThan(leavesBelowCanopy(beforeDrop) + 20),
      );
    },
  );

  test(
    'the end-of-heat artwork and glass tint cool on the same clock',
    () async {
      const scene = HolidayScene.chushu;
      const warm = HolidaySceneFrame(scene: scene, seconds: 0);
      const cool = HolidaySceneFrame(scene: scene, seconds: 8.25);
      expect(warm.tint.r, greaterThan(warm.tint.b));
      expect(cool.tint.b, greaterThan(cool.tint.r));
      expect(
        const HolidaySceneFrame(scene: scene, seconds: 21.25).tint,
        cool.tint,
      );

      const lightPixel = (90 * 584 + 320) * 4;
      final early = await _render(scene, warm.seconds);
      final late = await _render(scene, cool.seconds);
      expect(early[lightPixel], greaterThan(early[lightPixel + 2]));
      expect(late[lightPixel + 2], greaterThan(late[lightPixel]));
    },
  );
}
