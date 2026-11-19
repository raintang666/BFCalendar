part of 'holiday_glass_scene.dart';

const _fireflyGold = Color(0xFFE0EF7A);

final _bankEdge = Path()
  ..moveTo(238, 232)
  ..cubicTo(323, 220, 338, 185, 429, 196)
  ..cubicTo(479, 201, 537, 183, 587, 173);

final _nightBank = Path.from(_bankEdge)
  ..lineTo(587, 283)
  ..lineTo(238, 283)
  ..close();

final _grassBlade = Path()
  ..moveTo(0, 0)
  ..cubicTo(-7, -22, -19, -44, -35, -61)
  ..cubicTo(-14, -53, 0, -32, 0, 0)
  ..close();

final _grassVein = Path()
  ..moveTo(0, 0)
  ..quadraticBezierTo(-9, -35, -31, -55);

const _meadowGrass = [
  (Offset(277, 232), .61, -.25, Color(0xFF597D63), .41),
  (Offset(278, 232), -.56, .37, Color(0xFF608773), .36),
  (Offset(333, 214), .50, -.28, Color(0xFF5B766F), .47),
  (Offset(541, 220), .86, .23, Color(0xFF577D75), .60),
  (Offset(548, 222), -.91, -.46, Color(0xFF668F6C), .58),
  (Offset(557, 224), 1.05, .50, Color(0xFF759163), .62),
  (Offset(571, 223), -.89, .19, Color(0xFF79915D), .55),
];

typedef _Firefly = ({
  Offset center,
  Offset radii,
  double turns,
  double offset,
  double beats,
  double pulse,
  double size,
});

const _nearestFireflies = <_Firefly>[
  (
    center: Offset(394, 131),
    radii: Offset(105, 43),
    turns: 1,
    offset: .21,
    beats: 3,
    pulse: .46,
    size: 3.55,
  ),
  (
    center: Offset(437, 101),
    radii: Offset(72, 31),
    turns: 2,
    offset: 2.3,
    beats: 2,
    pulse: 2.05,
    size: 2.65,
  ),
  (
    center: Offset(473, 148),
    radii: Offset(56, 46),
    turns: 1,
    offset: 4.07,
    beats: 3,
    pulse: 4.1,
    size: 3.4,
  ),
  (
    center: Offset(365, 166),
    radii: Offset(79, 32),
    turns: 2,
    offset: 5.1,
    beats: 4,
    pulse: 1.2,
    size: 2.8,
  ),
];

final _distantFireflies = List<_Firefly>.generate(
  15,
  (i) => (
    center: Offset(
      280 + holidayRandom(i + 7300) * 274,
      79 + holidayRandom(i + 7340) * 114,
    ),
    radii: Offset(
      12 + holidayRandom(i + 7380) * 33,
      8 + holidayRandom(i + 7420) * 16,
    ),
    turns: 1.0 + i % 2,
    offset: holidayRandom(i + 7460) * _tau,
    beats: 2.0 + i % 3,
    pulse: holidayRandom(i + 7500) * _tau,
    size: .72 + holidayRandom(i + 7540) * .82,
  ),
);

Offset _fireflyPosition(_Firefly fly, double seconds) {
  final travel = _phase(seconds, fly.turns, fly.offset);
  return fly.center +
      Offset(
        fly.radii.dx * math.sin(travel) +
            math.sin(_phase(seconds, 3, fly.offset)) * 9,
        fly.radii.dy * math.cos(travel + .49) +
            math.sin(_phase(seconds, 4, fly.offset)) * 5,
      );
}

void _firefly(
  Canvas canvas,
  _Firefly fly,
  double seconds, {
  bool near = false,
}) {
  final point = _fireflyPosition(fly, seconds);
  final light = holidayFireflyPulse(seconds, fly.beats, fly.pulse);
  final radius = fly.size;
  if (near) {
    // The short trail follows this fly's own recent path.
    var previous = _fireflyPosition(fly, seconds - .32);
    for (var step = 1; step <= 5; step++) {
      final position = _fireflyPosition(fly, seconds - .32 * (1 - step / 5));
      _line(
        canvas,
        previous.dx,
        previous.dy,
        position.dx,
        position.dy,
        _fireflyGold,
        light * step / 10,
        radius * .96,
      );
      previous = position;
    }
    _glow(canvas, point.dx, point.dy, 24, _fireflyGold, light * .46);
    _ellipse(
      canvas,
      point.dx,
      point.dy,
      radius * 1.23,
      radius * .80,
      const Color(0xFFF8FEB2),
      light,
    );
  } else {
    _glow(canvas, point.dx, point.dy, radius * 7, _fireflyGold, light * .24);
    _ellipse(
      canvas,
      point.dx,
      point.dy,
      radius,
      radius,
      const Color(0xFFEBF4A5),
      light * .70,
    );
  }
}

void _grass(
  Canvas canvas,
  Offset root,
  double scale,
  double angle,
  Color color,
  double opacity,
) {
  canvas.save();
  canvas.translate(root.dx, root.dy);
  canvas.rotate(angle);
  canvas.scale(scale, scale.abs());
  canvas.drawPath(
    _grassBlade,
    Paint()
      ..shader = ui.Gradient.linear(const Offset(-31, -57), Offset.zero, [
        _a(color, opacity),
        _a(_mix(color, const Color(0xFF223B41), .7), opacity * .5),
      ]),
  );
  _stroke(canvas, _grassVein, color, opacity * .60, .65);
  canvas.restore();
}

void _fireflyLandscape(Canvas canvas) {
  _glow(canvas, 418, 118, 258, const Color(0xFF536CAE), .30);
  _glow(canvas, 237, 60, 259, const Color(0xFF506D98), .14);
  _glow(canvas, 523, 211, 202, const Color(0xFF4D8482), .15);
  canvas.drawPath(
    _nightBank,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 180),
        const Offset(0, 272),
        [_a(const Color(0xFF1B2B40), .79), const Color(0x00192C34)],
      ),
  );
  _stroke(canvas, _bankEdge, const Color(0xFF719D8F), .24, .95);
}

void _dashu(Canvas canvas, double seconds) {
  for (final (i, (root, scale, angle, color, opacity))
      in _meadowGrass.indexed) {
    final sway = math.sin(_phase(seconds, 2, i * .74)) * .12;
    _grass(canvas, root, scale, angle + sway, color, opacity);
  }
  for (final fly in _distantFireflies) {
    _firefly(canvas, fly, seconds);
  }
  for (final fly in _nearestFireflies) {
    _firefly(canvas, fly, seconds, near: true);
  }
}

void _fireflyBadge(Canvas canvas, double seconds) {
  const root = Offset(5, 15);
  final sway = math.sin(_phase(seconds)) * .10;
  _grass(canvas, root, .55, -.12 + sway, const Color(0xFF94BF78), .92);
  _grass(canvas, root, -.38, .19, const Color(0xFFA7C57B), .83);
  final x = -6 + math.sin(_phase(seconds, 2)) * 8;
  final y = -12 + math.cos(_phase(seconds, 2)) * 6;
  final light = .50 + .50 * holidayFireflyPulse(seconds, 3, .9);
  _glow(canvas, x, y, 17, _fireflyGold, .43 * light);
  _ellipse(canvas, x, y, 6, 4.3, const Color(0xFFF8FDBB), light, -.23);
  _ellipse(
    canvas,
    13,
    -16,
    3.1,
    3.1,
    const Color(0xFFEEF79F),
    .62 + .31 * holidayFireflyPulse(seconds, 3, 2.3),
  );
}
