import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';

const _tau = math.pi * 2;
const _blooms = [
  (Offset(354, 30), 15.0, -0.42, 0.69, 21),
  (Offset(414, 86), 17.0, 0.28, 0.83, 47),
  (Offset(502, 23), 16.0, -0.2, 0.65, 83),
  (Offset(521, 51), 10.0, 0.65, 0.66, 97),
  (Offset(535, 142), 13.0, -0.7, 0.73, 113),
];

Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: holidayClamp(opacity));

double _breeze(double t) =>
    math.sin(t * 0.67) * 0.009 + math.sin(t * 1.13 + 0.8) * 0.004;

void _oval(
  Canvas canvas,
  Offset center,
  double rx,
  double ry,
  double angle,
  Paint paint,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.drawOval(Rect.fromLTRB(-rx, -ry, rx, ry), paint);
  canvas.restore();
}

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

void _blossom(
  Canvas canvas,
  Offset center,
  double radius,
  double turn, {
  required int seed,
  required double opening,
  required double alpha,
  required double tilt,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(turn);
  canvas.scale(1, tilt);
  // Unequal overlapping petals retain the approved webpage's natural cup.
  for (final i in const [3, 4, 0, 1, 2]) {
    final angle = i * _tau / 5 + (holidayRandom(seed + i) - 0.5) * 0.24;
    final length =
        radius * (0.86 + holidayRandom(seed + 20 + i) * 0.26) * opening;
    final breadth = 0.48 + holidayRandom(seed + 40 + i) * 0.13;
    canvas.save();
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(-1, 2)
        ..cubicTo(
          -length * breadth,
          -length * 0.11,
          -length * (breadth + 0.12),
          -length * 0.74,
          -length * 0.22,
          -length * 0.97,
        )
        ..quadraticBezierTo(-length * 0.08, -length * 1.06, 0, -length * 0.88)
        ..quadraticBezierTo(
          length * 0.12,
          -length * 1.02,
          length * 0.3,
          -length * 0.94,
        )
        ..cubicTo(
          length * 0.69,
          -length * 0.68,
          length * 0.44,
          -length * 0.15,
          1,
          2,
        ),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 2),
          Offset(0, -length),
          [
            _alpha(const Color(0xFFAE5E72), alpha),
            _alpha(const Color(0xFFD29AA5), alpha),
            _alpha(const Color(0xFFE7C7C8), alpha),
            _alpha(const Color(0xFFF2E0D9), alpha),
          ],
          const [0, 0.29, 0.75, 1],
        ),
    );
    final veins = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = _alpha(const Color(0xFF77394B), 0.14 * alpha);
    for (final v in const [-0.22, 0.0, 0.23]) {
      canvas.drawPath(
        Path()
          ..moveTo(0, -1)
          ..quadraticBezierTo(
            length * v * 0.8,
            -length * 0.36,
            length * v,
            -length * 0.76,
          ),
        veins,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-length * 0.2, -length * 0.95)
        ..quadraticBezierTo(
          -length * 0.47,
          -length * 0.8,
          -length * 0.43,
          -length * 0.57,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = _alpha(const Color(0xFFFFF2DE), 0.28 * alpha),
    );
    canvas.restore();
  }
  canvas.drawCircle(
    Offset.zero,
    radius * 0.3,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        radius * 0.3,
        [
          _alpha(const Color(0xFF824151), alpha),
          _alpha(const Color(0xFFAF6376), alpha),
          const Color(0x00AF6376),
        ],
        const [0, 0.45, 1],
      ),
  );
  final stamen = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.45
    ..color = _alpha(const Color(0xFFC58F8E), 0.78 * alpha);
  for (var i = 0; i < 17; i++) {
    final angle = i * 2.4 + seed;
    final length = radius * (0.2 + holidayRandom(seed + 80 + i) * 0.22);
    final point = Offset(math.cos(angle), math.sin(angle)) * length;
    canvas.drawPath(
      Path()
        ..moveTo(0, 1)
        ..quadraticBezierTo(
          point.dx * 0.7,
          point.dy * 0.25,
          point.dx,
          point.dy,
        ),
      stamen,
    );
    _oval(
      canvas,
      point,
      0.7,
      0.48,
      angle,
      Paint()
        ..color = _alpha(
          i % 3 != 0 ? const Color(0xFFD4B997) : const Color(0xFFEEE0BB),
          alpha,
        ),
    );
  }
  canvas.restore();
}

void _bud(Canvas canvas, Offset position, double angle, double size) {
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(angle);
  canvas.drawPath(
    Path()
      ..moveTo(-2, 3)
      ..lineTo(-4, -1)
      ..lineTo(0, 0)
      ..lineTo(3, -2)
      ..lineTo(2, 4)
      ..close(),
    Paint()..color = const Color(0xFF6A7160),
  );
  _oval(
    canvas,
    Offset(0, -size * 0.6),
    size * 0.64,
    size,
    -0.15,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-size, 0),
        Offset(size, -size * 2),
        const [Color(0xFF884C5C), Color(0xFFC48E9C), Color(0xFFE3BEC1)],
        const [0, 0.7, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, 2)
      ..quadraticBezierTo(-size * 0.2, -size * 0.6, size * 0.15, -size * 1.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0x4D5B2E37),
  );
  canvas.restore();
}

void _petal(
  Canvas canvas,
  Offset center,
  double angle,
  double size,
  double tumble,
  double alpha,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(
    0.14 + 0.86 * math.cos(tumble).abs(),
    0.85 + 0.15 * math.sin(tumble * 0.7),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, -size)
      ..cubicTo(
        -size * 0.95,
        -size * 0.8,
        -size * 0.7,
        size * 0.4,
        -size * 0.12,
        size,
      )
      ..quadraticBezierTo(size * 0.2, size * 0.65, size * 0.55, size * 0.2)
      ..cubicTo(size * 0.9, -size * 0.5, size * 0.45, -size * 1.1, 0, -size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-size, -size),
        Offset(size, size),
        [
          _alpha(const Color(0xFFE9CFC9), alpha),
          _alpha(const Color(0xFFD9ADB4), alpha),
          _alpha(const Color(0xFFA46C80), alpha),
        ],
        const [0, 0.45, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-size * 0.2, -size * 0.7)
      ..quadraticBezierTo(-size * 0.5, 0, -size * 0.12, size * 0.7),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = _alpha(const Color(0xFFFFE7D9), 0.23 * alpha),
  );
  canvas.restore();
}

void _swallow(
  Canvas canvas,
  Offset center,
  double scale,
  double t,
  double heading,
  double bank,
  double alpha,
) {
  final cycle = t % 5.1;
  final beat = cycle < 1.85
      ? math.sin(cycle * _tau * 2.7) * math.sin(math.pi * cycle / 1.85)
      : 0.0;
  final spread = 0.82 + beat * 0.23;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(heading);
  canvas.scale(scale);
  canvas.save();
  canvas.scale(1, spread * (1 - bank * 0.25));
  canvas.drawPath(
    Path()
      ..moveTo(3, -1)
      ..cubicTo(3, -12, -2, -25, -13, -32)
      ..cubicTo(-12, -22, -10, -12, -6, -2)
      ..close(),
    Paint()..color = _alpha(const Color(0xFF283A42), alpha),
  );
  canvas.drawPath(
    Path()
      ..moveTo(2, 1)
      ..cubicTo(3, 11, -2, 25, -17, 32)
      ..cubicTo(-13, 22, -10, 12, -6, 2)
      ..close(),
    Paint()..color = _alpha(const Color(0xFF3F5156), alpha),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, -3)
      ..quadraticBezierTo(-2, -18, -12, -29),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = _alpha(const Color(0xFF859B96), 0.25 * alpha),
  );
  canvas.restore();
  canvas.drawPath(
    Path()
      ..moveTo(-7, -2)
      ..cubicTo(-16, -4, -22, -8, -31, -11)
      ..lineTo(-21, -0.1)
      ..lineTo(-12, 1)
      ..lineTo(-22, 2)
      ..lineTo(-32, 10)
      ..cubicTo(-21, 7, -13, 5, -7, 3)
      ..close(),
    Paint()..color = _alpha(const Color(0xFF2C3D43), alpha),
  );
  _oval(
    canvas,
    const Offset(-1, 0),
    11,
    3.1,
    0,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -4),
        const Offset(0, 4),
        [
          _alpha(const Color(0xFF546B70), alpha),
          _alpha(const Color(0xFF33474D), alpha),
          _alpha(const Color(0xFF22333A), alpha),
        ],
        const [0, 0.55, 1],
      ),
  );
  _oval(
    canvas,
    const Offset(9, -0.5),
    3.8,
    3,
    -0.2,
    Paint()..color = _alpha(const Color(0xFF31434A), alpha),
  );
  canvas.drawPath(
    Path()
      ..moveTo(9, 1)
      ..quadraticBezierTo(13, 0.2, 11, 2)
      ..lineTo(7, 2)
      ..close(),
    Paint()..color = _alpha(const Color(0xFF927B70), alpha),
  );
  canvas.drawPath(
    Path()
      ..moveTo(12, -1)
      ..lineTo(16, -0.2)
      ..lineTo(12, 1)
      ..close(),
    Paint()..color = _alpha(const Color(0xFF26373D), alpha),
  );
  canvas.drawCircle(
    const Offset(10, -1),
    0.45,
    Paint()..color = _alpha(const Color(0xFFD8DBC8), 0.6 * alpha),
  );
  canvas.restore();
}

void _branch(Canvas canvas, double t) {
  canvas.save();
  canvas.translate(600, 126);
  canvas.rotate(_breeze(t));
  canvas.translate(-600, -126);
  const segments = [
    (6.3, [604.0, 131.0, 582.0, 109.0, 568.0, 103.0, 547.0, 95.0]),
    (4.7, [547.0, 95.0, 520.0, 87.0, 510.0, 74.0, 483.0, 69.0]),
    (3.1, [483.0, 69.0, 459.0, 63.0, 441.0, 49.0, 421.0, 43.0]),
    (1.75, [421.0, 43.0, 393.0, 36.0, 373.0, 31.0, 344.0, 28.0]),
    (1.7, [526.0, 86.0, 522.0, 66.0, 514.0, 38.0, 499.0, 13.0]),
    (1.2, [479.0, 68.0, 458.0, 76.0, 441.0, 89.0, 407.0, 89.0]),
    (1.1, [433.0, 47.0, 432.0, 28.0, 421.0, 6.0, 414.0, -10.0]),
    (1.5, [570.0, 104.0, 561.0, 118.0, 550.0, 139.0, 530.0, 150.0]),
    (0.75, [387.0, 35.0, 381.0, 24.0, 369.0, 17.0, 363.0, 12.0]),
  ];
  final wood = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (var i = 0; i < segments.length; i++) {
    final (width, p) = segments[i];
    wood
      ..strokeWidth = width
      ..color = i < 4 ? const Color(0xFF65564B) : const Color(0xFF776354);
    canvas.drawPath(
      Path()
        ..moveTo(p[0], p[1])
        ..cubicTo(p[2], p[3], p[4], p[5], p[6], p[7]),
      wood,
    );
    wood
      ..strokeWidth = width * 0.23
      ..color = const Color(0x54B69C7B);
    canvas.drawPath(
      Path()
        ..moveTo(p[0], p[1] - 0.8)
        ..cubicTo(p[2], p[3] - 1, p[4], p[5] - 0.8, p[6], p[7] - 0.4),
      wood,
    );
  }
  wood
    ..strokeWidth = 0.7
    ..color = const Color(0x4D22231F);
  for (var i = 0; i < 19; i++) {
    final x = 351.0 + i * 13;
    final y = 30 + (x - 351) * 0.27 + math.max(0, x - 460) * 0.12;
    canvas.drawLine(Offset(x, y), Offset(x + 1.5, y - 2), wood);
  }
  for (final (position, angle, size) in const [
    (Offset(341, 28), -0.7, 4.0),
    (Offset(365, 14), -0.6, 3.5),
    (Offset(431, 84), 0.8, 4.7),
    (Offset(496, 13), -0.45, 4.0),
    (Offset(541, 143), 0.9, 4.0),
    (Offset(459, 63), -0.5, 3.4),
  ]) {
    _bud(canvas, position, angle, size);
  }
  for (final (position, angle) in const [
    (Offset(376, 34), -1.2),
    (Offset(452, 77), 1.6),
    (Offset(513, 37), -0.6),
    (Offset(549, 123), 1.3),
  ]) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-4, -9, 0, -17)
        ..quadraticBezierTo(4, -8, 0, 0),
      Paint()..color = const Color(0xFF768372),
    );
    canvas.drawLine(
      Offset.zero,
      const Offset(0, -15),
      Paint()
        ..strokeWidth = 0.5
        ..color = const Color(0x73AEB691),
    );
    canvas.restore();
  }
  for (var i = 0; i < _blooms.length; i++) {
    final (center, radius, angle, tilt, seed) = _blooms[i];
    _blossom(
      canvas,
      center,
      radius,
      angle + math.sin(t * 0.8 + i) * 0.014,
      seed: seed,
      opening: 0.95 + 0.05 * holidayQuintOut(t / 4),
      alpha: 0.96,
      tilt: tilt,
    );
  }
  canvas.restore();
}

void _flight(Canvas canvas, double t, int index) {
  final duration = index == 1 ? 13.1 : 11.8;
  final u = (t + (index == 1 ? -0.72 : 0.1)) % duration / duration;
  final v = 1 - u;
  final p = index == 1
      ? const [
          Offset(-110, 132),
          Offset(100, 68),
          Offset(345, 170),
          Offset(690, 53),
        ]
      : const [
          Offset(-75, 102),
          Offset(135, 40),
          Offset(323, 168),
          Offset(675, 51),
        ];
  final position =
      p[0] * (v * v * v) +
      p[1] * (3 * v * v * u) +
      p[2] * (3 * v * u * u) +
      p[3] * (u * u * u);
  final tangent =
      (p[1] - p[0]) * (3 * v * v) +
      (p[2] - p[1]) * (6 * v * u) +
      (p[3] - p[2]) * (3 * u * u);
  _swallow(
    canvas,
    position,
    (index == 1 ? 0.54 : 0.74) + math.sin(math.pi * u) * 0.22,
    t + index * 1.13,
    math.atan2(tangent.dy, tangent.dx),
    math.sin(u * _tau - 0.5) * 0.65,
    holidayClamp(u * 16) *
        holidayClamp((1 - u) * 16) *
        (index == 1 ? 0.65 : 0.94),
  );
}

// Deterministic seeds match the webpage; petal lifetimes do not reset at 12 s.
final _petals = List.generate(
  34,
  (i) => (
    period: 13.7 + i % 4 * 0.53,
    phase: holidayRandom(i + 2420),
    bloom: const [0, 1, 2, 0, 3, 1, 4][i % 7],
    depth: 0.35 + holidayRandom(i + 2440) * 1.1,
    speed: 12 + holidayRandom(i + 2460) * 15,
    tumble: 1.1 + holidayRandom(i + 2480),
  ),
);

/// Native Canvas counterpart of the approved, petal-rich 584-wide web scene.
void paintHolidayChunfenScene(Canvas canvas, double seconds) {
  final t = seconds;
  canvas.save();
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 584, 264),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(180, 210),
        const [Color(0x4A718277), Color(0x2654706D), Color(0x003A5056)],
        const [0, 0.6, 1],
      ),
  );
  _glow(canvas, const Offset(54, -38), 286, const Color(0xFFDDC999), 0.25);
  _glow(canvas, const Offset(210, 113), 238, const Color(0xFF94B2A5), 0.07);
  for (var k = 0; k < 4; k++) {
    _oval(
      canvas,
      Offset(135 + k * 83 + math.sin(t * 0.08) * 5, 109.0 + k * 7),
      180.0 - k * 19,
      8.0 + k * 2,
      -0.035,
      Paint()..color = const Color(0x04A6B5A5),
    );
  }
  final water = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.55;
  for (var i = 0; i < 22; i++) {
    final y = 138 + holidayRandom(i + 2300) * 74;
    final x = holidayRandom(i + 2330) * 584;
    final width = 9 + holidayRandom(i + 2370) * 43;
    final drift = math.sin(t * 0.65 + i) * 2;
    water.color = _alpha(
      const Color(0xFFB2C2AE),
      (0.018 + holidayRandom(i + 2390) * 0.06) * (1 - (y - 138) / 100),
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + drift, y)
        ..quadraticBezierTo(
          x + width * 0.5 + drift,
          y - 0.6,
          x + width + drift,
          y,
        ),
      water,
    );
  }
  _flight(canvas, t, 1);
  _flight(canvas, t, 0);
  _branch(canvas, t);
  for (var i = 0; i < _petals.length; i++) {
    final p = _petals[i];
    final age = (t - p.phase * p.period) % p.period;
    if (age > 11.9) continue;
    final angle = _breeze(t - age);
    final source = _blooms[p.bloom].$1 - const Offset(600, 126);
    final origin =
        const Offset(600, 126) +
        Offset(
          source.dx * math.cos(angle) - source.dy * math.sin(angle),
          source.dx * math.sin(angle) + source.dy * math.cos(angle),
        );
    final drift = p.speed * age + age * age * 0.55;
    final point =
        origin +
        Offset(
          -drift + 9 * (math.sin(age * 0.85 + i) - math.sin(i.toDouble())),
          age * (2 + p.depth * 2) +
              age * age * 1.05 +
              5 * (math.sin(age * 1.1 + i) - math.sin(i.toDouble())),
        );
    final alpha =
        holidayClamp(age * 2) *
        holidayClamp((11.9 - age) / 1.8) *
        (0.34 + p.depth * 0.36);
    _petal(
      canvas,
      point,
      -0.3 + age * 0.28 + math.sin(age * 0.8 + i) * 0.45,
      2.6 + p.depth * 2.5,
      age * p.tumble + i,
      alpha,
    );
  }
  canvas.restore();
}

/// A small peach sprig at the selected number's left, preserving touch targets.
void paintHolidayChunfenDate(
  Canvas canvas,
  Offset center, {
  required double scale,
  required double seconds,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  const x = -29.0, y = -15.0;
  canvas.translate(x + 9, y + 10);
  canvas.rotate(-0.12 + _breeze(seconds));
  canvas.translate(-x - 9, -y - 10);
  canvas.drawPath(
    Path()
      ..moveTo(x + 10, y + 11)
      ..quadraticBezierTo(x + 4, y + 1, x - 6, y - 6),
    Paint()
      ..color = const Color(0xFF8B7E6C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round,
  );
  _bud(canvas, const Offset(x + 7, y + 1), 0.7, 2.8);
  _blossom(
    canvas,
    const Offset(x, y),
    10.5,
    -0.3,
    seed: 67,
    opening: 0.94 + 0.06 * holidayQuintOut(seconds / 3),
    alpha: 0.97,
    tilt: 0.8,
  );
  canvas.restore();
}
