part of 'holiday_glass_scene.dart';

const _equinoxShore = 183.0;
const _equinoxDiskStops = [0.0, .57, 1.0];

final _equinoxCrescent = Path()
  ..moveTo(2.6, -27.9)
  ..arcToPoint(
    const Offset(24.9, 13),
    radius: const Radius.circular(28),
    largeArc: true,
    clockwise: false,
  )
  ..arcToPoint(
    const Offset(2.6, -27.9),
    radius: const Radius.circular(23.45),
    largeArc: true,
  )
  ..close();

final _equinoxFarBank = Path()
  ..moveTo(212, 183)
  ..cubicTo(241, 181, 256, 171, 273, 172)
  ..cubicTo(291, 172, 302, 178, 327, 176)
  ..cubicTo(350, 175, 364, 158, 383, 157)
  ..cubicTo(406, 157, 424, 175, 454, 174)
  ..cubicTo(479, 173, 492, 157, 515, 160)
  ..cubicTo(538, 163, 557, 179, 584, 181)
  ..lineTo(584, 191)
  ..lineTo(212, 191)
  ..close();

final _equinoxNearBank = Path()
  ..moveTo(212, 183)
  ..cubicTo(238, 184, 250, 180, 271, 179)
  ..cubicTo(295, 178, 308, 185, 335, 184)
  ..cubicTo(376, 182, 393, 171, 419, 173)
  ..cubicTo(450, 175, 476, 183, 509, 180)
  ..cubicTo(539, 178, 557, 171, 584, 176)
  ..lineTo(584, 191)
  ..lineTo(212, 191)
  ..close();

Paint _equinoxBankPaint(Color warm, Color cool) =>
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(212, 0),
        const Offset(584, 0),
        [_a(warm, 0), _a(warm, .79), _a(cool, .90), _a(cool, .58)],
        const [0, .24, .65, 1],
      );

final _equinoxFarPaint = _equinoxBankPaint(
  const Color(0xFF755B5A),
  const Color(0xFF3C4868),
);
final _equinoxNearPaint = _equinoxBankPaint(
  const Color(0xFF413E46),
  const Color(0xFF29364D),
);

final _equinoxStars = List.generate(
  20,
  (i) => (
    x: 389 + holidayRandom(5400 + i) * 172,
    y: 60 + holidayRandom(5500 + i) * 101,
    size: .48 + holidayRandom(5600 + i) * 1.03,
    delay: holidayRandom(5650 + i) * _tau,
  ),
).where((star) => star.x < 452 || star.y > 80).toList(growable: false);

final _equinoxRipples = List.generate(
  24,
  (i) => (
    depth: (i + .32 + holidayRandom(5700 + i) * .54) / 24,
    width: .27 + holidayRandom(5800 + i) * .73,
    shift: holidayRandom(5900 + i) - .5,
    delay: holidayRandom(6000 + i) * _tau,
  ),
);

void _equinoxSun(Canvas canvas, Offset center, double radius, double opacity) {
  if (opacity <= 0) return;
  final edge = Offset(0, radius);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = ui.Gradient.linear(center - edge, center + edge, [
        _a(const Color(0xFFFFEEB1), opacity),
        _a(const Color(0xFFFFC37A), opacity),
        _a(const Color(0xFFE27744), opacity),
      ], _equinoxDiskStops),
  );
}

void _equinoxMoon(Canvas canvas, Offset center, double radius, double opacity) {
  if (opacity <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius / 28);
  canvas.drawPath(
    _equinoxCrescent,
    Paint()
      ..shader =
          ui.Gradient.linear(const Offset(-23, -15), const Offset(18, 24), [
            _a(const Color(0xFFE7EFFF), opacity),
            _a(const Color(0xFFC1D4FD), opacity),
            _a(const Color(0xFF96AEEE), opacity),
          ], _equinoxDiskStops),
  );
  canvas.restore();
}

void _equinoxReflection(
  Canvas canvas,
  double seconds,
  Offset center,
  double opacity,
  Color color,
  double offset,
) {
  if (opacity <= 0) return;
  final length = 42 + 25 * holidaySmooth(70, _equinoxShore, center.dy);
  canvas.save();
  canvas.translate(center.dx, _equinoxShore + length * .41);
  canvas.scale(1, .46);
  _glow(canvas, 0, 0, length, color, opacity * .27);
  canvas.restore();

  for (final ripple in _equinoxRipples) {
    final depth = ripple.depth;
    final wave = math.sin(
      _phase(seconds, 3, ripple.delay + depth * 7 + offset),
    );
    final x = center.dx + (ripple.shift * 27 + wave * 8) * (.24 + depth);
    final width = (17 + 47 * depth) * ripple.width * (.84 + wave * .16);
    final shimmer = (.53 + wave * .26) * (1 - depth * .71) * opacity;
    _ellipse(
      canvas,
      x,
      _equinoxShore + 4 + depth * length,
      width / 2,
      .58 + depth,
      color,
      shimmer,
    );
  }
}

const _equinoxFlock = [
  (position: Offset.zero, size: 8.0, delay: 0.0),
  (position: Offset(-17, 6), size: 6.3, delay: 1.2),
  (position: Offset(-30, 1), size: 5.0, delay: 2.4),
];

void _equinoxBirds(Canvas canvas, double seconds) {
  final arrival = holidaySmooth(2.9, 8.85, seconds);
  final opacity =
      holidaySmooth(2.9, 4.2, seconds) *
      (1 - holidaySmooth(7.4, 8.85, seconds));
  if (opacity <= 0) return;
  for (final bird in _equinoxFlock) {
    final x = 332 + 97 * arrival + bird.position.dx;
    final y = 108 - 28 * arrival + bird.position.dy;
    final size = bird.size;
    final flap = math.sin(_phase(seconds, 15, bird.delay));
    final wing = Path()
      ..moveTo(x - size, y - 2.5 + flap * 3.5)
      ..quadraticBezierTo(x - size * .44, y - 3, x, y)
      ..quadraticBezierTo(x + size * .43, y - 4, x + size, y - 3 + flap * 3.7);
    _stroke(canvas, wing, const Color(0xFFE0CEC0), opacity * .57, 1.25);
  }
}

void _qiufen(Canvas canvas, double seconds) {
  final progress = holidayEquinoxProgress(seconds);
  final visible = holidayEquinoxVisibility(seconds);
  final sun = Offset(289 + 28 * progress, 66 + 138 * progress);
  final moon = Offset(516 - 83 * progress, 204 - 138 * progress);
  final daylight = visible * (1 - holidaySmooth(.80, 1, progress));
  final moonlight = visible * holidaySmooth(.09, .45, progress);
  _glow(
    canvas,
    sun.dx,
    math.min(sun.dy, _equinoxShore),
    151,
    HolidayCalendarDesign.equinoxGold,
    daylight * .34,
  );
  _glow(
    canvas,
    moon.dx,
    math.min(moon.dy, _equinoxShore),
    146,
    HolidayCalendarDesign.equinoxBlue,
    moonlight * .36,
  );

  canvas.save();
  canvas.clipRect(const Rect.fromLTRB(201, 0, 584, _equinoxShore));
  final night = holidaySmooth(.28, .79, progress);
  for (final star in _equinoxStars) {
    final twinkle = .61 + .39 * math.sin(_phase(seconds, 3, star.delay));
    _ellipse(
      canvas,
      star.x,
      star.y,
      star.size,
      star.size,
      const Color(0xFFDAE6FC),
      visible * night * twinkle * .84,
    );
  }
  _equinoxSun(canvas, sun, 26, daylight);
  _equinoxMoon(canvas, moon, 28, moonlight);
  _equinoxBirds(canvas, seconds);
  canvas.restore();

  canvas.drawPath(_equinoxFarBank, _equinoxFarPaint);
  canvas.drawPath(_equinoxNearBank, _equinoxNearPaint);
  _line(
    canvas,
    246,
    _equinoxShore + 4,
    567,
    _equinoxShore + 4,
    const Color(0xFFBCB6BD),
    .22,
    .72,
  );
  _equinoxReflection(
    canvas,
    seconds,
    sun,
    daylight,
    const Color(0xFFFCB165),
    0,
  );
  _equinoxReflection(
    canvas,
    seconds,
    moon,
    moonlight,
    const Color(0xFFACC4F9),
    1.2,
  );
}

void _equinoxBadge(Canvas canvas, double seconds) {
  final shift = 5 * (holidayEquinoxProgress(seconds) - .5);
  _equinoxSun(canvas, Offset(-15, -2 + shift), 10, .98);
  _equinoxMoon(canvas, Offset(14, -2 - shift), 12, .98);
  _line(canvas, -24, 13, -4, 13, const Color(0xFFFFD693), .77, 1.8);
  _line(canvas, 5, 13, 23, 13, const Color(0xFFC7DCFF), .77, 1.8);
}
