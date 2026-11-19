// Native Canvas counterpart of the confirmed glass-calendar web scenes.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';

part 'holiday_glass_autumn.dart';
part 'holiday_glass_chime.dart';
part 'holiday_glass_chrysanthemum.dart';
part 'holiday_glass_deep_snow.dart';
part 'holiday_glass_cicada.dart';
part 'holiday_glass_dew.dart';
part 'holiday_glass_equinox.dart';
part 'holiday_glass_fireflies.dart';
part 'holiday_glass_festivals.dart';
part 'holiday_glass_frost.dart';
part 'holiday_glass_labour.dart';
part 'holiday_glass_pine.dart';
part 'holiday_glass_sowing.dart';
part 'holiday_glass_sundial.dart';
part 'holiday_glass_tea.dart';
part 'holiday_glass_wheat.dart';
part 'holiday_glass_winter_solstice.dart';
part 'holiday_glass_wintersweet.dart';
part 'holiday_glass_icicle_house.dart';

const _tau = math.pi * 2;
const _loop = HolidayCalendarDesign.glassSceneCycleSeconds;
const holidayGlassSceneSize = Size(584, 440);

/// Keeps foreground particles and the glass rim on the existing scene clock.
class HolidayGlassCardOverlayPainter extends CustomPainter {
  HolidayGlassCardOverlayPainter(this.frames) : super(repaint: frames);
  final ValueListenable<HolidaySceneFrame> frames;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final frame = frames.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (frame.scene == HolidayScene.qingming ||
        frame.scene == HolidayScene.guyu) {
      final scale = size.width / 584;
      canvas.save();
      canvas.scale(scale);
      _rain(
        canvas,
        frame.seconds % _loop,
        const Color(0xFFBEDACD),
        18,
        .16,
        size.height / scale,
      );
      canvas.restore();
    }
    if (frame.scene == HolidayScene.mangzhong) {
      canvas.save();
      canvas.scale(size.width / 584);
      _motes(canvas, frame.seconds % _loop, const Color(0xFFFAD085), 8, .25);
      canvas.restore();
    }
    final glassLight = frame.glassLight;
    final rim = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.5),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _a(frame.tint, .18 + glassLight),
    );
    canvas.drawLine(
      const Offset(24, 1),
      Offset(size.width - 24, 1),
      Paint()
        ..strokeWidth = 1
        ..color = _a(_mix(frame.tint, Colors.white, .6), .16 + glassLight),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HolidayGlassCardOverlayPainter oldDelegate) =>
      oldDelegate.frames != frames;
}

double _phase(double t, [double rate = 1, double offset = 0]) =>
    _tau * t / _loop * rate + offset;
Color _a(Color color, double alpha) =>
    color.withValues(alpha: holidayClamp(alpha));
Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

void _glow(Canvas g, double x, double y, double r, Color c, double a) {
  if (r <= 0 || a <= 0) return;
  final center = Offset(x, y);
  g.drawCircle(
    center,
    r,
    Paint()..shader = ui.Gradient.radial(center, r, [_a(c, a), _a(c, 0)]),
  );
}

void _stroke(Canvas g, Path path, Color c, double a, [double width = 1]) =>
    g.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = _a(c, a),
    );

void _line(
  Canvas g,
  double x,
  double y,
  double ex,
  double ey,
  Color c,
  double a, [
  double width = 1,
]) => _stroke(
  g,
  Path()
    ..moveTo(x, y)
    ..lineTo(ex, ey),
  c,
  a,
  width,
);

void _ellipse(
  Canvas g,
  double x,
  double y,
  double rx,
  double ry,
  Color c,
  double a, [
  double angle = 0,
]) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  g.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    Paint()..color = _a(c, a),
  );
  g.restore();
}

void _leaf(
  Canvas g,
  double x,
  double y,
  double length,
  double width,
  double angle,
  Color c,
  double a,
) {
  g.save();
  g.translate(x, y);
  g.rotate(angle);
  final p = Path()
    ..moveTo(0, 0)
    ..cubicTo(-width, -length * .28, -width * .5, -length * .84, 0, -length)
    ..cubicTo(width * .62, -length * .77, width, -length * .18, 0, 0);
  g.drawPath(
    p,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-width, 0),
        Offset(width, -length),
        [
          _a(_mix(c, const Color(0xFF0D2622), .5), a),
          _a(c, a),
          _a(_mix(c, const Color(0xFFEFF6CA), .35), a),
          _a(c, a * .1),
        ],
        const [0, .48, .7, 1],
      ),
  );
  _line(
    g,
    0,
    0,
    0,
    -length,
    _mix(c, const Color(0xFFE1F5CF), .35),
    a * .45,
    .65,
  );
  g.restore();
}

void _mist(Canvas g, double t, Color c, double a, double base) {
  // Plus blending is scoped to these strokes, like the webpage's lighter mode.
  for (var k = 0; k < 22; k++) {
    final u = k / 21;
    final p = Path();
    for (var x = -20.0; x <= 604; x += 8) {
      final y =
          base +
          u * 44 +
          16 * math.sin(x * .009 + _phase(t) + u * 2) +
          9 * math.sin(x * .019 - _phase(t, 2) + u);
      if (x == -20) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    g.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..blendMode = BlendMode.plus
        ..color = _a(
          _mix(c, const Color(0xFF81A4DC), u * .28),
          (.017 + .028 * math.sin(math.pi * u)) * a,
        ),
    );
  }
}

final _particles = List.generate(
  100,
  (i) => (
    x: holidayRandom(i + 700),
    y: holidayRandom(i + 1000),
    r: holidayRandom(i + 1300),
    speed: holidayRandom(i + 1600),
  ),
);

void _rain(
  Canvas g,
  double t,
  Color c,
  int count,
  double alpha, [
  double height = 280,
]) {
  for (var i = 0; i < count; i++) {
    final f = _particles[i];
    final y =
        (f.y * height +
                t / _loop * (height + 38) * (1 + (f.speed * 2).round())) %
            (height + 38) -
        25;
    final x = f.x * 584 - 10 * math.sin(_phase(t)) + y * .08;
    _line(
      g,
      x,
      y,
      x - 2.1,
      y - 7 - f.r * 14,
      c,
      (.08 + f.r * .18) * alpha,
      .5 + f.r * .5,
    );
    if (f.r > .93) _glow(g, x, y, 7, c, .08 * alpha);
  }
}

void _ripple(
  Canvas g,
  double x,
  double y,
  double u,
  Color c,
  double a, [
  double scale = 1,
]) {
  if (u <= 0 || u >= 1) return;
  g.save();
  g.translate(x, y);
  g.scale(1, .24);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .9
    ..color = _a(c, math.sin(u * math.pi) * (1 - u) * .65 * a);
  for (var i = 0; i < 2; i++) {
    g.drawCircle(Offset.zero, (5 + u * 38 + i * 6) * scale, paint);
  }
  g.restore();
}

void _droplet(Canvas g, double x, double y, double r, [double a = 1]) {
  _glow(g, x, y, r * 3, const Color(0xFFA0E1D0), .12 * a);
  g.drawCircle(
    Offset(x, y),
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(x, y),
        r,
        [
          _a(const Color(0xFFF5FFEC), a),
          _a(const Color(0xFFD0F0CD), a * .8),
          _a(const Color(0xFF6BB99F), a * .15),
        ],
        const [0, .25, 1],
        TileMode.clamp,
        null,
        Offset(x - r * .3, y - r * .4),
        .1,
      ),
  );
}

void _umbrella(Canvas g, double x, double y, double r, double t) {
  final opening = .68 + .32 * (.5 - .5 * math.cos(_phase(t)));
  g.save();
  g.translate(x, y);
  g.rotate(-.12 + math.sin(_phase(t)) * .035);
  g.scale(r / 76);
  _stroke(
    g,
    Path()
      ..moveTo(0, -44)
      ..lineTo(0, 48)
      ..quadraticBezierTo(0, 61, 10, 59)
      ..quadraticBezierTo(17, 58, 17, 50),
    const Color(0xFFB2A277),
    .8,
    2,
  );
  g.save();
  g.scale(opening, 1);
  final canopy = Path()
    ..moveTo(-76, 0)
    ..cubicTo(-52, -61, 52, -61, 76, 0)
    ..quadraticBezierTo(57, -10, 38, 1)
    ..quadraticBezierTo(19, -10, 0, 1)
    ..quadraticBezierTo(-19, -10, -38, 1)
    ..quadraticBezierTo(-57, -10, -76, 0)
    ..close();
  g.drawPath(
    canopy,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-56, -45),
        const Offset(44, 15),
        [
          _a(const Color(0xFFE9E0C6), .94),
          _a(const Color(0xFFBFC6B7), .88),
          _a(const Color(0xFF608791), .9),
        ],
        const [0, .45, 1],
      ),
  );
  _stroke(g, canopy, const Color(0xFFE2E4CF), .57);
  for (final end in [-76.0, -57.0, -38.0, -19.0, 0.0, 19.0, 38.0, 57.0, 76.0]) {
    _stroke(
      g,
      Path()
        ..moveTo(0, -45)
        ..quadraticBezierTo(end * .62, -29, end, end % 38 == 0 ? 0 : -4),
      const Color(0xFF607F83),
      .6,
      .7,
    );
  }
  for (var i = 0; i < 29; i++) {
    _ellipse(
      g,
      (holidayRandom(i + 71) - .5) * 94,
      -9 - holidayRandom(i + 140) * 20,
      .55,
      .35,
      const Color(0xFFF7F1D6),
      .2,
    );
  }
  _stroke(
    g,
    Path()
      ..moveTo(-73, -2)
      ..quadraticBezierTo(0, -89, 73, -2),
    const Color(0xFFF4EDD3),
    .34,
    .8,
  );
  _line(g, 0, -49, 0, -44, const Color(0xFFE4DFC3), 1, 2.2);
  g.restore();
  g.restore();
}

/// Cache only the stationary light; transparent pixels preserve the glass fill.
ui.Picture recordHolidayGlassBackdrop(HolidayScene scene) {
  final recorder = ui.PictureRecorder();
  final g = Canvas(recorder, Offset.zero & holidayGlassSceneSize);
  switch (scene) {
    case HolidayScene.yuandan:
      _glow(g, 444, 112, 265, const Color(0xFF476BD4), .44);
      _glow(g, 154, 65, 207, const Color(0xFF409FAD), .19);
      _glow(g, 454, 205, 170, _festBlue, .15);
      _newYearSkyline(g);
    case HolidayScene.yuanxiao:
      _glow(g, 440, 129, 247, const Color(0xFF96414E), .54);
    case HolidayScene.laodong:
      _labourBackdrop(g);
    case HolidayScene.duanwu:
      _glow(g, 409, 89, 243, const Color(0xFF329D91), .45);
      _festivalShade(
        g,
        _festRiverHills,
        const Offset(0, 62),
        const Offset(0, 166),
        const [Color(0xD4376164), Color(0x5917252D)],
      );
    case HolidayScene.zhongqiu:
      _glow(g, 436, 109, 258, const Color(0xFF535DAB), .42);
    case HolidayScene.guoqing:
      _glow(g, 394, 81, 276, const Color(0xFFDC2F2B), .55);
      _glow(g, 463, 163, 141, _festGold, .35);
    case HolidayScene.qingming:
      _glow(g, 360, 18, 285, const Color(0xFF759EB9), .19);
      _glow(g, 500, 134, 139, const Color(0xFFA6B9B4), .13);
    case HolidayScene.guyu:
      _glow(g, 408, 136, 200, const Color(0xFF8FC777), .24);
      _glow(g, 131, 31, 225, const Color(0xFF76AAB7), .14);
    case HolidayScene.lixia:
      _glow(g, 420, 83, 195, const Color(0xFF46B49A), .24);
      _glow(g, 160, 5, 250, const Color(0xFF9AC096), .1);
    case HolidayScene.xiaoman:
      _wheatBackdrop(g);
    case HolidayScene.mangzhong:
      _sowingLandscape(g);
    case HolidayScene.xiazhi:
      _glow(g, 421, 120, 240, const Color(0xFF6992AA), .19);
    case HolidayScene.xiaoshu:
      _glow(g, 410, 75, 252, const Color(0xFF659B61), .23);
      _glow(g, 180, 108, 235, const Color(0xFF468B8E), .15);
    case HolidayScene.dashu:
      _fireflyLandscape(g);
    case HolidayScene.liqiu:
      _autumnLandscape(g);
    case HolidayScene.bailu:
      _glow(g, 415, 107, 255, const Color(0xFF75A6AF), .22);
    case HolidayScene.qiufen:
      _glow(g, 382, 154, 235, HolidayCalendarDesign.qiufen, .10);
    case HolidayScene.lidong:
      _glow(g, 349, 66, 235, const Color(0xFF7196B8), .25);
    case HolidayScene.dongzhi:
      _glow(g, 385, 84, 221, const Color(0xFF839FBE), .24);
    case HolidayScene.xiaohan:
      _glow(g, 453, 111, 198, const Color(0xFF7D9FBE), .25);
    default:
      break;
  }
  return recorder.endRecording();
}

/// All motion wraps at 13 seconds, independent of the page clock's own period.
void paintHolidayGlassMotion(Canvas g, HolidayScene scene, double seconds) {
  final t = seconds % _loop;
  g.save();
  g.clipRect(Offset.zero & holidayGlassSceneSize);
  switch (scene) {
    case HolidayScene.yuandan:
      _newYearFestival(g, t);
    case HolidayScene.chuxi:
      _newYearsEve(g, t);
    case HolidayScene.yuanxiao:
      _lanternFestival(g, t);
    case HolidayScene.laodong:
      _labourDay(g, t);
    case HolidayScene.duanwu:
      _dragonBoatFestival(g, t);
    case HolidayScene.zhongqiu:
      _midAutumn(g, t);
    case HolidayScene.guoqing:
      _nationalDay(g, t);
    case HolidayScene.qingming:
      _qingming(g, t);
    case HolidayScene.guyu:
      _guyu(g, t);
    case HolidayScene.lixia:
      _lixia(g, t);
    case HolidayScene.xiaoman:
      _xiaoman(g, t);
    case HolidayScene.mangzhong:
      _mangzhong(g, t);
    case HolidayScene.xiazhi:
      _xiazhi(g, t);
    case HolidayScene.xiaoshu:
      _xiaoshu(g, t);
    case HolidayScene.dashu:
      _dashu(g, t);
    case HolidayScene.liqiu:
      _liqiu(g, t);
    case HolidayScene.chushu:
      _chushu(g, t);
    case HolidayScene.bailu:
      _bailu(g, t);
    case HolidayScene.qiufen:
      _qiufen(g, t);
    case HolidayScene.hanlu:
      _hanlu(g, t);
    case HolidayScene.shuangjiang:
      _shuangjiang(g, t);
    case HolidayScene.lidong:
      _lidong(g, t);
    case HolidayScene.xiaoxue:
      _xiaoxue(g, t);
    case HolidayScene.daxue:
      _daxue(g, t);
    case HolidayScene.dongzhi:
      _dongzhi(g, t);
    case HolidayScene.xiaohan:
      _xiaohan(g, t);
    case HolidayScene.dahan:
      _dahan(g, t);
    default:
      break;
  }
  g.restore();
}

void _qingming(Canvas g, double t) {
  for (var layer = 0; layer < 3; layer++) {
    final base = 81.0 + layer * 35, shift = math.sin(_phase(t) + layer) * 3;
    final ridge = Path()..moveTo(-20, base + 75);
    for (var x = -20.0; x <= 604; x += 4) {
      final peak =
          math.sin(x * .011 + layer * 1.7) * 22 +
          math.sin(x * .026 + layer) * 10 +
          math.cos(x * .043 + layer) * 4;
      ridge.lineTo(x, base - peak + shift);
    }
    ridge
      ..lineTo(604, base + 75)
      ..close();
    g.drawPath(
      ridge,
      Paint()
        ..shader =
            ui.Gradient.linear(Offset(0, base - 40), Offset(0, base + 75), [
              _a(
                Color.fromARGB(
                  255,
                  96 + layer * 6,
                  137 + layer * 4,
                  155 + layer * 4,
                ),
                .16 + layer * .045,
              ),
              _a(const Color(0xFF36566F), 0),
            ]),
    );
  }
  g.save();
  g.scale(1, .17);
  for (var i = 0; i < 4; i++) {
    _glow(
      g,
      80 + i * 150 + math.sin(_phase(t) + i) * 26,
      590.0 + i * 110,
      190,
      const Color(0xFFA4BAC4),
      .07,
    );
  }
  g.restore();
  final ux = 424 + math.sin(_phase(t)) * 9,
      uy = 112 + math.sin(_phase(t) + .7) * 3;
  _ellipse(g, ux + 3, 201, 65, 6, const Color(0xFF86ADBB), .06);
  _umbrella(g, ux, uy, 85, t);
  _rain(g, t, const Color(0xFFBDD7E7), 92, 1.1, 285);
  for (var i = 0; i < 7; i++) {
    _ripple(
      g,
      65.0 + i * 76,
      198 + holidayRandom(i + 77) * 47,
      (t / _loop * 4 + i * .17) % 1,
      const Color(0xFF9CBED4),
      .64,
    );
  }
}

void _sprout(
  Canvas g,
  double x,
  double y,
  double s,
  double t,
  double seed,
  double a,
) {
  g.save();
  g.translate(x, y);
  g.scale(s);
  final bend = math.sin(_phase(t) + seed) * 6;
  _stroke(
    g,
    Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(bend * .3, -33, bend, -72),
    const Color(0xFF81BD77),
    a * .8,
    1.15,
  );
  _leaf(
    g,
    bend * .55,
    -38,
    43,
    8,
    -.9 + math.sin(_phase(t) + seed) * .06,
    const Color(0xFF96CB7B),
    a,
  );
  _leaf(
    g,
    bend * .3,
    -22,
    53,
    8,
    .76 + math.sin(_phase(t) + seed + 1) * .06,
    const Color(0xFF73B376),
    a,
  );
  _leaf(g, bend, -68, 29, 5, .17, const Color(0xFFB5D689), a);
  g.restore();
}

void _guyu(Canvas g, double t) {
  _mist(g, t, const Color(0xFF8AC08D), .8, 103);
  for (var i = 0; i < 13; i++) {
    _sprout(
      g,
      240.0 + i * 26,
      211 + holidayRandom(i + 120) * 65,
      .42 + holidayRandom(i + 90) * .5,
      t,
      i.toDouble(),
      .26 + holidayRandom(i + 160) * .3,
    );
  }
  _sprout(g, 435, 238, 1.63, t, .4, .9);
  _sprout(g, 507, 261, 1.08, t, 1.5, .8);
  _sprout(g, 349, 236, .91, t, 2.6, .65);
  _rain(g, t, const Color(0xFFCBE7D0), 68, .85, 270);
  final bend = math.sin(_phase(t) + .4) * 6;
  final dropX = 435 + (bend * .55 - 34) * 1.63, u = t / 3.25 % 1;
  _droplet(g, dropX, 238 - 61 * 1.63, 3.2, .9);
  if (u < .58) {
    _droplet(
      g,
      dropX,
      139 + holidayQuintOut(u / .58) * 96,
      1.4 + math.sin(u / .58 * math.pi) * 1.1,
      .8,
    );
  } else {
    _ripple(g, dropX, 235, (u - .58) / .42, const Color(0xFFADD9AF), .9);
  }
  for (var i = 0; i < 5; i++) {
    _ripple(
      g,
      105.0 + i * 99,
      197 + holidayRandom(i + 221) * 47,
      (t / _loop * 4 + i * .23) % 1,
      const Color(0xFFA9D1B3),
      .45,
    );
  }
}

void _lotus(
  Canvas g,
  double x,
  double y,
  double r,
  double flat,
  double angle,
  double t,
  double a,
) {
  g.save();
  g.translate(x, y + math.sin(_phase(t) + r) * 1.2);
  g.rotate(angle + math.sin(_phase(t)) * .014);
  g.scale(1, flat);
  final p = Path();
  for (var i = 0; i <= 80; i++) {
    final an = i / 80 * _tau, rr = r * (1 + .025 * math.sin(an * 7));
    final xx = math.cos(an) * rr, yy = math.sin(an) * rr;
    if (i == 0) {
      p.moveTo(xx, yy);
    } else {
      p.lineTo(xx, yy);
    }
  }
  p.close();
  g.drawPath(
    p,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r,
        [
          _a(const Color(0xFFACD58E), a),
          _a(const Color(0xFF4F9B76), a),
          _a(const Color(0xFF1D5144), a * .55),
        ],
        const [0, .4, 1],
        TileMode.clamp,
        null,
        Offset(-r * .25, -r * .3),
        1,
      ),
  );
  for (var i = 0; i < 18; i++) {
    final an = i / 18 * _tau;
    _stroke(
      g,
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          math.cos(an) * r * .46 + 3,
          math.sin(an) * r * .5 - 3,
          math.cos(an) * r * .96,
          math.sin(an) * r * .96,
        ),
      const Color(0xFFBFE6A0),
      a * .21,
      .65,
    );
  }
  _stroke(g, p, const Color(0xFF8DD59F), a * .35, .85);
  _ellipse(g, 0, 0, 3, 3, const Color(0xFFD0E7A7), a * .7);
  g.restore();
}

void _dragonfly(
  Canvas g,
  double x,
  double y,
  double s,
  double t, [
  double a = 1,
]) {
  g.save();
  g.translate(x, y);
  g.scale(s);
  g.rotate(-.12 + math.sin(_phase(t)) * .1);
  final flutter = .38 + .3 * math.sin(_phase(t, 96));
  for (final side in [-1.0, 1.0]) {
    for (var j = 0; j < 2; j++) {
      g.save();
      g.rotate(side * (.14 + j * .3));
      final p = Path()
        ..moveTo(0, j * 4.0)
        ..cubicTo(
          side * 10,
          -16 * flutter,
          side * 41,
          -17 * flutter,
          side * 30,
          0,
        )
        ..cubicTo(side * 18, 5 * flutter, side * 6, 5, 0, j * 4.0);
      g.drawPath(p, Paint()..color = _a(const Color(0xFFCDF0E2), .12 * a));
      _stroke(g, p, const Color(0xFFCBF2DC), .45 * a, .6);
      _line(g, 0, j * 4.0, side * 30, -1, const Color(0xFFC1E5D9), .2 * a, .5);
      g.restore();
    }
  }
  _stroke(
    g,
    Path()
      ..moveTo(0, -8)
      ..quadraticBezierTo(-1, 2, 0, 20),
    const Color(0xFFCECF7B),
    a,
    2,
  );
  _ellipse(g, 0, -8, 2.4, 2.1, const Color(0xFFE8EAAD), a);
  _glow(g, 0, -7, 8, const Color(0xFFD2ED97), .15 * a);
  g.restore();
}

void _lixia(Canvas g, double t) {
  _mist(g, t, const Color(0xFF69C0B3), .8, 121);
  for (var i = 0; i < 15; i++) {
    final y = 100.0 + i * 8;
    _line(
      g,
      285 + holidayRandom(i + 600) * 140,
      y,
      400 + holidayRandom(i + 640) * 145,
      y,
      const Color(0xFF82CDB2),
      .04,
      .7,
    );
  }
  _lotus(g, 485, 155, 67, .57, -.22, t, .7);
  _lotus(g, 386, 106, 53, .62, .12, t, .88);
  _lotus(g, 525, 69, 33, .65, -.3, t, .45);
  _stroke(
    g,
    Path()
      ..moveTo(453, 213)
      ..quadraticBezierTo(460, 148, 448, 78),
    const Color(0xFF72B47E),
    .65,
    1.5,
  );
  for (var i = 0; i < 5; i++) {
    _leaf(
      g,
      448.0 + (i - 2) * 2,
      83,
      24.0 - (i - 2).abs() * 3,
      5.6,
      (i - 2) * .17,
      const Color(0xFFDDACBA),
      .85,
    );
  }
  _glow(g, 448, 65, 24, const Color(0xFFDDACBA), .08);
  final dx = 303 + math.cos(_phase(t)) * 81,
      dy = 65 + math.sin(_phase(t, 2)) * 15;
  _glow(g, dx + 10, dy + 72, 26, const Color(0xFF5DB2A1), .06);
  _dragonfly(g, dx, dy, .83, t, .95);
  for (var i = 0; i < 4; i++) {
    _ripple(
      g,
      253.0 + i * 87,
      178 + holidayRandom(i + 44) * 47,
      (t / _loop * 3 + i * .27) % 1,
      const Color(0xFF74D3BC),
      .65,
    );
  }
  _motes(g, t, const Color(0xFFB4E5AF), 17, .6);
}

void _motes(Canvas g, double t, Color color, int count, double opacity) {
  for (var i = 0; i < count; i++) {
    final f = _particles[i + 54],
        p = (f.y + t / _loop * (1 + f.speed.round())) % 1;
    final x = f.x * 584 + math.sin(_phase(t) + i) * 9, y = 260 - p * 290;
    final a = math.sin(math.pi * p) * (.15 + f.r * .4) * opacity;
    if (i % 5 == 0) _glow(g, x, y, 7, color, a * .22);
    _ellipse(g, x, y, .55 + f.r * .8, .55 + f.r * .8, color, a);
  }
}

void paintHolidayGlassDate(
  Canvas g,
  HolidayScene scene,
  Offset center, {
  required double scale,
  required double seconds,
}) {
  final t = seconds % _loop;
  g.save();
  g.translate(center.dx, center.dy);
  g.scale(scale);
  g.translate(-27, -17);
  switch (scene) {
    case HolidayScene.yuandan:
      g.scale(.4);
      _newYearDateBadge(g, t);
    case HolidayScene.chuxi:
      g.scale(.4);
      _fortunePaper(g, 0, 0, .32, t);
    case HolidayScene.yuanxiao:
      g.scale(.4);
      _lotusLight(g, 0, 8, 1, t);
    case HolidayScene.laodong:
      g.scale(.4);
      _labourDateBadge(g);
    case HolidayScene.duanwu:
      g.scale(.4);
      _dragonBoat(g, -2, 2, .23, t);
    case HolidayScene.zhongqiu:
      g.scale(.4);
      _harvestMoon(g, 0, 0, 17);
    case HolidayScene.guoqing:
      g.scale(.4);
      _nationalDateBadge(g);
    case HolidayScene.qingming:
      _umbrella(g, 0, 0, 12, t);
    case HolidayScene.guyu:
      g.scale(.5);
      _sprout(g, 0, 15, .56, t, 0, 1);
      _droplet(g, -13, -14, 3.5);
    case HolidayScene.lixia:
      g.scale(.5);
      _lotus(g, 0, 0, 22, .62, -.1, t, .95);
      _dragonfly(g, 11, -14, .48, t);
    case HolidayScene.xiaoman:
      g.scale(.4);
      _wheatBadge(g, t);
    case HolidayScene.mangzhong:
      g.scale(.48);
      _sowingBadge(g, t);
    case HolidayScene.xiazhi:
      g.scale(.4);
      _sundialBadge(g, t);
    case HolidayScene.xiaoshu:
      g.scale(.4);
      _cicadaBadge(g, t);
    case HolidayScene.dashu:
      g.scale(.4);
      _fireflyBadge(g, t);
    case HolidayScene.liqiu:
      g.scale(.4);
      _autumnLeafBadge(g, t);
    case HolidayScene.chushu:
      g.scale(.4);
      _chimeBadge(g, t);
    case HolidayScene.bailu:
      g.scale(.4);
      _dewBadge(g, t);
    case HolidayScene.qiufen:
      g.scale(.4);
      _equinoxBadge(g, t);
    case HolidayScene.hanlu:
      g.scale(.4);
      _chrysanthemumBadge(g, t);
    case HolidayScene.shuangjiang:
      g.scale(.4);
      _frostedPersimmonBadge(g, t);
    case HolidayScene.lidong:
      g.scale(.4);
      _winterTeaBadge(g, t);
    case HolidayScene.xiaoxue:
      g.scale(.4);
      _snowyPineBadge(g, t);
    case HolidayScene.daxue:
      g.scale(.4);
      _deepSnowCabinBadge(g, t);
    case HolidayScene.dongzhi:
      g.scale(.4);
      _dumplingDateBadge(g, t);
    case HolidayScene.xiaohan:
      g.scale(.4);
      _wintersweetDateBadge(g, t);
    case HolidayScene.dahan:
      g.scale(.4);
      _icicleHouseDateBadge(g, t);
    default:
      break;
  }
  g.restore();
}
