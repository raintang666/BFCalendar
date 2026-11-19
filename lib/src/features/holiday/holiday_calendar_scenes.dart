import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_calendar_chunfen.dart';
import 'holiday_calendar_jingzhe.dart';
import 'holiday_calendar_rain.dart';

const _tau = math.pi * 2;

Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: holidayClamp(opacity));

void _glow(Canvas canvas, Offset center, double radius, Color color, double a) {
  if (radius <= 0 || a <= 0) return;
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(center, radius, [
        _alpha(color, a),
        _alpha(color, 0),
      ]),
  );
}

class HolidayBackdropPainter extends CustomPainter {
  HolidayBackdropPainter(this.frame);
  final HolidaySceneFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(HolidayCalendarDesign.background, BlendMode.src);
    canvas.save();
    canvas.scale(size.width / 1080, size.height / 1080);
    final cycle = switch (frame.scene) {
      HolidayScene.xiaoman ||
      HolidayScene.mangzhong ||
      HolidayScene.xiazhi ||
      HolidayScene.xiaoshu ||
      HolidayScene.dashu ||
      HolidayScene.liqiu ||
      HolidayScene.chushu ||
      HolidayScene.bailu ||
      HolidayScene.qiufen ||
      HolidayScene.hanlu ||
      HolidayScene.shuangjiang ||
      HolidayScene.lidong ||
      HolidayScene.xiaoxue ||
      HolidayScene.daxue ||
      HolidayScene.dongzhi ||
      HolidayScene.xiaohan ||
      HolidayScene.dahan ||
      HolidayScene.yuandan ||
      HolidayScene.chuxi ||
      HolidayScene.yuanxiao ||
      HolidayScene.laodong ||
      HolidayScene.duanwu ||
      HolidayScene.zhongqiu ||
      HolidayScene.guoqing => HolidayCalendarDesign.glassSceneCycleSeconds,
      _ => HolidayCalendarDesign.sceneCycleSeconds,
    };
    final p = frame.time / cycle * _tau;
    final glassLight = frame.glassLight;
    _glow(
      canvas,
      Offset(380 + 60 * math.sin(p), 300 + 40 * math.cos(p)),
      560,
      frame.tint,
      0.34 + 0.1 * frame.flash + glassLight,
    );
    _glow(
      canvas,
      Offset(760 - 50 * math.sin(p), 820 + 30 * math.cos(p * 2)),
      520,
      Color.lerp(frame.tint, const Color(0xFF3C46A0), 0.6)!,
      0.26,
    );
    _glow(
      canvas,
      const Offset(540, 216),
      300,
      frame.tint,
      0.2 + 0.14 * frame.flash + glassLight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HolidayBackdropPainter oldDelegate) =>
      oldDelegate.frame != frame;
}

class HolidayScenePainter extends CustomPainter {
  HolidayScenePainter(this.frame);
  final HolidaySceneFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    final scale = size.width / 584;
    canvas.scale(scale);
    final height = size.height / scale;
    final bounds = Rect.fromLTWH(0, 0, 584, height);
    canvas.saveLayer(bounds, Paint());
    _ambient(canvas, frame.time, frame.ambient);
    if (frame.snow > 0.01) {
      _glow(
        canvas,
        const Offset(430, 30),
        240,
        const Color(0xFF78A0FF),
        0.34 * frame.snow,
      );
      _glow(
        canvas,
        const Offset(140, 10),
        200,
        const Color(0xFFC8E1FF),
        0.2 * frame.snow,
      );
      _snow(canvas, frame.time, frame.snow, 264, 584, 1);
    }
    _fireworks(canvas, frame.time, frame.fireworks);
    _lanterns(canvas, frame.time, frame.lanterns);
    if (frame.scene == HolidayScene.lichun) _lichun(canvas, frame.time);
    if (frame.scene == HolidayScene.yushui) {
      paintHolidayRainScene(canvas, frame.time);
    }
    if (frame.scene == HolidayScene.jingzhe) {
      paintHolidayJingzheScene(canvas, frame.time);
    }
    if (frame.scene == HolidayScene.chunfen) {
      paintHolidayChunfenScene(canvas, frame.time);
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, height),
          const [
            Colors.white,
            Colors.white,
            Color(0xC7FFFFFF),
            Color(0x80FFFFFF),
            Color(0x42FFFFFF),
            Color(0x1AFFFFFF),
            Color(0x08FFFFFF),
            Color(0x00FFFFFF),
          ],
          const [0, 0.3, 0.42, 0.54, 0.66, 0.78, 0.9, 1],
        ),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HolidayScenePainter oldDelegate) =>
      oldDelegate.frame != frame;
}

void _ambient(Canvas canvas, double t, double a) {
  if (a < 0.01) return;
  _glow(
    canvas,
    const Offset(300, 40),
    260,
    HolidayCalendarDesign.ambient,
    0.22 * a,
  );
  _glow(canvas, const Offset(470, 90), 200, const Color(0xFF5A6EFF), 0.16 * a);
  for (var k = 0; k < 44; k++) {
    final u = k / 43;
    final path = Path();
    for (var x = -20.0; x <= 604; x += 12) {
      final y =
          96 +
          u * 46 * math.sin(x * 0.006 + t * 0.5 + 1) +
          34 * math.sin(x * 0.009 - t * 0.7 + u * 2.2) +
          18 * math.sin(x * 0.021 + t * 1.1 + u * 4);
      if (x == -20) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..blendMode = BlendMode.plus
        ..color = _alpha(
          Color.lerp(const Color(0xFF3CE6D2), const Color(0xFF6E78FF), u)!,
          (0.05 + 0.1 * math.sin(math.pi * u)) * a,
        ),
    );
  }
}

final _flakes = List.generate(
  110,
  (i) => (
    x: holidayRandom(i),
    phase: holidayRandom(i + 50),
    speed: 0.35 + holidayRandom(i + 90) * 0.75,
    depth: holidayRandom(i + 130),
    sway: holidayRandom(i + 170),
  ),
);

void _snow(
  Canvas canvas,
  double t,
  double a,
  double height,
  double width,
  double density,
) {
  if (a < 0.01) return;
  final tt = t - 1.9;
  for (var i = 0; i < _flakes.length; i++) {
    if (i / _flakes.length > density) continue;
    final f = _flakes[i];
    final depth = f.depth;
    final radius = depth > 0.9 ? 7 + depth * 5 : 1.2 + depth * 2.6;
    final fall = tt * (46 + f.speed * 70) * (0.6 + depth * 0.8);
    final y = ((f.phase * height + fall) % (height + 30)) - 15;
    if (!(fall > y + 15 || tt > 3.2)) continue;
    final x =
        ((f.x * width +
                math.sin(tt * (0.6 + f.sway) + i) * (10 + depth * 16) +
                tt * 8) %
            (width + 30)) -
        15;
    if (depth > 0.9) {
      _glow(
        canvas,
        Offset(x, y),
        radius * 2.2,
        const Color(0xFFEBF4FF),
        0.16 * a,
      );
    } else {
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = _alpha(const Color(0xFFF0F7FF), (0.35 + depth * 0.6) * a),
      );
    }
  }
}

const _fireworkPalette = [
  Color(0xFFFFC45C),
  Color(0xFFFF6E96),
  Color(0xFF6EDCFF),
  Color(0xFFFFF4DC),
  Color(0xFFBE96FF),
  Color(0xFFFF9646),
];
const _burstX = [0.72, 0.3, 0.52, 0.14, 0.86, 0.42, 0.64, 0.24];
final _bursts = List.generate(
  8,
  (k) => (
    time: 4.9 + 0.36 + k * 0.36,
    x: _burstX[k] * 584,
    y: 64 + holidayRandom(k + 17) * 64,
    color: _fireworkPalette[k % _fireworkPalette.length],
    count: 40 + ((k * 7) % 12),
    power: 0.8 + holidayRandom(k + 71) * 0.5,
  ),
);

void _fireworks(Canvas canvas, double t, double a) {
  if (a < 0.01) return;
  _glow(canvas, const Offset(292, 260), 300, const Color(0xFF3C2878), 0.25 * a);
  for (var k = 0; k < _bursts.length; k++) {
    final b = _bursts[k];
    final d = t - b.time;
    if (d < 0 && d > -0.42) {
      final u = 1 + d / 0.42;
      final y = holidayLerp(274, b.y, holidayQuintOut(u));
      final x = b.x + math.sin(u * 9 + k) * 3;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 26 * (1 - u) + 6),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..color = _alpha(const Color(0xFFFFECC8), 0.8 * a),
      );
      _glow(canvas, Offset(x, y), 10, const Color(0xFFFFECC8), 0.7 * a);
    }
    if (d < 0 || d >= 1.7) continue;
    final life = d / 1.7;
    _glow(
      canvas,
      Offset(b.x, b.y),
      180 * holidayQuintOut(d / 0.3),
      b.color,
      0.4 * (1 - life) * a * math.exp(-d * 2),
    );
    for (var i = 0; i < b.count; i++) {
      final angle = i / b.count * _tau + holidayRandom(k * 31 + i) * 0.25;
      final speed =
          (170 + holidayRandom(k * 53 + i) * 150) *
          b.power *
          (i % 3 != 0 ? 1 : 0.55);
      const drag = 2.6;
      final s = (1 - math.exp(-drag * d)) / drag;
      final x = b.x + math.cos(angle) * speed * s;
      final y = b.y + math.sin(angle) * speed * s + 26 * d * d;
      final flicker = 0.6 + 0.4 * math.sin(d * 38 + i * 2.3);
      final opacity = math.pow(1 - life, 1.4) * flicker * a;
      final previous = math.max(0.0, d - 0.15);
      final s0 = (1 - math.exp(-drag * previous)) / drag;
      final start = Offset(
        b.x + math.cos(angle) * speed * s0,
        b.y + math.sin(angle) * speed * s0 + 26 * previous * previous,
      );
      canvas.drawLine(
        start,
        Offset(x, y),
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..color = _alpha(
            Color.lerp(Colors.white, b.color, holidayClamp(d * 2.2))!,
            opacity,
          ),
      );
      if (i % 4 == 0) _glow(canvas, Offset(x, y), 7, b.color, opacity * 0.7);
    }
  }
}

const _lanternOrder = [5, 0, 8, 3, 10, 1, 6, 9, 2, 7, 4];
final _paperLanterns = List.generate(
  11,
  (i) => (
    x: (_lanternOrder[i] + 0.5 + (holidayRandom(i + 3) - 0.5) * 0.6) / 11,
    depth: holidayRandom(i + 23),
    speed: 14 + holidayRandom(i + 43) * 22,
    phase: holidayRandom(i + 63),
  ),
)..sort((a, b) => a.depth.compareTo(b.depth));

void _lanterns(Canvas canvas, double t, double a) {
  if (a < 0.01) return;
  final tt = t - 9.2;
  _glow(canvas, const Offset(292, 300), 330, const Color(0xFFFF461E), 0.28 * a);
  _glow(canvas, const Offset(120, 220), 180, const Color(0xFFFF9628), 0.14 * a);
  for (var i = 0; i < _paperLanterns.length; i++) {
    final l = _paperLanterns[i];
    final s = 0.5 + l.depth * 1.1;
    final w = 22 * s;
    final h = 28 * s;
    final rise =
        l.speed * tt * (0.6 + l.depth) +
        (70 + l.phase * 150) * (1 - math.exp(-tt * 1.6));
    final y = 294 + l.phase * 60 - rise;
    final x = l.x * 584 + math.sin(tt * 0.8 + i * 1.7) * 10 * s;
    if (y < -40) continue;
    final opacity = a * (0.55 + 0.45 * l.depth) * holidayClamp((284 - y) / 40);
    _glow(
      canvas,
      Offset(x, y),
      h * 2.4,
      const Color(0xFFFF7828),
      0.3 * opacity,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Radius.circular(w * 0.42),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y - h / 2),
          Offset(0, y + h / 2),
          [
            _alpha(const Color(0xFFE6321E), opacity),
            _alpha(const Color(0xFFFF7828), opacity),
            _alpha(const Color(0xFFFFD678), opacity),
          ],
          [0, 0.55, 1],
        ),
    );
    _glow(
      canvas,
      Offset(x, y + h * 0.18),
      w * 0.7,
      const Color(0xFFFFF0BE),
      0.9 * opacity * (0.8 + 0.2 * math.sin(tt * 5 + i)),
    );
    final rim = Paint()..color = _alpha(const Color(0xFF78140E), opacity);
    canvas.drawRect(
      Rect.fromLTWH(x - w * 0.26, y - h / 2 - 2 * s, w * 0.52, 3 * s),
      rim,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - w * 0.26, y + h / 2 - s, w * 0.52, 3 * s),
      rim,
    );
    canvas.drawLine(
      Offset(x, y + h / 2 + 2 * s),
      Offset(x + math.sin(tt * 2 + i) * 2, y + h / 2 + 12 * s),
      Paint()
        ..strokeWidth = 1
        ..color = _alpha(const Color(0xFFFFC878), 0.7 * opacity),
    );
  }
  for (var i = 0; i < 26; i++) {
    final phase =
        (tt * (0.12 + holidayRandom(i + 300) * 0.14) + holidayRandom(i + 330)) %
        1;
    canvas.drawCircle(
      Offset(
        holidayRandom(i + 360) * 584 + math.sin(tt + i) * 8,
        264 - phase * 264,
      ),
      1.2,
      Paint()
        ..color = _alpha(
          const Color(0xFFFFC878),
          math.sin(math.pi * phase) * 0.7 * a,
        ),
    );
  }
}

void _springLeaf(
  Canvas canvas,
  Offset origin,
  double angle,
  double length,
  double width,
  double opacity, {
  double growth = 1,
  bool warm = false,
}) {
  if (growth <= 0) return;
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.rotate(angle);
  canvas.scale(growth);
  final shape = Path()
    ..moveTo(0, 0)
    ..cubicTo(-width * 0.72, -length * 0.24, -width, -length * 0.66, 0, -length)
    ..cubicTo(width * 0.85, -length * 0.68, width * 0.7, -length * 0.22, 0, 0);
  canvas.drawPath(
    shape,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-width, 0),
        Offset(width, -length),
        [
          _alpha(
            warm ? const Color(0xFF6B8B43) : const Color(0xFF3C8655),
            opacity,
          ),
          _alpha(
            warm ? const Color(0xFFC7D487) : const Color(0xFF98C875),
            opacity,
          ),
          _alpha(
            warm ? const Color(0xFFE5E8A6) : const Color(0xFFD4E9AC),
            opacity,
          ),
        ],
        const [0, 0.5, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, -1)
      ..quadraticBezierTo(width * 0.07, -length * 0.4, 0, -length * 0.9),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = _alpha(const Color(0xFFE2F6B8), 0.42 * opacity),
  );
  final veins = Path();
  for (var i = 1; i < 4; i++) {
    final y = -length * (0.14 + i * 0.14);
    final wing = width * math.sin((0.14 + i * 0.14) * math.pi) * 0.65;
    veins
      ..moveTo(0, y)
      ..lineTo(-wing, y - length * 0.14)
      ..moveTo(0, y)
      ..lineTo(wing, y - length * 0.14);
  }
  canvas.drawPath(
    veins,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = _alpha(const Color(0xFFE2F6B8), 0.17 * opacity),
  );
  canvas.restore();
}

Offset _bezierPoint(List<Offset> points, double u) {
  final v = 1 - u;
  return points[0] * (v * v * v) +
      points[1] * (3 * v * v * u) +
      points[2] * (3 * v * u * u) +
      points[3] * (u * u * u);
}

void _springBranch(
  Canvas canvas,
  List<Offset> points,
  double t,
  double side, [
  double delay = 0,
]) {
  final growth = holidayQuintOut((t - delay) / 2.3);
  if (growth <= 0) return;
  canvas.save();
  canvas.translate(points[0].dx, points[0].dy);
  canvas.rotate(math.sin(t * 0.85 + side) * 0.026);
  canvas.translate(-points[0].dx, -points[0].dy);
  final start = _bezierPoint(points, 0);
  final branch = Path()..moveTo(start.dx, start.dy);
  for (var u = 0.02; u < growth; u += 0.02) {
    final point = _bezierPoint(points, u);
    branch.lineTo(point.dx, point.dy);
  }
  final tip = _bezierPoint(points, growth);
  branch.lineTo(tip.dx, tip.dy);
  canvas.drawPath(
    branch,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        const Offset(0, 250),
        const Offset(0, 40),
        [
          _alpha(const Color(0xFF416949), 0.06),
          _alpha(const Color(0xFF6D9E63), 0.6),
          _alpha(const Color(0xFFADCC81), 0.92),
        ],
        const [0, 0.5, 1],
      ),
  );
  for (var i = 0; i < 7; i++) {
    final u = 0.24 + i * 0.115;
    if (u > growth) continue;
    final point = _bezierPoint(points, u);
    final next = _bezierPoint(points, math.min(1.0, u + 0.03));
    final direction = math.atan2(next.dx - point.dx, -(next.dy - point.dy));
    final unfurl = holidayQuintOut((t - delay - 0.25 - u * 1.4) / 1.2);
    final length = 22.0 + (i % 3) * 5;
    final spread = (i.isOdd ? 1 : -1) * (0.72 + math.sin(t * 0.8 + i) * 0.07);
    _springLeaf(
      canvas,
      point,
      direction + spread,
      length,
      9.0 + (i % 3) * 2,
      0.92,
      growth: unfurl,
      warm: i % 3 == 0,
    );
    if (i.isEven) {
      _springLeaf(
        canvas,
        point,
        direction - spread * 0.78,
        length * 0.76,
        8,
        0.72,
        growth: unfurl,
      );
    }
    if (unfurl > 0 && unfurl < 0.96) {
      _glow(canvas, point, 15, const Color(0xFFBBE093), 0.12 * (1 - unfurl));
    }
  }
  _springLeaf(
    canvas,
    tip,
    side * 0.25,
    27,
    9,
    0.9,
    growth: holidayQuintOut((t - delay - 1.65) / 1.25),
  );
  canvas.restore();
}

final _driftingSpringLeaves = List.generate(
  12,
  (i) => (
    phase: holidayRandom(i + 700),
    height: holidayRandom(i + 720),
    depth: holidayRandom(i + 740),
  ),
);

void _lichun(Canvas canvas, double t) {
  _glow(canvas, const Offset(462, 34), 230, const Color(0xFFF6E4A6), 0.2);
  _glow(canvas, const Offset(105, 160), 250, const Color(0xFF6BBD86), 0.12);
  _glow(canvas, const Offset(294, 30), 250, const Color(0xFFB3D598), 0.1);
  for (var k = 0; k < 4; k++) {
    final x = 430 + k * 35 + math.sin(t * 0.17 + k) * 9;
    canvas.drawPath(
      Path()
        ..moveTo(x, -30)
        ..lineTo(x + 21, -30)
        ..lineTo(x - 100, 285)
        ..lineTo(x - 175, 285)
        ..close(),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(Offset(x, -30), Offset(x - 150, 270), [
          _alpha(const Color(0xFFECE8AC), 0.035),
          _alpha(const Color(0xFFECE8AC), 0),
        ]),
    );
  }
  _springBranch(
    canvas,
    const [Offset(47, 287), Offset(98, 235), Offset(106, 120), Offset(189, 39)],
    t,
    -1,
  );
  _springBranch(
    canvas,
    const [
      Offset(570, 281),
      Offset(519, 221),
      Offset(524, 133),
      Offset(437, 71),
    ],
    t,
    1,
    0.18,
  );
  _springBranch(
    canvas,
    const [
      Offset(88, 285),
      Offset(126, 249),
      Offset(181, 233),
      Offset(220, 184),
    ],
    t,
    -0.5,
    0.55,
  );
  for (var i = 0; i < _driftingSpringLeaves.length; i++) {
    final leaf = _driftingSpringLeaves[i];
    final cycle = (t * (0.045 + leaf.depth * 0.018) + leaf.phase) % 1;
    final point = Offset(
      cycle * 684 - 50,
      25 + leaf.height * 157 + math.sin(t * 0.56 + i * 1.7) * 12,
    );
    final length = 9 + leaf.depth * 13;
    _springLeaf(
      canvas,
      point,
      -0.8 + math.sin(t * 0.64 + i) * 0.65,
      length,
      length * 0.33,
      math.sin(math.pi * cycle) * (0.25 + leaf.depth * 0.32),
      warm: i % 4 == 0,
    );
  }
  for (var i = 0; i < 18; i++) {
    final cycle =
        (t * (0.025 + holidayRandom(i + 830) * 0.018) +
            holidayRandom(i + 850)) %
        1;
    final point = Offset(
      cycle * 584,
      20 + holidayRandom(i + 870) * 200 + math.sin(t * 0.45 + i) * 9,
    );
    final opacity =
        math.sin(math.pi * cycle) * (0.1 + holidayRandom(i + 890) * 0.2);
    if (i % 4 == 0) {
      _glow(canvas, point, 5, const Color(0xFFE2EBB1), opacity * 0.36);
    }
    canvas.drawCircle(
      point,
      0.65 + holidayRandom(i + 910),
      Paint()..color = _alpha(const Color(0xFFD3E4AB), opacity),
    );
  }
}

/// Uses the confirmed webpage's 584px coordinates, including the leftward nudge.
void paintHolidaySpringBud(
  Canvas canvas,
  Offset origin, {
  required double scale,
  required double seconds,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(scale);
  final growth = holidayQuintOut(seconds / 1.5);
  final sway = math.sin(seconds * 0.9) * 0.08;
  _springLeaf(
    canvas,
    const Offset(-18, -5),
    -0.68 + sway,
    22,
    8,
    0.95,
    growth: growth,
  );
  _springLeaf(
    canvas,
    const Offset(-17, -6),
    0.65 + sway,
    17,
    7,
    0.85,
    growth: growth,
  );
  canvas.restore();
}

/// A small paper lantern above the date, clear of the number and lunar label.
void paintHolidayLanternBadge(Canvas canvas, Offset origin, double seconds) {
  final appear = holidayQuintOut(seconds / 0.55);
  if (appear <= 0) return;
  canvas.save();
  canvas.translate(origin.dx, origin.dy - 7);
  canvas.rotate(math.sin(seconds * 1.5) * 0.1);
  canvas.translate(0, 7 + math.sin(seconds * 1.7) * 0.6);
  canvas.scale(0.7 + 0.3 * appear);
  _glow(canvas, const Offset(0, 2), 11, const Color(0xFFFF8A3C), 0.24 * appear);
  canvas.drawLine(
    const Offset(0, -8),
    const Offset(0, -6),
    Paint()
      ..strokeWidth = 0.7
      ..color = _alpha(const Color(0xFFFFD995), appear),
  );
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-5, -6, 10, 12),
    const Radius.circular(3.6),
  );
  canvas.drawRRect(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -6),
        const Offset(0, 6),
        [
          _alpha(const Color(0xFFFF4E2F), appear),
          _alpha(const Color(0xFFFF8C39), appear),
          _alpha(const Color(0xFFFFD48A), appear),
        ],
        const [0, 0.55, 1],
      ),
  );
  final ribs = Path()
    ..moveTo(-1.5, -5.5)
    ..cubicTo(-3.4, -2, -3.4, 2, -1.5, 5.5)
    ..moveTo(1.5, -5.5)
    ..cubicTo(3.4, -2, 3.4, 2, 1.5, 5.5);
  canvas.drawPath(
    ribs,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = _alpha(const Color(0xFFFFE0A0), 0.45 * appear),
  );
  _glow(
    canvas,
    const Offset(0, 3),
    3.5,
    const Color(0xFFFFF0BE),
    (0.55 + 0.1 * math.sin(seconds * 4)) * appear,
  );
  canvas.drawRect(
    const Rect.fromLTWH(-3.3, -6.7, 6.6, 1.4),
    Paint()..color = _alpha(const Color(0xFFB6362A), appear),
  );
  canvas.drawRect(
    const Rect.fromLTWH(-3, 5.3, 6, 1.3),
    Paint()..color = _alpha(const Color(0xFFFFAE55), appear),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, 7)
      ..quadraticBezierTo(-0.8, 9, math.sin(seconds * 2) * 1.3, 12),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..strokeCap = StrokeCap.round
      ..color = _alpha(const Color(0xFFFFD995), appear),
  );
  canvas.restore();
}

/// The confirmed webpage's two gold blooms, with an empty pause between cycles.
void paintHolidayFireworkBadge(Canvas canvas, Offset origin, double seconds) {
  final phase = seconds % HolidayCalendarDesign.dateFireworkCycleSeconds;
  if (phase <= 0 || phase >= HolidayCalendarDesign.dateFireworkVisibleSeconds) {
    return;
  }
  const gold = HolidayCalendarDesign.newYear;
  const champagne = Color(0xFFFFEBBA);
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  if (phase < 0.44) {
    final u = holidayClamp(phase / 0.44);
    final rise = 1 - math.pow(1 - u, 3).toDouble();
    final head = Offset(-0.7 + math.sin(u * math.pi) * 1.1, 15 * (1 - rise));
    final tail = math.max(0.0, u - 0.28);
    final tailY = 15 * math.pow(1 - tail, 3).toDouble();
    final intensity = math.sin(math.pi * u);
    canvas.drawPath(
      Path()
        ..moveTo(head.dx, head.dy)
        ..quadraticBezierTo(-1, head.dy + 3, -0.7, tailY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(head, Offset(head.dx, tailY), [
          _alpha(champagne, intensity * 0.95),
          _alpha(gold, 0),
        ]),
    );
    _glow(canvas, head, 2.2, champagne, intensity * 0.35);
  }
  for (final bloom in const [
    (
      delay: 0.39,
      origin: Offset.zero,
      count: 18,
      radius: 10.0,
      duration: 1.55,
      seed: 17,
    ),
    (
      delay: 0.72,
      origin: Offset(11, -4),
      count: 11,
      radius: 5.6,
      duration: 1.25,
      seed: 83,
    ),
  ]) {
    final age = phase - bloom.delay;
    if (age <= 0 || age >= bloom.duration) continue;
    final life = age / bloom.duration;
    final fade = math.min(1.0, age / 0.07) * math.pow(1 - life, 0.7);
    _glow(
      canvas,
      bloom.origin,
      8 * holidayQuintOut(age / 0.18),
      gold,
      math.exp(-age * 7) * 0.24,
    );
    for (var i = 0; i < bloom.count; i++) {
      final angle =
          i / bloom.count * _tau -
          math.pi / 2 +
          (holidayRandom(i + bloom.seed) - 0.5) * 0.13;
      final extent =
          bloom.radius * (0.76 + holidayRandom(i + bloom.seed + 23) * 0.24);
      Offset pointAt(double t) {
        final spread =
            (1 - math.exp(-3.2 * t)) / (1 - math.exp(-3.2 * bloom.duration));
        final curl = math.sin(i * 1.7 + bloom.seed) * t * 0.24;
        return bloom.origin +
            Offset(
              math.cos(angle + curl) * extent * spread,
              math.sin(angle + curl) * extent * spread * 0.9 + 1.8 * t * t,
            );
      }

      final trail = 0.34 + life * 0.2;
      final head = pointAt(age);
      final tail = pointAt(math.max(0.0, age - trail));
      final mid = pointAt(math.max(0.0, age - trail / 2));
      final shimmer = 0.8 + 0.2 * math.sin(age * 19 + i * 2.1);
      final ink = Color.lerp(gold, champagne, 0.55 + 0.45 * life)!;
      canvas.drawPath(
        Path()
          ..moveTo(tail.dx, tail.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, head.dx, head.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.62 * (1 - 0.3 * life)
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            tail,
            head + const Offset(0.001, 0),
            [
              _alpha(gold, fade * 0.08),
              _alpha(ink, fade * shimmer * 0.6),
              _alpha(champagne, fade * shimmer),
            ],
            const [0, 0.6, 1],
          ),
      );
      canvas.drawCircle(
        head,
        0.48 * (1 - 0.35 * life),
        Paint()..color = _alpha(champagne, fade * shimmer),
      );
      if (i % 4 == 0 && age > 0.38) {
        final ember = pointAt(math.max(0.0, age - 0.25));
        canvas.drawCircle(
          ember + Offset(0, age * 1.3),
          0.3,
          Paint()
            ..color = _alpha(
              gold,
              fade *
                  0.5 *
                  math.sin(holidayClamp((age - 0.38) / 0.65) * math.pi),
            ),
        );
      }
    }
  }
  canvas.restore();
}

/// Snow remains decorative; the SDK owns the selected cell and its hit target.
void paintHolidaySnowCap(Canvas canvas, Offset center, double growth) {
  if (growth <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(0.65);
  _snowCap(canvas, Offset.zero, growth, 1);
  canvas.restore();
}

const _lumps = [
  (-1.0, 0.34),
  (-0.72, 0.62),
  (-0.42, 0.86),
  (-0.1, 1.0),
  (0.22, 0.94),
  (0.5, 0.74),
  (0.76, 0.5),
  (1.0, 0.3),
];

void _snowCap(Canvas canvas, Offset center, double cap, double alpha) {
  final angle = 1.02 * (0.3 + 0.7 * cap);
  final growth = 0.4 + 0.6 * cap;
  final opacity = alpha * holidayClamp(cap * 6);
  final path = Path();
  for (final (u, k) in _lumps) {
    final a = -math.pi / 2 + u * angle;
    final radius = (3 + 4.6 * k) * growth;
    final r = 24 + radius * 0.5 - 1.4;
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(math.cos(a) * r, math.sin(a) * r),
        radius: radius,
      ),
    );
  }
  path.addPath(
    Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: 24 + 2.2 * growth),
        -math.pi / 2 - angle,
        angle * 2,
        true,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: 23 - 3 * growth),
        -math.pi / 2 + angle,
        -angle * 2,
        false,
      )
      ..close(),
    Offset.zero,
  );
  canvas.drawPath(
    path.shift(const Offset(0, 3)),
    Paint()
      ..color = _alpha(const Color(0xFF14286E), 0.45 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        center - const Offset(0, 34),
        center - const Offset(0, 14),
        [
          _alpha(Colors.white, opacity),
          _alpha(const Color(0xFFEEF4FF), opacity),
          _alpha(const Color(0xFFC9DAFB), opacity),
        ],
        [0, 0.6, 1],
      ),
  );
}
