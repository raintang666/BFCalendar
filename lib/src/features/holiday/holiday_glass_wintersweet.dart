part of 'holiday_glass_scene.dart';

final _wintersweetBranch = Path()
  ..moveTo(586, 225)
  ..quadraticBezierTo(541, 193, 498, 167)
  ..cubicTo(453, 136, 409, 126, 376, 109)
  ..quadraticBezierTo(350, 96, 324, 91)
  ..lineTo(307, 81)
  ..quadraticBezierTo(333, 87, 360, 97)
  ..cubicTo(397, 114, 441, 124, 483, 143)
  ..quadraticBezierTo(538, 167, 589, 203)
  ..close();

final _wintersweetBranchGrain = Path()
  ..moveTo(583, 210)
  ..cubicTo(529, 176, 479, 151, 441, 137)
  ..quadraticBezierTo(395, 122, 369, 108)
  ..moveTo(571, 211)
  ..quadraticBezierTo(537, 186, 514, 174)
  ..moveTo(501, 153)
  ..quadraticBezierTo(469, 137, 432, 126)
  ..moveTo(388, 112)
  ..lineTo(365, 101);

final _wintersweetSnow = Path()
  ..moveTo(313, 82)
  ..quadraticBezierTo(330, 84, 346, 92)
  ..moveTo(353, 95)
  ..quadraticBezierTo(367, 100, 376, 104)
  ..moveTo(403, 114)
  ..quadraticBezierTo(425, 121, 440, 127)
  ..moveTo(451, 131)
  ..quadraticBezierTo(466, 136, 483, 144)
  ..moveTo(493, 148)
  ..quadraticBezierTo(508, 155, 522, 162)
  ..moveTo(532, 167)
  ..quadraticBezierTo(552, 178, 567, 188)
  ..moveTo(394, 52)
  ..quadraticBezierTo(404, 60, 407, 71)
  ..moveTo(438, 89)
  ..lineTo(448, 76);

final _wintersweetPetal = Path()
  ..moveTo(-1, 4)
  ..cubicTo(-5, -2, -10, -11, -7, -21)
  ..quadraticBezierTo(-6, -28, 0, -31)
  ..quadraticBezierTo(7, -29, 8, -22)
  ..cubicTo(10, -13, 5, -2, 2, 4)
  ..close();

final _wintersweetVein = Path()
  ..moveTo(0, 0)
  ..quadraticBezierTo(-3, -9, -1, -17)
  ..quadraticBezierTo(1, -24, 0, -28);

final _wintersweetBudShell = Path()
  ..moveTo(0, 4)
  ..cubicTo(-9, 5, -13, -7, -7, -13)
  ..quadraticBezierTo(2, -20, 9, -12)
  ..cubicTo(15, -6, 9, 4, 0, 4)
  ..close();

final _wintersweetBudSeam = Path()
  ..moveTo(-3, -12)
  ..quadraticBezierTo(-6, -5, 0, 3)
  ..moveTo(4, -13)
  ..quadraticBezierTo(8, -5, 3, 2);

final _wintersweetBadgeTwig = Path()
  ..moveTo(-11, 18)
  ..quadraticBezierTo(0, 9, 13, -4)
  ..lineTo(22, -9);

final _wintersweetTwigs = [
  (
    path: Path()
      ..moveTo(477, 151)
      ..quadraticBezierTo(456, 128, 432, 112)
      ..quadraticBezierTo(414, 95, 405, 68)
      ..quadraticBezierTo(397, 55, 384, 47),
    width: 5.1,
  ),
  (
    path: Path()
      ..moveTo(427, 125)
      ..quadraticBezierTo(400, 135, 373, 148)
      ..quadraticBezierTo(351, 158, 331, 156),
    width: 4.2,
  ),
  (
    path: Path()
      ..moveTo(425, 102)
      ..quadraticBezierTo(439, 88, 449, 74)
      ..lineTo(456, 61),
    width: 3.1,
  ),
  (
    path: Path()
      ..moveTo(521, 173)
      ..quadraticBezierTo(512, 183, 501, 201)
      ..lineTo(482, 211),
    width: 3.5,
  ),
  (
    path: Path()
      ..moveTo(355, 102)
      ..quadraticBezierTo(336, 108, 320, 117)
      ..lineTo(308, 123),
    width: 2.6,
  ),
  (
    path: Path()
      ..moveTo(543, 182)
      ..quadraticBezierTo(554, 155, 571, 149),
    width: 3.2,
  ),
];

const _wintersweetBuds = [
  (Offset(309, 82), .64, -1.0),
  (Offset(384, 48), .39, -.65),
  (Offset(455, 62), .55, .64),
  (Offset(331, 156), .42, -1.1),
  (Offset(483, 210), .48, -.96),
  (Offset(570, 149), .60, .7),
];
const _wintersweetBlossoms = [
  (Offset(321, 115), .57, -.44, .75, .3, 2.3),
  (Offset(405, 67), .66, -.40, .81, 1.0, 2.8),
  (Offset(372, 147), .72, .22, .68, -.3, 1.45),
  (Offset(481, 146), .87, .52, .91, .4, 3.35),
  (Offset(503, 197), .65, .17, .72, 1.4, 4.15),
  (Offset(429, 108), 1.15, -.21, .94, 0.0, .95),
];
final _wintersweetBark = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(367, 98),
    const Offset(343, 163),
    const [Color(0xFF97766A), Color(0xFF604743), Color(0xFF42343E)],
    const [0, .48, 1],
  );

void _paintWintersweetBud(
  Canvas canvas,
  Offset center,
  double size,
  double tilt, [
  double opacity = 1,
]) {
  if (opacity <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(tilt);
  canvas.scale(size);
  canvas.drawPath(
    _wintersweetBudShell,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, -17),
        const Offset(1, 5),
        [
          _a(const Color(0xFFF9DC82), opacity),
          _a(const Color(0xFFC99246), opacity),
          _a(const Color(0xFF624236), opacity),
        ],
        const [0, .58, 1],
      ),
  );
  _stroke(canvas, _wintersweetBudSeam, const Color(0xFFFEDF8E), .62 * opacity);
  canvas.restore();
}

void _paintWintersweetFlower(
  Canvas canvas,
  Offset center,
  double size,
  double tilt,
  double bloom,
  double depth, [
  double turns = 0,
]) {
  final bud = 1 - holidaySmooth(.17, .61, bloom);
  _paintWintersweetBud(canvas, center, size * .84, tilt, bud);
  if (bloom <= .01) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(tilt);
  canvas.scale(size, size * depth);
  final opacity = holidaySmooth(.01, .23, bloom);
  final spread = .23 + .77 * bloom;
  final outer = ui.Gradient.linear(
    const Offset(0, -30),
    const Offset(1, 5),
    [
      _a(const Color(0xFFFFF3BB), opacity),
      _a(const Color(0xFFF1CC71), opacity),
      _a(const Color(0xFFD19148), opacity),
      _a(const Color(0xFF814834), opacity),
    ],
    const [0, .44, .78, 1],
  );
  final inner = ui.Gradient.linear(
    const Offset(0, -30),
    const Offset(0, 4),
    [
      _a(const Color(0xFFF7DB89), opacity),
      _a(const Color(0xFFDEA554), opacity),
      _a(const Color(0xFF703935), opacity),
    ],
    const [0, .42, 1],
  );
  final petalPaint = Paint();
  for (final (count, ring, gradient) in [(9, 1.0, outer), (6, .65, inner)]) {
    petalPaint.shader = gradient;
    for (var n = 0; n < count; n++) {
      final waviness = holidayRandom(n + count * 10);
      canvas.save();
      canvas.rotate(n * _tau / count + turns + ring * .25 + waviness * .13);
      canvas.translate(0, -3 * spread * ring);
      canvas.scale(
        ring * (.61 + .45 * waviness),
        ring * spread * (.82 + waviness * .24),
      );
      canvas.drawPath(_wintersweetPetal, petalPaint);
      _stroke(
        canvas,
        _wintersweetPetal,
        const Color(0xFFFFEAA2),
        opacity * .47,
        .86,
      );
      _stroke(
        canvas,
        _wintersweetVein,
        const Color(0xFFFFF9CD),
        opacity * .43,
        .86,
      );
      canvas.restore();
    }
  }
  _ellipse(
    canvas,
    0,
    0,
    6.3 * spread,
    5.4 * spread,
    const Color(0xFF894436),
    opacity,
  );
  for (var i = 0; i < 6; i++) {
    final angle = i * _tau / 6 + .34;
    final x = math.cos(angle) * spread * 4;
    final y = math.sin(angle) * spread * 3.2;
    _ellipse(canvas, x, y, 1.5, 1.15, const Color(0xFFFFDB8C), opacity, angle);
  }
  canvas.restore();
}

void _xiaohan(Canvas canvas, double t) {
  final bloom = holidayWintersweetOpening(t, .95);
  _glow(canvas, 407, 125, 134, const Color(0xFFEFB068), .075 + .15 * bloom);
  canvas.save();
  canvas.translate(584, 213);
  canvas.rotate(
    .018 * math.sin(_phase(t)) + .012 * math.sin(_phase(t, 2, 1.1)),
  );
  canvas.translate(-584, -213);
  canvas.drawPath(_wintersweetBranch, _wintersweetBark);
  _stroke(canvas, _wintersweetBranchGrain, const Color(0xFFB08773), .53, 1.25);
  for (final twig in _wintersweetTwigs) {
    _stroke(canvas, twig.path, const Color(0xFF574343), 1, twig.width);
    canvas.save();
    canvas.translate(0, -.95);
    _stroke(canvas, twig.path, const Color(0xFFA47F6E), .66, twig.width * .34);
    canvas.restore();
  }
  _stroke(canvas, _wintersweetSnow, const Color(0xFFAAC5D6), .55, 4.4);
  canvas.save();
  canvas.translate(0, -1.35);
  _stroke(canvas, _wintersweetSnow, const Color(0xFFE2EFF6), .75, 1.9);
  canvas.restore();

  for (final (center, size, tilt) in _wintersweetBuds) {
    _paintWintersweetBud(canvas, center, size, tilt);
  }
  for (final (center, size, tilt, depth, turns, start)
      in _wintersweetBlossoms) {
    _paintWintersweetFlower(
      canvas,
      center,
      size,
      tilt,
      holidayWintersweetOpening(t, start),
      depth,
      turns,
    );
  }
  canvas.restore();

  for (var i = 0; i < 26; i++) {
    final flake = _particles[i];
    final u = (flake.y + t / _loop * (1 + flake.speed.round())) % 1;
    final x = 246 + flake.x * 348 - 49 * u;
    final y = 12 + u * 205;
    final opacity = math.sin(math.pi * u) * (.16 + flake.r * .32);
    _ellipse(
      canvas,
      x,
      y,
      .65 + flake.r * 1.55,
      .59 + flake.r * .86,
      const Color(0xFFE0EEF7),
      opacity,
      -.35,
    );
  }
}

void _wintersweetDateBadge(Canvas canvas, double t) {
  final bloom = .38 + .62 * holidayWintersweetOpening(t, .95);
  _stroke(canvas, _wintersweetBadgeTwig, const Color(0xFFAF8878), 1, 3.2);
  _paintWintersweetBud(canvas, const Offset(15, -5), .62, .48);
  _paintWintersweetFlower(canvas, const Offset(-4, -5), .86, -.19, bloom, .94);
}
