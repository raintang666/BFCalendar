part of 'holiday_glass_scene.dart';

const _cicadaPerch = Offset(426, 111);

final _cicadaBranch = Path()
  ..moveTo(268, 242)
  ..cubicTo(365, 203, 440, 105, 584, 68)
  ..lineTo(602, 95)
  ..cubicTo(475, 127, 400, 219, 278, 258)
  ..close();

final _cicadaBark = Path()
  ..moveTo(291, 244)
  ..cubicTo(405, 191, 455, 115, 580, 84)
  ..moveTo(352, 222)
  ..cubicTo(398, 198, 425, 163, 474, 133);

final _cicadaWing = Path()
  ..moveTo(3, -23)
  ..cubicTo(24, -17, 37, 14, 32, 34)
  ..quadraticBezierTo(27, 56, 13, 58)
  ..cubicTo(4, 50, 0, 33, 0, 14)
  ..close();

final _cicadaVeins = Path()
  ..moveTo(4, -18)
  ..cubicTo(19, 3, 21, 34, 13, 56)
  ..moveTo(13, -7)
  ..quadraticBezierTo(23, 1, 29, 17)
  ..moveTo(17, 10)
  ..quadraticBezierTo(27, 17, 32, 29)
  ..moveTo(19, 27)
  ..quadraticBezierTo(26, 32, 29, 42)
  ..moveTo(17, 41)
  ..quadraticBezierTo(22, 46, 23, 51)
  ..moveTo(16, 14)
  ..quadraticBezierTo(9, 27, 7, 43);

final _cicadaBody = Path()
  ..moveTo(0, -29)
  ..cubicTo(-19, -27, -21, -8, -16, 18)
  ..cubicTo(-15, 36, -7, 49, 0, 53)
  ..cubicTo(7, 49, 15, 36, 16, 18)
  ..cubicTo(21, -8, 19, -27, 0, -29)
  ..close();

final _cicadaThorax = Path()
  ..moveTo(-16, -27)
  ..quadraticBezierTo(0, -37, 16, -27)
  ..lineTo(18, -10)
  ..quadraticBezierTo(0, 7, -18, -10)
  ..close();

final _cicadaHead = Path()
  ..moveTo(-14, -28)
  ..quadraticBezierTo(-20, -38, -11, -43)
  ..quadraticBezierTo(1, -49, 13, -42)
  ..quadraticBezierTo(19, -38, 14, -28)
  ..quadraticBezierTo(0, -24, -14, -28)
  ..close();

final _cicadaLegs = Path()
  ..moveTo(11, -23)
  ..lineTo(25, -27)
  ..lineTo(32, -20)
  ..lineTo(30, -15)
  ..moveTo(15, -12)
  ..lineTo(31, -11)
  ..lineTo(38, 0)
  ..lineTo(35, 5)
  ..moveTo(14, 1)
  ..lineTo(30, 7)
  ..lineTo(35, 19)
  ..lineTo(31, 23);

final _cicadaRibs = () {
  final ribs = Path();
  for (var i = 0; i < 6; i++) {
    final y = 3.0 + i * 6;
    final width = 13 - i * 1.35;
    ribs
      ..moveTo(-width, y)
      ..quadraticBezierTo(0, y + 4, width, y);
  }
  return ribs;
}();

final _cicadaBodyPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-17, 0),
    const Offset(17, 9),
    const [Color(0xFF53714A), Color(0xFF819655), Color(0xFF293F38)],
    const [0, .46, 1],
  );

final _cicadaBranchPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(298, 221),
    const Offset(567, 85),
    [
      _a(const Color(0xFF354333), .28),
      _a(const Color(0xFF716E40), .95),
      _a(const Color(0xFF465C3F), .78),
    ],
    const [0, .53, 1],
  );

const _cicadaCanopy = [
  (Offset(310, 0), 121.0, 35.0, 2.76, Color(0xFF48764A), .40),
  (Offset(365, -12), 99.0, 28.0, -2.44, Color(0xFF688E4E), .36),
  (Offset(555, 6), 112.0, 29.0, -1.97, Color(0xFF628A44), .29),
  (Offset(589, 91), 105.0, 26.0, -1.38, Color(0xFF7CA04C), .57),
  (Offset(518, 113), 89.0, 26.0, 1.71, Color(0xFF467D4F), .55),
  (Offset(373, 193), 109.0, 32.0, -.99, Color(0xFF74954B), .62),
  (Offset(354, 202), 89.0, 25.0, -1.78, Color(0xFF48774D), .45),
];

void _cicada(
  Canvas canvas,
  Offset center,
  double scale,
  double angle,
  double seconds,
  double strength, {
  bool detail = true,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  final quiver = math.sin(_phase(seconds, 118)) * strength;

  if (detail) {
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1);
      _stroke(canvas, _cicadaLegs, const Color(0xFF798856), .85, 2.1);
      canvas.restore();
    }
  }

  canvas.save();
  canvas.scale(1, 1 + .018 * quiver);
  canvas.drawPath(_cicadaBody, _cicadaBodyPaint);
  _stroke(canvas, _cicadaRibs, const Color(0xFF263B2A), .62, 1.2);
  canvas.restore();

  final wingPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(2, -21),
      const Offset(33, 37),
      [
        _a(const Color(0xFFDAE599), .70),
        _a(const Color(0xFFB8D294), .52 + strength * .12),
        _a(const Color(0xFF9DC78A), .24),
      ],
      const [0, .52, 1],
    );
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.rotate(-.034 - strength * .13 + quiver * .032);
    canvas.drawPath(_cicadaWing, wingPaint);
    _stroke(
      canvas,
      _cicadaWing,
      const Color(0xFFDEF2AF),
      .70,
      detail ? 1.05 : 2.7,
    );
    if (detail) _stroke(canvas, _cicadaVeins, const Color(0xFFE6EEB3), .64, .8);
    canvas.restore();
  }

  canvas.drawPath(_cicadaThorax, Paint()..color = const Color(0xFF5F7545));
  _stroke(
    canvas,
    _cicadaThorax,
    const Color(0xFFB8C575),
    .75,
    detail ? .85 : 2,
  );
  canvas.drawPath(_cicadaHead, Paint()..color = const Color(0xFF809458));
  for (final side in [-1.0, 1.0]) {
    _ellipse(
      canvas,
      side * 13,
      -37,
      5.1,
      6.3,
      const Color(0xFF172822),
      .96,
      side * .22,
    );
    _ellipse(
      canvas,
      side * 13 - 1.1,
      -39,
      1.4,
      1.4,
      const Color(0xFFE2EFA8),
      .70,
    );
  }
  canvas.restore();
}

void _cicadaWaves(Canvas canvas, double seconds) {
  canvas.save();
  canvas.translate(_cicadaPerch.dx, _cicadaPerch.dy + 6);
  canvas.rotate(-.22);
  for (final onset in holidayCicadaCalls) {
    final progress = (seconds - onset) / 1.58;
    if (progress <= 0 || progress >= 1) continue;
    final radius = 23 + 112 * progress;
    final wave = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2,
          height: radius * 1.36,
        ),
        -2.9,
        3.55,
      )
      ..addArc(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.76,
          height: radius * 1.20,
        ),
        .74,
        1.81,
      );
    final opacity = math.sin(math.pi * progress) * (1 - progress * .55);
    _stroke(canvas, wave, const Color(0xFFDCEC93), .62 * opacity, 1.5);
  }
  canvas.restore();
}

void _xiaoshu(Canvas canvas, double seconds) {
  final strength = holidayCicadaEnergy(seconds);
  final sway = math.sin(_phase(seconds));
  _glow(canvas, 475 + sway * 24, 22, 179, const Color(0xFFD2DC7F), .20);
  _glow(canvas, 424, 112, 124, const Color(0xFFC6DB78), .16 * strength);
  for (final (i, (position, length, width, angle, color, opacity))
      in _cicadaCanopy.indexed) {
    final breeze = math.sin(_phase(seconds, 2, i * .65)) * .13;
    _leaf(
      canvas,
      position.dx,
      position.dy,
      length,
      width,
      angle + breeze,
      color,
      opacity,
    );
  }
  canvas.drawPath(_cicadaBranch, _cicadaBranchPaint);
  _stroke(canvas, _cicadaBark, const Color(0xFFB1A662), .36, 1.4);
  _cicadaWaves(canvas, seconds);
  _cicada(canvas, _cicadaPerch, 1.14, .64 + sway * .018, seconds, strength);
}

void _cicadaBadge(Canvas canvas, double seconds) {
  _cicada(
    canvas,
    const Offset(0, -3),
    .53,
    .6,
    seconds,
    holidayCicadaEnergy(seconds),
    detail: false,
  );
}
