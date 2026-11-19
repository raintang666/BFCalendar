import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';

Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: holidayClamp(opacity));

void _glow(Canvas canvas, Offset center, double radius, Color color, double a) {
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

void _ladybug(
  Canvas canvas,
  Offset position, {
  required double angle,
  required double scale,
  required double seconds,
  required double alpha,
}) {
  if (alpha <= 0) return;
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  canvas.saveLayer(
    const Rect.fromLTWH(-16, -18, 32, 34),
    Paint()..color = _alpha(Colors.white, alpha),
  );
  canvas.drawOval(
    const Rect.fromLTWH(-10, -6, 20, 18),
    Paint()..color = const Color(0x3D06110C),
  );
  final legs = Paint()
    ..color = const Color(0xFF273931)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  for (final side in [-1, 1]) {
    for (var i = 0; i < 3; i++) {
      final y = -4.0 + i * 4;
      final step = math.sin(seconds * 8 + i * 2.1 + side) * 2;
      canvas.drawPath(
        Path()
          ..moveTo(side * 6, y)
          ..lineTo(side * 10, y - 1 + step)
          ..lineTo(side * 12, y + 2 + step),
        legs,
      );
    }
  }
  canvas.drawOval(
    const Rect.fromLTWH(-4.5, -13, 9, 8),
    Paint()..color = const Color(0xFF26352F),
  );
  legs.strokeWidth = 0.85;
  for (final side in [-1, 1]) {
    canvas.drawPath(
      Path()
        ..moveTo(side * 2, -11)
        ..quadraticBezierTo(side * 3, -14, side * 5, -14),
      legs,
    );
  }
  canvas.drawOval(
    const Rect.fromLTWH(-7.8, -10, 15.6, 20),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-7, -8),
        const Offset(8, 9),
        const [
          Color(0xFFF4AD78),
          Color(0xFFDD795B),
          Color(0xFFA7403A),
          Color(0xFF632D2D),
        ],
        const [0, 0.25, 0.7, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, -9.7)
      ..quadraticBezierTo(0.6, 0, 0, 9.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xCC3C231F),
  );
  for (final (x, y, radius) in const [
    (-3.0, -4.0, 1.7),
    (3.0, -4.0, 1.7),
    (-3.6, 1.0, 1.8),
    (3.6, 1.0, 1.8),
    (-2.6, 5.5, 1.4),
    (2.6, 5.5, 1.4),
  ]) {
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = const Color(0xFF49302D),
    );
  }
  canvas.save();
  canvas.translate(-3.1, -4.5);
  canvas.rotate(-0.35);
  canvas.drawOval(
    const Rect.fromLTWH(-1.3, -2.5, 2.6, 5),
    Paint()..color = const Color(0x6BFFE0B2),
  );
  canvas.restore();
  canvas.restore();
  canvas.restore();
}

final _meadowBlades = List.generate(
  18,
  (i) => (
    root: 22 + holidayRandom(i + 1500) * 535,
    height: 57 + holidayRandom(i + 1540) * 123,
    lean: (holidayRandom(i + 1580) - 0.5) * 82,
    width: 2 + holidayRandom(i + 1620) * 4,
    phase: holidayRandom(i + 1660) * math.pi * 2,
    depth: holidayRandom(i + 1700),
  ),
);

Offset _beetleTrail(double t) {
  final v = 1 - t;
  return const Offset(349, 186) * (v * v * v) +
      const Offset(376, 143) * (3 * v * v * t) +
      const Offset(421, 149) * (3 * v * t * t) +
      const Offset(464, 164) * (t * t * t);
}

/// Canvas coordinates match the approved webpage's 584-wide scene.
void paintHolidayJingzheScene(Canvas canvas, double seconds) {
  final t = seconds;
  final pulse = holidayThunderPulse(t);
  _glow(canvas, const Offset(208, 180), 265, const Color(0xFF729D6E), 0.13);
  _glow(
    canvas,
    const Offset(440, 40),
    240,
    const Color(0xFF8E96B0),
    0.14 + pulse * 0.04,
  );
  _glow(canvas, const Offset(320, 229), 225, const Color(0xFFC0B47B), 0.07);
  for (var i = 0; i < 5; i++) {
    final center = Offset(
      319 + i * 47 + math.sin(t * 0.09 + i) * 7,
      20.0 + i % 2 * 11,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, 22.0 + i % 2 * 10),
        width: 184,
        height: 76,
      ),
      Paint()
        ..shader = ui.Gradient.radial(center, 92, [
          _alpha(const Color(0xFF97A3B9), 0.055 + pulse * 0.035),
          const Color(0x00717E94),
        ]),
    );
  }
  if (pulse > 0) {
    const bolts = [
      [
        Offset(446, 33),
        Offset(430, 54),
        Offset(440, 61),
        Offset(415, 86),
        Offset(424, 91),
        Offset(397, 121),
      ],
      [Offset(434, 58), Offset(458, 72), Offset(452, 86)],
      [Offset(416, 86), Offset(395, 92), Offset(386, 108)],
    ];
    for (var layer = 0; layer < 2; layer++) {
      for (var i = 0; i < bolts.length; i++) {
        canvas.drawPath(
          Path()..addPolygon(bolts[i], false),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = layer == 0 ? 8 : (i == 0 ? 1.35 : 0.8)
            ..color = _alpha(
              const Color(0xFFD6DBED),
              pulse * (layer == 0 ? 0.08 : (i == 0 ? 0.74 : 0.4)),
            ),
        );
      }
    }
    _glow(
      canvas,
      const Offset(432, 55),
      113,
      const Color(0xFFBEC6E2),
      pulse * 0.105,
    );
  }
  for (var i = 0; i < _meadowBlades.length; i++) {
    final p = _meadowBlades[i];
    final sway = math.sin(t * 0.82 + p.phase) * (4 + p.depth * 4);
    final growth = holidayQuintOut(t / (1.2 + p.depth * 0.5));
    final rootY = 270.0 + i % 3 * 9;
    final tip = Offset(p.root + p.lean + sway, rootY - p.height * growth);
    canvas.drawPath(
      Path()
        ..moveTo(p.root - p.width / 2, rootY)
        ..quadraticBezierTo(
          p.root + p.lean * 0.1,
          rootY - p.height * 0.65,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          p.root + p.lean * 0.23 + p.width,
          rootY - p.height * 0.58,
          p.root + p.width / 2,
          rootY,
        ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.root, rootY),
          tip,
          [
            const Color(0x00406140),
            _alpha(const Color(0xFF658F57), 0.2 + p.depth * 0.25),
            _alpha(const Color(0xFFAABC73), 0.4 + p.depth * 0.36),
          ],
          const [0, 0.5, 1],
        ),
    );
  }
  canvas.save();
  canvas.translate(0, math.sin(t * 0.65) * 3);
  canvas.drawPath(
    Path()
      ..moveTo(331, 251)
      ..cubicTo(334, 195, 376, 134, 464, 164)
      ..cubicTo(410, 156, 362, 175, 331, 251),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(343, 231),
        const Offset(464, 155),
        const [Color(0x0D426A46), Color(0xFF4C7B50), Color(0xFFA6BC75)],
        const [0, 0.55, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(335, 240)
      ..cubicTo(354, 183, 401, 151, 461, 164),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = const Color(0x70C3D58F),
  );
  final u = (t * 0.052 + 0.14) % 1;
  final p = _beetleTrail(u);
  final q = _beetleTrail(math.min(1, u + 0.008));
  final appear =
      holidayQuintOut(u / 0.1) *
      (1 - holidayQuintOut((u - 0.88) / 0.12)) *
      holidayQuintOut(t / 0.7);
  _ladybug(
    canvas,
    p - const Offset(0, 8),
    angle: math.atan2(q.dx - p.dx, -(q.dy - p.dy)),
    scale: 1.45,
    seconds: t,
    alpha: appear,
  );
  for (final dew in const [Offset(395, 164), Offset(436, 163)]) {
    canvas.drawPath(
      Path()
        ..moveTo(dew.dx, dew.dy - 2.5)
        ..cubicTo(
          dew.dx - 3,
          dew.dy + 2,
          dew.dx + 3,
          dew.dy + 2,
          dew.dx,
          dew.dy - 2.5,
        ),
      Paint()..color = const Color(0x6EB9DACC),
    );
  }
  canvas.restore();
  for (var i = 0; i < 11; i++) {
    final u =
        (t * (0.018 + holidayRandom(i + 1740) * 0.012) +
            holidayRandom(i + 1780)) %
        1;
    canvas.drawCircle(
      Offset(
        44 + u * 490,
        85 + holidayRandom(i + 1820) * 130 + math.sin(t * 0.55 + i) * 7,
      ),
      0.6 + holidayRandom(i + 1860) * 0.55,
      Paint()
        ..color = _alpha(const Color(0xFFC6D399), math.sin(math.pi * u) * 0.22),
    );
  }
}

/// Small waking ladybug sits to the left of the number, leaving text readable.
void paintHolidayJingzheDate(
  Canvas canvas,
  Offset center, {
  required double scale,
  required double seconds,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  _ladybug(
    canvas,
    Offset(
      -24 + math.sin(seconds * 0.55) * 2,
      -12 + math.sin(seconds * 0.7) * 1.4,
    ),
    angle: 0.35,
    scale: 0.74,
    seconds: seconds,
    alpha: 0.95 * holidayQuintOut(seconds / 0.65),
  );
  canvas.restore();
}
