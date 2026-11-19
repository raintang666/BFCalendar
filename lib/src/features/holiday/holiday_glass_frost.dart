part of 'holiday_glass_scene.dart';

const _rimeWhite = Color(0xFFE1F3FC);

final _persimmonBranch = Path()
  ..moveTo(571, 63)
  ..cubicTo(519, 58, 482, 79, 442, 91)
  ..cubicTo(395, 106, 339, 101, 287, 126)
  ..moveTo(477, 80)
  ..quadraticBezierTo(485, 96, 481, 121)
  ..moveTo(389, 102)
  ..cubicTo(385, 114, 389, 126, 395, 138)
  ..moveTo(432, 94)
  ..quadraticBezierTo(406, 83, 402, 70)
  ..moveTo(524, 69)
  ..quadraticBezierTo(521, 88, 510, 96);

final _persimmonBranchRim = Path()
  ..moveTo(550, 62)
  ..cubicTo(517, 62, 475, 81, 443, 89)
  ..cubicTo(400, 102, 373, 102, 346, 106)
  ..moveTo(478, 82)
  ..quadraticBezierTo(486, 103, 481, 119);

final _persimmonFruit = Path()
  ..moveTo(0, -32)
  ..cubicTo(-16, -36, -37, -29, -42, -13)
  ..cubicTo(-49, 6, -39, 29, -23, 34)
  ..cubicTo(-14, 38, -6, 38, 0, 36)
  ..cubicTo(7, 38, 16, 37, 24, 33)
  ..cubicTo(38, 25, 47, 11, 43, -9)
  ..cubicTo(40, -26, 18, -36, 0, -32)
  ..close();

final _persimmonSepals = Path()
  ..moveTo(0, -32)
  ..cubicTo(-8, -36, -16, -36, -23, -39)
  ..quadraticBezierTo(-21, -33, -28, -30)
  ..quadraticBezierTo(-17, -26, -7, -29)
  ..quadraticBezierTo(-3, -28, -2, -22)
  ..quadraticBezierTo(3, -26, 5, -29)
  ..quadraticBezierTo(13, -25, 23, -25)
  ..quadraticBezierTo(20, -31, 28, -34)
  ..quadraticBezierTo(15, -34, 8, -36)
  ..close();

final _persimmonShoulder = Path()
  ..moveTo(-47, -40)
  ..lineTo(47, -40)
  ..lineTo(47, -6)
  ..cubicTo(38, -10, 33, -10, 27, -15)
  ..cubicTo(23, -19, 18, -12, 10, -17)
  ..cubicTo(4, -21, 2, -14, -7, -14)
  ..cubicTo(-13, -12, -18, -20, -24, -14)
  ..cubicTo(-32, -10, -36, -17, -48, -11)
  ..close();

final _persimmonLeaf = Path()
  ..moveTo(0, 0)
  ..cubicTo(20, -22, 48, -32, 80, -19)
  ..cubicTo(69, -3, 44, 19, 0, 0)
  ..close();

final _persimmonLeafRim = Path()
  ..moveTo(5, -5)
  ..cubicTo(21, -22, 49, -31, 79, -19)
  ..cubicTo(71, -8, 59, 1, 47, 5);

final _persimmonLeafVeins = Path()
  ..moveTo(0, 0)
  ..cubicTo(28, -10, 57, -11, 78, -19)
  ..moveTo(20, -6)
  ..lineTo(29, -19)
  ..moveTo(26, -8)
  ..lineTo(39, 6)
  ..moveTo(37, -10)
  ..lineTo(48, -25)
  ..moveTo(47, -12)
  ..lineTo(59, -1)
  ..moveTo(57, -14)
  ..lineTo(66, -24);

Paint _persimmonSkin(List<Color> colors) =>
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(5, 12),
        59,
        colors,
        const [0, .36, .73, 1],
        TileMode.clamp,
        null,
        const Offset(-16, -15),
        2,
      );

final _persimmonAmber = _persimmonSkin(const [
  Color(0xFFFFD691),
  Color(0xFFF49844),
  Color(0xFFD05E28),
  Color(0xFF913027),
]);
final _persimmonRusset = _persimmonSkin(const [
  Color(0xFFFDBC6D),
  Color(0xFFE77A38),
  Color(0xFFB64123),
  Color(0xFF772C26),
]);
final _persimmonSepalPaint = Paint()..color = const Color(0xFF6D7149);
final _persimmonPorePaint = Paint()..color = _a(const Color(0xFF754530), .24);

final _persimmonPores = _persimmonPoreShape();

Path _persimmonPoreShape() {
  final path = Path();
  for (var i = 0; i < 38; i++) {
    final x = (holidayRandom(9700 + i) - .5) * 79;
    final y = -1 + holidayRandom(9800 + i) * 36;
    final size = .36 + holidayRandom(9900 + i) * .69;
    path.addOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: size * 2,
        height: size * 1.34,
      ),
    );
  }
  return path;
}

Paint _persimmonLeafTone(List<Color> colors) => Paint()
  ..shader = ui.Gradient.linear(
    const Offset(12, -26),
    const Offset(49, 9),
    colors,
    const [0, .65, 1],
  );

final _persimmonCopperLeaf = _persimmonLeafTone(const [
  Color(0xFF935E37),
  Color(0xFF79422F),
  Color(0xFF543830),
]);
final _persimmonGreenLeaf = _persimmonLeafTone(const [
  Color(0xFF6D7858),
  Color(0xFF456051),
  Color(0xFF2B4342),
]);

final _rimeGrains = List.generate(112, (i) {
  final seed = 9100 + i;
  final depth = holidayRandom(seed + 200);
  return (
    x: (holidayRandom(seed) - .5) * (75 + depth * 21),
    y: -35 + math.pow(depth, 1.4).toDouble() * 39,
    size: .42 + holidayRandom(seed + 500) * 1.46,
    delay: depth * 2.4 + holidayRandom(seed + 800) * 1.1,
    opacity: .91 - depth * .52,
  );
}, growable: false);

const _persimmonCrystals = [
  (Offset(-28, -21), 2.74, 12.0, .3),
  (Offset(-17, -27), 3.54, 19.0, .9),
  (Offset(15, -30), 2.60, 16.0, 1.2),
  (Offset(30, -24), 3.38, 14.0, 1.85),
  (Offset(-8, -24), 2.92, 15.0, 2.15),
  (Offset(23, -21), 3.03, 11.0, 2.55),
];

const _leafCrystals = [
  (Offset(20, -14), .50, 10.0),
  (Offset(35, -20), .97, 15.0),
  (Offset(49, -22), 1.45, 13.0),
  (Offset(62, -22), 1.85, 10.0),
];

Path _frostFern(double length, double growth) {
  final twig = Path()
    ..moveTo(0, 0)
    ..lineTo(0, -length * growth);
  for (var i = 1; i <= 4; i++) {
    final u = i * .175;
    final reach = holidaySmooth(u, u + .24, growth) * length * (.29 - u * .19);
    if (reach <= 0) continue;
    final base = -length * u;
    final fork = reach * .55;
    twig
      ..moveTo(-reach, base - reach * .80)
      ..lineTo(0, base)
      ..lineTo(reach, base - reach * .80)
      ..moveTo(-fork, base - fork * .80)
      ..lineTo(-fork * 1.32, base - fork * 1.72)
      ..moveTo(fork, base - fork * .80)
      ..lineTo(fork * 1.32, base - fork * 1.72);
  }
  return twig;
}

void _paintFrostFern(
  Canvas canvas,
  Offset center,
  double angle,
  double length,
  double growth,
  double opacity,
) {
  if (growth <= 0) return;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  _stroke(
    canvas,
    _frostFern(length, growth),
    _rimeWhite,
    opacity * growth,
    .85,
  );
  canvas.restore();
}

void _paintPersimmonCalyx(Canvas canvas, double frost) {
  _line(canvas, 1, -31, -2, -43, const Color(0xFF554E34), 1, 3.35);
  canvas.drawPath(_persimmonSepals, _persimmonSepalPaint);
  _line(canvas, -15, -32, 20, -31, const Color(0xFFB1AB76), .63, .84);
  _stroke(canvas, _persimmonSepals, _rimeWhite, frost * .74, 1.28);
}

void _frostedPersimmon(
  Canvas canvas,
  Offset center,
  double scale,
  double angle,
  Paint skin,
  double seconds,
  double delay,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  canvas.drawPath(_persimmonFruit, skin);
  final frost = holidayFrostGrowth(seconds, delay);
  canvas.save();
  canvas.clipPath(_persimmonFruit);
  canvas.drawPath(_persimmonPores, _persimmonPorePaint);
  if (frost > 0) {
    canvas.drawPath(
      _persimmonShoulder,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -37),
          const Offset(0, -4),
          [
            _a(_rimeWhite, frost * .86),
            _a(const Color(0xFFCCE3F2), frost * .59),
            const Color(0x00BFDFF2),
          ],
          const [0, .45, 1],
        ),
    );
    final grainPaint = Paint();
    for (final grain in _rimeGrains) {
      final growth = holidayFrostGrowth(seconds, delay + grain.delay);
      if (growth <= 0) continue;
      final size = grain.size * growth;
      canvas.save();
      canvas.translate(grain.x, grain.y);
      canvas.rotate(-.53);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size * 2,
          height: size * 1.48,
        ),
        grainPaint..color = _a(_rimeWhite, growth * grain.opacity),
      );
      canvas.restore();
    }
    for (final (point, direction, length, lag) in _persimmonCrystals) {
      _paintFrostFern(
        canvas,
        point,
        direction,
        length,
        holidayFrostGrowth(seconds, delay + lag),
        .91,
      );
    }
  }
  canvas.restore();
  _paintPersimmonCalyx(canvas, frost);
  canvas.restore();
}

void _frostedLeaf(
  Canvas canvas,
  double seconds,
  Offset root,
  double angle,
  double scale,
  Paint tone,
) {
  canvas.save();
  canvas.translate(root.dx, root.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  canvas.drawPath(_persimmonLeaf, tone);
  _stroke(canvas, _persimmonLeafVeins, const Color(0xFFD1B47F), .56, 1.05);
  final frost = holidayFrostGrowth(seconds, -.75);
  _stroke(canvas, _persimmonLeafRim, _rimeWhite, frost * .66, 1.23);
  _stroke(
    canvas,
    _persimmonLeafVeins,
    const Color(0xFFB5D7E6),
    frost * .66,
    .78,
  );
  for (final (point, lag, length) in _leafCrystals) {
    _paintFrostFern(
      canvas,
      point,
      2.58,
      length,
      holidayFrostGrowth(seconds, lag),
      .76,
    );
  }
  canvas.restore();
}

void _frostSpark(
  Canvas canvas,
  double x,
  double y,
  double seconds,
  double peak,
) {
  final pulse =
      holidaySmooth(peak - .25, peak, seconds) *
      (1 - holidaySmooth(peak, peak + .40, seconds));
  if (pulse <= 0) return;
  final radius = 5.8 * pulse;
  _glow(canvas, x, y, radius * 2, const Color(0xFFC8EBFF), .51 * pulse);
  _line(canvas, x - radius, y, x + radius, y, _rimeWhite, pulse, .95);
  _line(canvas, x, y - radius, x, y + radius, _rimeWhite, pulse, .95);
}

void _shuangjiang(Canvas canvas, double seconds) {
  final frost = holidayFrostGrowth(seconds);
  _glow(canvas, 391, 79, 233, const Color(0xFF88B4DB), .18 + .26 * frost);
  _glow(canvas, 462, 167, 157, const Color(0xFFE68A52), .21 - .06 * frost);
  for (var i = 0; i < 3; i++) {
    final drift = 37 * math.sin(_phase(seconds, 1, i * 1.22));
    canvas.save();
    canvas.translate(323 + i * 83.0 + drift, 134 + i * 35.0);
    canvas.scale(1, .13 + i * .017);
    _glow(canvas, 0, 0, 154, const Color(0xFFADCDE2), .08 + .11 * frost);
    canvas.restore();
  }

  canvas.save();
  canvas.translate(555, 75);
  canvas.rotate(.022 * math.sin(_phase(seconds, 2, .33)));
  canvas.translate(-555, -67);
  _stroke(canvas, _persimmonBranch, const Color(0xFF332B26), 1, 7.2);
  _stroke(canvas, _persimmonBranch, const Color(0xFF84684E), .78, 3.7);
  _stroke(
    canvas,
    _persimmonBranchRim,
    const Color(0xFFD1E1E6),
    .58 * frost,
    1.30,
  );
  _frostedLeaf(
    canvas,
    seconds,
    const Offset(365, 105),
    -2.76 + .058 * math.sin(_phase(seconds, 2, 1.1)),
    1.02,
    _persimmonCopperLeaf,
  );
  _frostedLeaf(
    canvas,
    seconds,
    const Offset(403, 71),
    -1.54 + .049 * math.sin(_phase(seconds, 2, .35)),
    .54,
    _persimmonGreenLeaf,
  );
  _frostedLeaf(
    canvas,
    seconds,
    const Offset(509, 96),
    .16 + .041 * math.sin(_phase(seconds, 2, 1.9)),
    .62,
    _persimmonGreenLeaf,
  );
  _frostedPersimmon(
    canvas,
    const Offset(481, 151),
    .89,
    .12,
    _persimmonRusset,
    seconds,
    .42,
  );
  _frostedPersimmon(
    canvas,
    const Offset(396, 177),
    1.12,
    -.08,
    _persimmonAmber,
    seconds,
    0,
  );
  _frostSpark(canvas, 383, 150, seconds, 8.16);
  _frostSpark(canvas, 501, 135, seconds, 8.86);
  canvas.restore();
}

final _frostBadgeRay = _frostFern(9.5, 1);

void _frostedPersimmonBadge(Canvas canvas, double seconds) {
  canvas.save();
  canvas.translate(-7, 1);
  canvas.scale(.39);
  canvas.drawPath(_persimmonFruit, _persimmonAmber);
  _paintPersimmonCalyx(canvas, .40 + .50 * holidayFrostGrowth(seconds));
  canvas.restore();

  canvas.save();
  canvas.translate(17, -8);
  canvas.rotate(.09 * math.sin(_phase(seconds, 2, .4)));
  for (var ray = 0; ray < 6; ray++) {
    _stroke(canvas, _frostBadgeRay, _rimeWhite, .96, .85);
    canvas.rotate(_tau / 6);
  }
  canvas.restore();
}
