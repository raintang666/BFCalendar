part of 'holiday_glass_scene.dart';

const _pineSnowWhite = Color(0xFFE9F6FC);

final _pineWinterRidge = Path()
  ..moveTo(221, 218)
  ..cubicTo(278, 207, 293, 191, 335, 192)
  ..cubicTo(357, 192, 383, 213, 422, 211)
  ..cubicTo(465, 209, 485, 182, 519, 187)
  ..cubicTo(549, 192, 567, 206, 584, 209)
  ..lineTo(584, 258)
  ..lineTo(221, 258)
  ..close();

final _snowyPineBough = Path()
  ..moveTo(586, 101)
  ..cubicTo(547, 107, 507, 124, 471, 134)
  ..cubicTo(418, 150, 361, 152, 286, 164)
  ..cubicTo(333, 161, 374, 161, 420, 157)
  ..cubicTo(493, 151, 547, 121, 586, 119)
  ..close();

final _pineBoughRidge = Path()
  ..moveTo(303, 162)
  ..cubicTo(360, 156, 420, 152, 474, 135)
  ..cubicTo(512, 123, 554, 108, 578, 105);

final _pineRidgePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(224, 209),
    const Offset(540, 241),
    const [Color(0x00324653), Color(0x66344C62), Color(0x177299B1)],
    const [0, .59, 1],
  );
final _pineBarkPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(335, 154),
    const Offset(570, 112),
    const [Color(0xFF405253), Color(0xFF564B48), Color(0xFF363D3E)],
    const [0, .59, 1],
  );

final _pineSnowCap = Path()
  ..moveTo(-1, 0)
  ..cubicTo(-.92, -.35, -.77, -.91, -.55, -.79)
  ..cubicTo(-.38, -.72, -.24, -1.1, -.06, -.99)
  ..cubicTo(.13, -.85, .30, -.81, .49, -.72)
  ..cubicTo(.72, -.62, .88, -.28, 1, 0)
  ..cubicTo(.81, .13, .63, .02, .49, .17)
  ..cubicTo(.34, .30, .17, .20, .04, .19)
  ..cubicTo(-.15, .35, -.31, .17, -.49, .22)
  ..cubicTo(-.71, .18, -.88, .21, -1, 0)
  ..close();

Path _makePineSnowCrystal() {
  final crystal = Path();
  for (var ray = 0; ray < 6; ray++) {
    final angle = ray * _tau / 6;
    final x = math.sin(angle), y = -math.cos(angle);
    crystal
      ..moveTo(0, 0)
      ..lineTo(x, y)
      ..moveTo(.57 * x + .23 * y, .57 * y - .23 * x)
      ..lineTo(.78 * x, .78 * y)
      ..lineTo(.57 * x - .23 * y, .57 * y + .23 * x);
  }
  return crystal;
}

final _pineSnowCrystal = _makePineSnowCrystal();

// The geometry stays cached while each twig sways at its own angle.
final _snowyPineFans =
    const [
          (Offset(553, 111), Offset(514, 78), 15.0),
          (Offset(545, 116), Offset(565, 154), 16.0),
          (Offset(519, 123), Offset(475, 103), 16.0),
          (Offset(511, 127), Offset(535, 172), 18.0),
          (Offset(491, 133), Offset(447, 82), 19.0),
          (Offset(479, 137), Offset(491, 178), 17.0),
          (Offset(458, 143), Offset(402, 108), 17.0),
          (Offset(442, 148), Offset(450, 199), 18.0),
          (Offset(419, 151), Offset(367, 125), 17.0),
          (Offset(399, 155), Offset(387, 201), 15.0),
          (Offset(374, 156), Offset(325, 122), 16.0),
          (Offset(352, 160), Offset(324, 186), 13.0),
          (Offset(329, 161), Offset(281, 152), 13.0),
        ].indexed
        .map((entry) {
          final (index, (root, tip, spread)) = entry;
          final delta = tip - root;
          final length = delta.distance;
          final stem = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(length * .52, 5, length, 0);
          final needles = [Path(), Path(), Path()];
          final pairs = 13 + (holidayRandom(15500 + index) * 7).floor();
          for (var pair = 0; pair < pairs; pair++) {
            for (final side in const [-1, 1]) {
              final seed = 13400 + index * 41 + pair * 2 + (side > 0 ? 1 : 0);
              final u =
                  .07 + pair / (pairs - 1) * .71 + holidayRandom(seed) * .027;
              final arch = math.sin(u * math.pi);
              final taper = math.pow(arch, .73).toDouble();
              final startX = u * length, startY = arch * 2.5;
              final reach =
                  (spread + (1 - u) * length * .10) *
                  taper *
                  (.56 + holidayRandom(seed + 700) * .54);
              final endX =
                  startX + reach * (.86 + holidayRandom(seed + 1200) * .64);
              final endY = startY + reach * side;
              needles[(holidayRandom(seed + 1600) * needles.length).floor()]
                ..moveTo(startX, startY)
                ..quadraticBezierTo(
                  startX + reach * .58,
                  startY + reach * side * .43,
                  endX,
                  endY,
                );
            }
          }
          return (
            root: root,
            angle: math.atan2(delta.dy, delta.dx),
            stem: stem,
            needles: needles,
          );
        })
        .toList(growable: false);

const _pineSnowPatches = [
  (Offset(315, 158), 13.0, 3.5, .44, -.13),
  (Offset(347, 154), 21.0, 4.3, .05, -.10),
  (Offset(389, 151), 25.0, 5.1, .15, -.12),
  (Offset(433, 144), 23.0, 5.2, .40, -.24),
  (Offset(480, 131), 24.0, 5.1, .22, -.30),
  (Offset(526, 116), 25.0, 5.1, .15, -.32),
  (Offset(573, 104), 22.0, 5.1, .20, -.22),
  (Offset(344, 130), 8.4, 2.7, 1.25, .32),
  (Offset(385, 132), 11.0, 3.4, 1.05, .40),
  (Offset(415, 115), 10.0, 3.6, .77, .32),
  (Offset(458, 94), 9.0, 3.5, 1.24, .44),
  (Offset(486, 105), 10.0, 3.3, .96, .24),
  (Offset(522, 86), 9.3, 3.2, 1.19, .26),
];

const _pineBackgroundFlakes = 47;
final _pineDriftingSnow = List.generate(70, (i) {
  final distant = i < _pineBackgroundFlakes;
  final size = holidayRandom(15200 + i);
  return (
    x: 214 + holidayRandom(15000 + i) * 370,
    offset: holidayRandom(15100 + i),
    size: distant ? .54 + size * 1.07 : 1.3 + size * 1.47,
    speed: distant ? 1 : 2,
    drift: 9 + holidayRandom(15300 + i) * 25,
    delay: holidayRandom(15400 + i) * _tau,
    crystal: !distant && i % 5 == 0,
  );
}, growable: false);

final _pineLoosenedSnow = List.generate(
  23,
  (i) => (
    x: 328 + holidayRandom(15600 + i) * 128,
    delay: holidayRandom(15700 + i) * .40,
    drift: 14 + holidayRandom(15800 + i) * 42,
    size: .54 + holidayRandom(15900 + i) * 1.92,
  ),
  growable: false,
);

void _paintPineSnowCap(
  Canvas canvas,
  Offset center,
  double width,
  double thickness,
  double cover, [
  double angle = 0,
]) {
  if (cover <= .01) return;
  final opacity = holidaySmooth(.015, .37, cover);
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(width * (.61 + .39 * cover), thickness * cover);
  canvas.drawPath(
    _pineSnowCap,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -1),
        const Offset(0, .24),
        [
          _a(_pineSnowWhite, .90 * opacity),
          _a(const Color(0xFFBBD8E6), .95 * opacity),
          _a(const Color(0xFF91B3CC), .78 * opacity),
        ],
        const [0, .59, 1],
      ),
  );
  canvas.restore();
}

void _paintPineSnowCrystal(
  Canvas canvas,
  Offset center,
  double radius,
  double angle,
  double opacity,
  double width,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(radius);
  _stroke(canvas, _pineSnowCrystal, _pineSnowWhite, opacity, width);
  canvas.restore();
}

void _pineSnowFlurry(
  Canvas canvas,
  double seconds,
  double gust,
  int from,
  int to,
) {
  final strength =
      .65 +
      .35 *
          holidaySmooth(.6, 3.5, seconds) *
          (1 - holidaySmooth(10.2, _loop, seconds));
  for (var i = from; i < to; i++) {
    final flake = _pineDriftingSnow[i];
    final fall = (seconds / _loop * flake.speed + flake.offset) % 1;
    final sway = math.sin(_phase(seconds, 2, flake.delay) + fall * 4);
    final x = flake.x + flake.drift * sway + gust * (16 + flake.size * 9);
    final y = -9 + fall * 278;
    final opacity =
        strength *
        math.pow(math.sin(math.pi * fall), .75) *
        (.30 + flake.size * .24);
    if (flake.crystal) {
      _paintPineSnowCrystal(
        canvas,
        Offset(x, y),
        flake.size * 1.9,
        _phase(seconds, 1, flake.delay),
        opacity * .86,
        .16,
      );
    } else {
      _ellipse(
        canvas,
        x,
        y,
        flake.size,
        flake.size * .85,
        _pineSnowWhite,
        opacity,
        .3,
      );
    }
  }
}

void _xiaoxue(Canvas canvas, double seconds) {
  final cover = holidayPineSnowCover(seconds);
  final gust = holidayPineSnowGust(seconds);
  _glow(canvas, 424, 87, 266, const Color(0xFF82ACD8), .24 + .20 * cover);
  _glow(canvas, 503, 183, 174, const Color(0xFF6692AA), .14 + .10 * cover);
  canvas.drawPath(_pineWinterRidge, _pineRidgePaint);
  _pineSnowFlurry(canvas, seconds, gust, 0, _pineBackgroundFlakes);

  canvas.save();
  canvas.translate(571, 109);
  canvas.rotate(
    -.028 * cover + .020 * math.sin(_phase(seconds, 2, .2)) + .057 * gust,
  );
  canvas.translate(-571, -109);
  canvas.drawPath(_snowyPineBough, _pineBarkPaint);
  _stroke(canvas, _pineBoughRidge, const Color(0xFF90948F), .52, 1.08);
  for (final (index, fan) in _snowyPineFans.indexed) {
    canvas.save();
    canvas.translate(fan.root.dx, fan.root.dy);
    canvas.rotate(
      fan.angle +
          .048 * math.sin(_phase(seconds, 2, index * .49)) +
          gust * .085,
    );
    _stroke(canvas, fan.stem, const Color(0xFF636B5F), .92, 1.9);
    _stroke(canvas, fan.needles[0], const Color(0xFF375B5E), .90, 1.28);
    _stroke(canvas, fan.needles[1], const Color(0xFF4E797A), .93, 1.07);
    _stroke(canvas, fan.needles[2], const Color(0xFF82A09B), .82, .76);
    canvas.restore();
  }
  for (final (center, width, thickness, delay, angle) in _pineSnowPatches) {
    _paintPineSnowCap(
      canvas,
      center,
      width,
      thickness,
      holidayPineSnowCover(seconds, delay),
      angle,
    );
  }
  canvas.restore();

  for (final flake in _pineLoosenedSnow) {
    final fall = (seconds - 8.12 - flake.delay) / 1.32;
    if (fall <= 0 || fall >= 1) continue;
    final opacity = math.sin(math.pi * fall) * .93;
    final y = 147 + (454 - flake.x) * .08 + 15 * fall + 89 * fall * fall;
    _ellipse(
      canvas,
      flake.x + flake.drift * fall,
      y,
      flake.size,
      flake.size * .80,
      _pineSnowWhite,
      opacity,
      -.28,
    );
  }
  _pineSnowFlurry(
    canvas,
    seconds,
    gust,
    _pineBackgroundFlakes,
    _pineDriftingSnow.length,
  );
}

final _pineSnowBadgeBranch = Path()
  ..moveTo(-23, 11)
  ..quadraticBezierTo(-2, 5, 21, -11);
final _pineSnowBadgeNeedles = Path()
  ..moveTo(-15, 8)
  ..lineTo(-21, -4)
  ..moveTo(-15, 8)
  ..lineTo(-7, 12)
  ..moveTo(-9, 5)
  ..lineTo(-13, -10)
  ..moveTo(-9, 5)
  ..lineTo(3, 11)
  ..moveTo(-2, 2)
  ..lineTo(-6, -15)
  ..moveTo(-2, 2)
  ..lineTo(13, 6)
  ..moveTo(5, -2)
  ..lineTo(2, -19)
  ..moveTo(5, -2)
  ..lineTo(17, 1)
  ..moveTo(12, -7)
  ..lineTo(11, -20)
  ..moveTo(12, -7)
  ..lineTo(23, -5)
  ..moveTo(18, -10)
  ..lineTo(20, -20);

void _snowyPineBadge(Canvas canvas, double seconds) {
  final cover = holidayPineSnowCover(seconds);
  canvas.save();
  canvas.rotate(.06 * math.sin(_phase(seconds, 2, .6)));
  _stroke(canvas, _pineSnowBadgeBranch, const Color(0xFF98A894), .99, 2.2);
  _stroke(canvas, _pineSnowBadgeNeedles, const Color(0xFF88C3B8), .96, 1.95);
  _paintPineSnowCap(canvas, const Offset(-5, 2), 10, 3.4, .43 + .57 * cover);
  _paintPineSnowCap(canvas, const Offset(12, -9), 9.6, 3.2, .45 + .55 * cover);
  _paintPineSnowCrystal(
    canvas,
    Offset(-16, -17 + 2.8 * math.sin(_phase(seconds, 1, .25))),
    6.4,
    _phase(seconds),
    .87,
    .18,
  );
  canvas.restore();
}
