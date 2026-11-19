part of 'holiday_glass_scene.dart';

const _autumnGold = Color(0xFFE6A266);

final _autumnLeafShape = Path()
  ..moveTo(0, 39)
  ..cubicTo(-10, 31, -22, 33, -33, 25)
  ..cubicTo(-40, 21, -48, 9, -52, 3)
  ..quadraticBezierTo(-41, 0, -31, 6)
  ..quadraticBezierTo(-35, -6, -46, -25)
  ..quadraticBezierTo(-28, -22, -17, -13)
  ..quadraticBezierTo(-20, -24, -16, -37)
  ..quadraticBezierTo(-6, -41, 1, -58)
  ..quadraticBezierTo(11, -43, 19, -35)
  ..quadraticBezierTo(23, -25, 17, -11)
  ..quadraticBezierTo(32, -24, 48, -25)
  ..quadraticBezierTo(39, -8, 31, 3)
  ..quadraticBezierTo(45, -1, 51, 4)
  ..cubicTo(39, 22, 27, 28, 16, 31)
  ..quadraticBezierTo(8, 33, 0, 39)
  ..close();

final _autumnLeafStalk = Path()
  ..moveTo(0, 36)
  ..quadraticBezierTo(-3, 44, 7, 56);

final _autumnLeafVeins = Path()
  ..moveTo(0, 38)
  ..quadraticBezierTo(-6, 9, 1, -55)
  ..moveTo(-1, 29)
  ..quadraticBezierTo(-26, 20, -48, 5)
  ..moveTo(-2, 18)
  ..quadraticBezierTo(-29, 5, -42, -21)
  ..moveTo(-4, 3)
  ..quadraticBezierTo(-17, -10, -14, -33)
  ..moveTo(0, 30)
  ..quadraticBezierTo(24, 21, 48, 5)
  ..moveTo(-1, 18)
  ..quadraticBezierTo(24, 8, 45, -22)
  ..moveTo(-1, 2)
  ..quadraticBezierTo(14, -13, 17, -34);

final _autumnFineVeins = Path()
  ..moveTo(-12, 24)
  ..quadraticBezierTo(-25, 27, -36, 20)
  ..moveTo(-20, 14)
  ..lineTo(-34, 9)
  ..moveTo(-18, 8)
  ..lineTo(-27, -9)
  ..moveTo(-15, -4)
  ..lineTo(-30, -13)
  ..moveTo(-5, -20)
  ..lineTo(-12, -25)
  ..moveTo(14, 23)
  ..quadraticBezierTo(24, 26, 30, 20)
  ..moveTo(15, 10)
  ..quadraticBezierTo(30, 7, 34, 0)
  ..moveTo(13, 5)
  ..lineTo(20, -14)
  ..moveTo(6, -18)
  ..lineTo(14, -28);

final _autumnWater = Path()
  ..moveTo(-12, 282)
  ..cubicTo(94, 279, 165, 233, 229, 218)
  ..cubicTo(300, 202, 347, 208, 403, 214)
  ..cubicTo(466, 221, 520, 202, 584, 199)
  ..lineTo(584, 290)
  ..lineTo(-12, 290)
  ..close();

final _autumnHorizon = Path()
  ..moveTo(224, 218)
  ..cubicTo(302, 199, 350, 208, 403, 214)
  ..cubicTo(466, 221, 520, 202, 584, 199);

final _autumnCrown = Path()
  ..moveTo(277, 99)
  ..cubicTo(271, 85, 284, 63, 304, 54)
  ..cubicTo(295, 35, 325, 16, 351, 23)
  ..cubicTo(364, 3, 394, 5, 412, 16)
  ..cubicTo(428, 5, 455, 12, 464, 28)
  ..cubicTo(487, 24, 507, 38, 511, 58)
  ..cubicTo(538, 59, 545, 81, 533, 99)
  ..cubicTo(538, 114, 514, 128, 489, 128)
  ..cubicTo(480, 145, 450, 149, 432, 135)
  ..cubicTo(408, 151, 379, 150, 363, 135)
  ..cubicTo(336, 143, 321, 129, 313, 120)
  ..cubicTo(291, 123, 280, 115, 277, 99)
  ..close();

final _autumnTrunk = Path()
  ..moveTo(389, 224)
  ..cubicTo(402, 216, 407, 193, 412, 165)
  ..cubicTo(420, 123, 414, 95, 404, 69)
  ..lineTo(410, 61)
  ..cubicTo(425, 84, 432, 117, 428, 155)
  ..cubicTo(426, 186, 426, 215, 444, 226)
  ..cubicTo(424, 222, 415, 228, 389, 224)
  ..close();

final _autumnBark = Path()
  ..moveTo(413, 214)
  ..quadraticBezierTo(423, 172, 421, 128)
  ..quadraticBezierTo(422, 104, 414, 83)
  ..moveTo(421, 214)
  ..quadraticBezierTo(420, 192, 424, 172);

final _autumnBoughs = [
  (
    path: Path()
      ..moveTo(417, 133)
      ..quadraticBezierTo(400, 108, 372, 93)
      ..quadraticBezierTo(350, 79, 315, 81),
    width: 6.7,
  ),
  (
    path: Path()
      ..moveTo(416, 113)
      ..quadraticBezierTo(405, 91, 388, 72)
      ..quadraticBezierTo(378, 60, 361, 45),
    width: 5.0,
  ),
  (
    path: Path()
      ..moveTo(422, 108)
      ..quadraticBezierTo(424, 72, 414, 39)
      ..quadraticBezierTo(408, 27, 395, 19),
    width: 4.7,
  ),
  (
    path: Path()
      ..moveTo(425, 139)
      ..quadraticBezierTo(442, 105, 463, 94)
      ..quadraticBezierTo(483, 82, 511, 79),
    width: 6.2,
  ),
  (
    path: Path()
      ..moveTo(428, 121)
      ..quadraticBezierTo(441, 95, 448, 68)
      ..quadraticBezierTo(456, 46, 473, 36),
    width: 4.4,
  ),
  (
    path: Path()
      ..moveTo(438, 121)
      ..quadraticBezierTo(461, 113, 492, 115),
    width: 3.5,
  ),
  (
    path: Path()
      ..moveTo(395, 104)
      ..quadraticBezierTo(369, 109, 345, 117),
    width: 3.1,
  ),
  (
    path: Path()
      ..moveTo(386, 74)
      ..quadraticBezierTo(360, 77, 334, 62),
    width: 2.6,
  ),
];

const _autumnTreeLeaves = [
  (Offset(302, 90), .22, -.82, .38, .65),
  (Offset(319, 67), .26, -1.41, .57, .82),
  (Offset(332, 100), .24, .93, .76, .63),
  (Offset(347, 45), .27, -.55, .45, .72),
  (Offset(357, 78), .25, 1.08, .42, .84),
  (Offset(366, 31), .22, -.47, .68, .72),
  (Offset(375, 110), .30, .48, .66, .81),
  (Offset(379, 66), .30, -1.12, .77, .87),
  (Offset(393, 43), .28, -.48, .49, .80),
  (Offset(408, 20), .22, .22, .46, .56),
  (Offset(407, 107), .27, -.62, .51, .77),
  (Offset(424, 55), .29, .63, .59, .88),
  (Offset(436, 38), .23, .94, .63, .61),
  (Offset(439, 110), .26, -.47, .68, .71),
  (Offset(453, 80), .28, 1.25, .78, .76),
  (Offset(467, 52), .26, .96, .58, .58),
  (Offset(481, 98), .27, -.72, .70, .66),
  (Offset(496, 69), .25, .63, .71, .53),
  (Offset(510, 92), .25, 1.43, .68, .55),
  (Offset(491, 122), .22, 1.24, .75, .59),
];

final _autumnWaterPaint = Paint()
  ..shader = ui.Gradient.linear(const Offset(0, 202), const Offset(0, 288), [
    _a(const Color(0xFF536F79), .30),
    const Color(0x003E5865),
  ]);

final _autumnCrownPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(309, 23),
    const Offset(498, 132),
    [
      _a(const Color(0xFF8E9F5B), .30),
      _a(const Color(0xFF937E4B), .28),
      _a(const Color(0xFF655341), .16),
    ],
    const [0, .48, 1],
  );

final _autumnWoodPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(400, 129),
    const Offset(438, 180),
    const [Color(0xFF9C7858), Color(0xFF76563E), Color(0xFF4A3B34)],
    const [0, .45, 1],
  );

void _autumnLandscape(Canvas canvas) {
  _glow(canvas, 442, 117, 242, const Color(0xFF719AB3), .21);
  _glow(canvas, 284, 63, 218, const Color(0xFF7BA27E), .08);
}

void _autumnLeaf(
  Canvas canvas,
  Offset position,
  double scale,
  double angle,
  double autumn,
  double opacity, {
  double width = 1,
  double height = 1,
}) {
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(angle);
  canvas.scale(scale * width, scale * height);
  final rim = _mix(const Color(0xFFDCE5AD), const Color(0xFFFEC782), autumn);
  canvas.drawPath(
    _autumnLeafShape,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-35, -39),
        const Offset(44, 37),
        [
          _a(
            _mix(const Color(0xFFC6DA93), const Color(0xFFFECD85), autumn),
            opacity,
          ),
          _a(
            _mix(const Color(0xFF92AD66), const Color(0xFFD38852), autumn),
            opacity,
          ),
          _a(
            _mix(const Color(0xFF3C6C4E), const Color(0xFF7C4133), autumn),
            opacity,
          ),
        ],
        const [0, .46, 1],
      ),
  );
  _stroke(canvas, _autumnLeafShape, rim, .60 * opacity, 1.1);
  _stroke(
    canvas,
    _autumnLeafStalk,
    const Color(0xFFB38653),
    .92 * opacity,
    1.8,
  );
  final vein = _mix(const Color(0xFF446943), const Color(0xFF773F2D), autumn);
  _stroke(canvas, _autumnLeafVeins, vein, .62 * opacity, 1.25);
  _stroke(canvas, _autumnFineVeins, rim, .38 * opacity, .68);
  canvas.restore();
}

void _autumnTree(Canvas canvas, double seconds) {
  canvas.drawPath(_autumnCrown, _autumnCrownPaint);
  for (final bough in _autumnBoughs) {
    _stroke(canvas, bough.path, const Color(0xFF654D3E), .94, bough.width);
    _stroke(
      canvas,
      bough.path,
      const Color(0xFFBF955E),
      .36,
      math.max(.5, bough.width * .18),
    );
  }
  canvas.drawPath(_autumnTrunk, _autumnWoodPaint);
  _stroke(canvas, _autumnBark, const Color(0xFFCAA171), .48, 1.05);
  for (final (i, (position, size, angle, color, opacity))
      in _autumnTreeLeaves.indexed) {
    final breeze = math.sin(_phase(seconds, 2, i * .43)) * .10;
    _autumnLeaf(canvas, position, size, angle + breeze, color, opacity);
  }
}

void _autumnFallingLeaves(Canvas canvas, double seconds) {
  final returnToBough = holidaySmooth(11.55, _loop, seconds);
  for (final (i, leaf) in holidayAutumnDrops.indexed) {
    final breeze = math.sin(_phase(seconds, 2, i * .54)) * .10;
    final age = seconds - leaf.start;
    if (age < 0 || returnToBough > 0) {
      final attached = age < 0 ? 1.0 : returnToBough;
      _autumnLeaf(
        canvas,
        leaf.from,
        leaf.size,
        leaf.angle + breeze,
        leaf.color,
        attached,
      );
    }
    if (age < 0) continue;

    final progress = holidayClamp(age / leaf.travel);
    final opacity =
        1 - holidaySmooth(leaf.travel + .65, leaf.travel + 1.65, age);
    if (opacity <= 0) continue;
    final settled = holidaySmooth(.81, 1, progress);
    final fallArc = math.sin(math.pi * progress);
    final tumble = fallArc * math.sin(_tau * progress * .92);
    final fall = progress * (.70 + progress * .30);
    final position = Offset(
      holidayLerp(leaf.from.dx, leaf.to.dx, progress) + tumble * leaf.drift,
      holidayLerp(leaf.from.dy, leaf.to.dy, fall) +
          math.sin(_tau * progress) * 7,
    );
    final angle =
        leaf.angle +
        breeze * (1 - progress) +
        .78 * math.sin(_tau * progress + i * .3) * fallArc;
    final face = math.cos(_tau * progress * (1.05 + (i % 3) * .16));
    final leafColor = holidayLerp(leaf.color, 1, progress * .86);
    if (leaf.water) {
      _ripple(
        canvas,
        leaf.to.dx,
        leaf.to.dy,
        (age - leaf.travel) / 1.55,
        const Color(0xFFE0C299),
        1.05,
        1.28,
      );
    }
    _autumnLeaf(
      canvas,
      position,
      leaf.size,
      angle,
      leafColor,
      opacity,
      width: holidayLerp(face, 1, settled),
      height: holidayLerp(1, .29, settled),
    );
  }
}

void _liqiu(Canvas canvas, double seconds) {
  _glow(canvas, 386, 68, 173, _autumnGold, .12 + holidayAutumnLight(seconds));
  canvas.drawPath(_autumnWater, _autumnWaterPaint);
  _stroke(canvas, _autumnHorizon, const Color(0xFF9CB6B3), .20, .9);
  for (var i = 0; i < 4; i++) {
    final start =
        264 + i * 64 + 16 * math.sin(_phase(seconds, 1, i.toDouble()));
    final y = 219.0 + i * 8;
    _line(
      canvas,
      start,
      y,
      start + 27 + i * 5,
      y,
      const Color(0xFF97B7B3),
      .16 - i * .025,
      .8,
    );
  }
  _ellipse(canvas, 417, 223, 39, 6, const Color(0xFF1E2521), .26);
  _autumnTree(canvas, seconds);
  _autumnFallingLeaves(canvas, seconds);
}

void _autumnLeafBadge(Canvas canvas, double seconds) {
  final breeze = math.sin(_phase(seconds, 2)) * .16;
  _glow(canvas, 0, -3, 30, _autumnGold, .22);
  _autumnLeaf(canvas, const Offset(0, -3), .47, -.43 + breeze, .92, 1);
}
