import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';

Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: holidayClamp(opacity));

void _glow(
  Canvas canvas,
  Offset center,
  double radius,
  Color color,
  double alpha,
) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(center, radius, [
        _alpha(color, alpha),
        _alpha(color, 0),
      ]),
  );
}

final _rainStreaks = List.generate(
  112,
  (i) => (
    x: holidayRandom(i + 1100),
    phase: holidayRandom(i + 1130),
    depth: holidayRandom(i + 1160),
    speed: 0.55 + holidayRandom(i + 1190) * 0.65,
  ),
);
final _pondRipples = List.generate(
  15,
  (i) => (
    x: 26 + holidayRandom(i + 1230) * 532,
    y: 157 + holidayRandom(i + 1260) * 84,
    phase: holidayRandom(i + 1290),
    period: 2.1 + holidayRandom(i + 1320) * 2.4,
    radius: 17 + holidayRandom(i + 1350) * 35,
  ),
);

void _waterRipple(
  Canvas canvas,
  Offset center,
  double life,
  double radius, {
  double alpha = 0.45,
  double stroke = 0.85,
}) {
  if (life < 0 || life >= 1) return;
  final r = 2 + math.sqrt(life) * radius;
  final fade = math.pow(1 - life, 1.6).toDouble();
  canvas.drawOval(
    Rect.fromCenter(center: center, width: r * 2, height: r * 0.48),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = _alpha(const Color(0xFFA0D9E5), fade * alpha),
  );
  if (life > 0.16) {
    final inner = r * (1 - 0.18 / life);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: math.max(1, inner) * 2,
        height: math.max(0.5, inner * 0.24) * 2,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = _alpha(const Color(0xFF83BFCF), fade * alpha * 0.46),
    );
  }
}

void _waterDrop(Canvas canvas, Offset center, double radius, double alpha) {
  final x = center.dx, y = center.dy, r = radius;
  final path = Path()
    ..moveTo(x, y - r * 1.8)
    ..cubicTo(
      x - r * 0.15,
      y - r * 0.5,
      x - r,
      y - r * 0.2,
      x - r * 0.8,
      y + r * 0.4,
    )
    ..cubicTo(
      x - r * 0.4,
      y + r * 1.3,
      x + r * 0.8,
      y + r,
      x + r * 0.85,
      y + r * 0.2,
    )
    ..cubicTo(x + r, y - r * 0.3, x + r * 0.15, y - r * 0.6, x, y - r * 1.8);
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        center - Offset(r, r * 2),
        center + Offset(r, r),
        [
          _alpha(const Color(0xFFD2EFF2), 0.35 * alpha),
          _alpha(const Color(0xFF95D1E1), 0.9 * alpha),
          _alpha(const Color(0xFFDEF7F7), 0.8 * alpha),
        ],
        const [0, 0.6, 1],
      ),
  );
  canvas.drawPath(
    Path()
      ..moveTo(x - r * 0.35, y - r * 0.2)
      ..quadraticBezierTo(x - r * 0.6, y + r * 0.3, x - r * 0.15, y + r * 0.65),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = _alpha(const Color(0xFFECFBF9), 0.62 * alpha),
  );
}

const _roofCorners = [
  Offset(458, 66),
  Offset(534, 68),
  Offset(570, 83),
  Offset(540, 101),
  Offset(458, 112),
  Offset(376, 101),
  Offset(346, 83),
  Offset(382, 68),
];
const _bases = [
  Offset(458, 160),
  Offset(510, 165),
  Offset(532, 177),
  Offset(510, 189),
  Offset(458, 194),
  Offset(406, 189),
  Offset(384, 177),
  Offset(406, 165),
];

Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);
Offset _roofControl1(Offset corner) =>
    Offset(458 + (corner.dx - 458) * 0.3, 55);
Offset _roofControl2(Offset corner) =>
    Offset(corner.dx + (458 - corner.dx) * 0.22, corner.dy + 13);
Path _roofRidge(Offset corner) => Path()
  ..moveTo(458, 23)
  ..cubicTo(
    _roofControl1(corner).dx,
    55,
    _roofControl2(corner).dx,
    _roofControl2(corner).dy,
    corner.dx,
    corner.dy,
  );
Offset _ridgePoint(Offset corner, double u) {
  final v = 1 - u;
  return const Offset(458, 23) * (v * v * v) +
      _roofControl1(corner) * (3 * v * v * u) +
      _roofControl2(corner) * (3 * v * u * u) +
      corner * (u * u * u);
}

ui.Picture? _pavilionPicture;

/// Static architecture is recorded once; only the water is redrawn each frame.
ui.Picture _pavilion() {
  if (_pavilionPicture case final picture?) return picture;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintPavilion(canvas);
  return _pavilionPicture = recorder.endRecording();
}

void _paintPavilion(Canvas canvas) {
  const center = Offset(458, 177);
  List<Offset> platform(double scale, double dy) =>
      _bases.map((p) => center + (p - center) * scale + Offset(0, dy)).toList();
  _glow(canvas, const Offset(458, 115), 150, const Color(0xFF80B6C0), 0.055);
  canvas.drawOval(
    const Rect.fromLTWH(346, 194, 224, 28),
    Paint()..color = const Color.fromRGBO(6, 18, 25, 0.28),
  );
  final lower = platform(1.31, 8), upper = platform(1.14, 0);
  canvas.drawPath(_polygon(lower), Paint()..color = const Color(0xFF29424C));
  for (var i = 2; i < 6; i++) {
    final a = lower[i], b = lower[(i + 1) % 8];
    canvas.drawPath(
      _polygon([a, b, b + const Offset(0, 5), a + const Offset(0, 5)]),
      Paint()
        ..color = i < 4 ? const Color(0xFF213741) : const Color(0xFF1D333D),
    );
  }
  canvas.drawPath(
    _polygon(lower),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color.fromRGBO(158, 193, 198, 0.28),
  );
  canvas.drawPath(
    _polygon(upper),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 155),
        const Offset(0, 201),
        const [Color(0xFF314C55), Color(0xFF47606A)],
      ),
  );
  canvas.drawPath(
    _polygon(upper),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color.fromRGBO(170, 204, 205, 0.3),
  );
  for (final i in [0, 1, 7]) {
    final p = _bases[i];
    canvas.drawLine(
      p - const Offset(0, 77),
      p - const Offset(0, 1),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = const Color.fromRGBO(86, 125, 133, 0.58),
    );
  }
  for (var i = 0; i < 8; i++) {
    canvas.drawLine(
      _bases[i] - const Offset(0, 75),
      _bases[(i + 1) % 8] - const Offset(0, 75),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.8
        ..color = i < 2 || i == 7
            ? const Color.fromRGBO(79, 114, 127, 0.58)
            : const Color.fromRGBO(117, 151, 158, 0.75),
    );
  }
  for (var i = 2; i < 6; i++) {
    final a = _bases[i], b = _bases[(i + 1) % 8];
    for (final h in [25.0, 10.0]) {
      canvas.drawLine(
        a - Offset(0, h),
        b - Offset(0, h),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.3
          ..color = h == 25 ? const Color(0xFF71939B) : const Color(0xFF466772),
      );
    }
    for (var n = 1; n < 4; n++) {
      final p = Offset.lerp(a, b, n / 4)!;
      canvas.drawLine(
        p - const Offset(0, 24),
        p - const Offset(0, 11),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.1
          ..color = const Color.fromRGBO(121, 159, 166, 0.65),
      );
    }
  }
  for (final i in [2, 6, 3, 5, 4]) {
    final p = _bases[i];
    canvas.drawRect(
      Rect.fromLTWH(p.dx - 2.5, p.dy - 78, 5, 78),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(p.dx - 3, 0),
          Offset(p.dx + 3, 0),
          const [Color(0xFF36515E), Color(0xFF7B989D), Color(0xFF395761)],
          const [0, 0.48, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromLTWH(p.dx - 4, p.dy - 5, 8, 5),
      Paint()..color = const Color(0xFF64818A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(p.dx - 6, p.dy - 68)
        ..lineTo(p.dx, p.dy - 73)
        ..lineTo(p.dx + 6, p.dy - 68),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = const Color(0xFF729299),
    );
  }
  const faces = [
    Color(0xFF324C5C),
    Color(0xFF3C5B6B),
    Color(0xFF456879),
    Color(0xFF4B7080),
    Color(0xFF507485),
    Color(0xFF436777),
    Color(0xFF304E60),
    Color(0xFF345466),
  ];
  for (var i = 0; i < 8; i++) {
    final a = _roofCorners[i], b = _roofCorners[(i + 1) % 8];
    final c1 = _roofControl1(a),
        c2 = _roofControl2(a),
        d1 = _roofControl1(b),
        d2 = _roofControl2(b);
    final third = Offset.lerp(a, b, 0.3)!, twoThirds = Offset.lerp(a, b, 0.7)!;
    final path = Path()
      ..moveTo(458, 23)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, a.dx, a.dy)
      ..cubicTo(
        third.dx,
        third.dy + 5,
        twoThirds.dx,
        twoThirds.dy + 5,
        b.dx,
        b.dy,
      )
      ..cubicTo(d2.dx, d2.dy, d1.dx, d1.dy, 458, 23)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(458, 23),
          (a + b) / 2 + const Offset(0, 6),
          [const Color(0xFF65818B), faces[i], const Color(0xFF294653)],
          const [0, 0.3, 1],
        ),
    );
    for (final u in [0.42, 0.57, 0.7, 0.81, 0.9]) {
      final p = _ridgePoint(a, u), q = _ridgePoint(b, u);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(
            (p.dx + q.dx) / 2,
            (p.dy + q.dy) / 2 + 4 * u,
            q.dx,
            q.dy,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..color = const Color.fromRGBO(156, 194, 205, 0.13),
      );
    }
  }
  for (var i = 0; i < 8; i++) {
    final a = _roofCorners[i],
        b = _roofCorners[(i + 1) % 8],
        third = Offset.lerp(a, b, 0.3)!,
        twoThirds = Offset.lerp(a, b, 0.7)!;
    canvas.drawPath(
      _roofRidge(a),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = i < 2 || i == 7
            ? const Color.fromRGBO(144, 185, 199, 0.43)
            : const Color.fromRGBO(183, 218, 224, 0.67),
    );
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy + 3)
        ..cubicTo(
          third.dx,
          third.dy + 8,
          twoThirds.dx,
          twoThirds.dy + 8,
          b.dx,
          b.dy + 3,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5
        ..color = const Color(0xFF294553),
    );
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(
          third.dx,
          third.dy + 5,
          twoThirds.dx,
          twoThirds.dy + 5,
          b.dx,
          b.dy,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5
        ..color = const Color.fromRGBO(178, 214, 221, 0.67),
    );
  }
  canvas.drawOval(
    const Rect.fromLTWH(451, 21.5, 14, 5),
    Paint()..color = const Color(0xFF698892),
  );
  canvas.drawLine(
    const Offset(458, 22),
    const Offset(458, 12),
    Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = const Color(0xFFA0BEC6),
  );
  canvas.drawCircle(
    const Offset(458, 12),
    2.4,
    Paint()..color = const Color(0xFFADC8CC),
  );
}

/// Same 584px scene geometry and seeded water motion as the approved webpage.
void paintHolidayRainScene(Canvas canvas, double seconds) {
  final t = seconds;
  _glow(canvas, const Offset(386, 42), 285, const Color(0xFF699FB5), 0.18);
  _glow(canvas, const Offset(87, 143), 220, const Color(0xFF6AAFAE), 0.11);
  _glow(canvas, const Offset(345, 213), 200, const Color(0xFF6EB3C5), 0.1);
  canvas.drawOval(
    const Rect.fromLTWH(55, 154, 560, 124),
    Paint()
      ..shader = ui.Gradient.radial(const Offset(335, 217), 255, const [
        Color.fromRGBO(127, 191, 202, 0.055),
        Color.fromRGBO(127, 191, 202, 0),
      ]),
  );
  for (var k = 0; k < 6; k++) {
    final y = 178 + k * 12 + math.sin(t * 0.3 + k) * 2;
    canvas.drawPath(
      Path()
        ..moveTo(20, y)
        ..cubicTo(160, y - 5, 380, y + 5, 565, y - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _alpha(const Color(0xFF8FC2CA), 0.025 + (k % 2) * 0.009),
    );
  }
  for (final p in _pondRipples) {
    _waterRipple(
      canvas,
      Offset(p.x, p.y),
      (t / p.period + p.phase) % 1,
      p.radius,
      alpha: 0.32,
    );
  }
  canvas.drawPicture(_pavilion());
  const drops = [(6, 216.0), (2, 216.0), (5, 231.0)];
  for (var i = 0; i < drops.length; i++) {
    final (corner, waterY) = drops[i];
    final tip = _roofCorners[corner],
        period = 2 + i * 0.57,
        phase = (t / period + i * 0.31) % 1;
    if (phase < 0.3) {
      _waterDrop(canvas, tip + const Offset(0, 2), 1 + phase * 7, 0.68);
    } else {
      final u = (phase - 0.3) / 0.7;
      final point = Offset(tip.dx + u * 6, tip.dy + (waterY - tip.dy) * u * u);
      _waterDrop(canvas, point, 2.5 + i * 0.35, 0.82);
      if (u > 0.8) {
        _glow(canvas, point, 7, const Color(0xFFAADEE6), 0.06 * (u - 0.8) * 5);
      }
    }
    final age = ((phase + 0.04) % 1) * period;
    _waterRipple(
      canvas,
      Offset(tip.dx + 6, waterY),
      age / 1.7,
      35 + i * 4,
      alpha: 0.55,
    );
  }
  for (var i = 0; i < _rainStreaks.length; i++) {
    final p = _rainStreaks[i], depth = p.depth;
    final fall = (t * (89 + p.speed * 83) + p.phase * 324) % 324 - 35;
    final wind = 7 + math.sin(t * 0.38 + p.phase * 4) * 3;
    final x = (p.x * 644 + fall * 0.16 + math.sin(t * 0.23 + i) * 3) % 644 - 30;
    final length = 9 + depth * 18;
    canvas.drawLine(
      Offset(x - wind, fall - length),
      Offset(x, fall),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.55 + depth * 0.85
        ..shader = ui.Gradient.linear(
          Offset(x - wind, fall - length),
          Offset(x, fall),
          [
            const Color.fromRGBO(164, 211, 224, 0),
            _alpha(const Color(0xFFB5E1E8), 0.11 + depth * 0.25),
          ],
        ),
    );
    if (i % 23 == 0) {
      _glow(
        canvas,
        Offset(x, fall),
        4 + depth * 4,
        const Color(0xFFA1DAE6),
        0.035,
      );
    }
  }
}

/// Fits the water decoration to the SDK's selected cell without covering text.
void paintHolidayRainDate(Canvas canvas, Rect selection, double seconds) {
  final scale = selection.width / 64;
  canvas.save();
  canvas.translate(selection.center.dx, selection.bottom + 1);
  canvas.scale(scale);
  final phase = (seconds * 0.58) % 1;
  _waterRipple(canvas, Offset.zero, phase, 28, alpha: 0.85, stroke: 1.7);
  _waterRipple(
    canvas,
    Offset.zero,
    (phase + 0.5) % 1,
    24,
    alpha: 0.55,
    stroke: 1.25,
  );
  canvas.restore();
  final drip = (seconds * 0.54 + 0.3) % 1;
  _waterDrop(
    canvas,
    Offset(math.max(2, selection.left - 1), selection.top + 4 + drip * 12),
    1.25,
    math.sin(math.pi * drip) * 0.68,
  );
}
