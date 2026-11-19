part of 'holiday_glass_scene.dart';

final _chrysanthemumPetal = Path()
  ..moveTo(0, 0)
  ..cubicTo(24, -6, 52, -11, 76, -14)
  ..cubicTo(90, -16, 102, -12, 100, -5)
  ..cubicTo(98, 1, 83, 6, 67, 6)
  ..cubicTo(38, 6, 15, 4, 0, 0)
  ..close();

final _chrysanthemumFold = Path()
  ..moveTo(0, 0)
  ..cubicTo(31, -2, 58, -3, 83, -7)
  ..cubicTo(92, -8, 98, -9, 100, -5)
  ..cubicTo(98, 1, 83, 6, 67, 6)
  ..cubicTo(38, 6, 15, 4, 0, 0)
  ..close();

final _chrysanthemumVein = Path()
  ..moveTo(21, -1)
  ..cubicTo(44, -2, 66, -4, 87, -8);

final _chrysanthemumStems = Path()
  ..moveTo(0, 0)
  ..cubicTo(1, -49, 7, -91, 23, -126)
  ..moveTo(3, -45)
  ..cubicTo(-23, -64, -57, -81, -80, -100);

final _chrysanthemumLeaf = Path()
  ..moveTo(0, 0)
  ..cubicTo(16, -9, 17, -19, 30, -21)
  ..lineTo(28, -13)
  ..cubicTo(39, -20, 42, -27, 54, -25)
  ..lineTo(51, -16)
  ..cubicTo(63, -20, 69, -22, 78, -18)
  ..lineTo(73, -12)
  ..cubicTo(82, -15, 90, -10, 99, -6)
  ..cubicTo(87, -3, 88, 3, 77, 5)
  ..lineTo(77, 12)
  ..cubicTo(65, 9, 62, 16, 48, 13)
  ..lineTo(51, 7)
  ..cubicTo(36, 13, 31, 18, 23, 11)
  ..lineTo(27, 4)
  ..cubicTo(15, 6, 9, 5, 0, 0)
  ..close();

final _chrysanthemumLeafVein = Path()
  ..moveTo(2, 0)
  ..quadraticBezierTo(50, -3, 87, -7)
  ..moveTo(25, -1)
  ..lineTo(38, -15)
  ..moveTo(43, -2)
  ..lineTo(52, 7)
  ..moveTo(52, -4)
  ..lineTo(63, -14)
  ..moveTo(72, -5)
  ..lineTo(81, 1);

final _chrysanthemumLeafPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(0, 8),
    const Offset(97, -13),
    const [Color(0xFF2B4746), Color(0xFF5A7764), Color(0xFF849071)],
    const [0, .60, 1],
  );
final _chrysanthemumFoldPaint = Paint()..color = const Color(0x306E3A22);

const _chrysanthemumFoliage = [
  (position: Offset(2, -26), angle: -2.91, length: .82, width: .72),
  (position: Offset(5, -54), angle: -.33, length: .71, width: .68),
  (position: Offset(-38, -73), angle: 2.99, length: .43, width: .60),
  (position: Offset(10, -84), angle: -2.36, length: .44, width: .53),
];

typedef _ChrysanthemumPalette = ({Color root, Color face, Color tip});

const _chrysanthemumAmber = (
  root: Color(0xFF8E5023),
  face: Color(0xFFE89E45),
  tip: Color(0xFFFDD17D),
);
const _chrysanthemumRingSpecs = [
  (
    count: 19,
    length: 82.0,
    width: 1.07,
    start: .65,
    end: 5.15,
    palette: (
      root: Color(0xFF724122),
      face: Color(0xFFD48741),
      tip: Color(0xFFF8BF6B),
    ),
  ),
  (
    count: 17,
    length: 66.0,
    width: .93,
    start: 1.30,
    end: 5.75,
    palette: _chrysanthemumAmber,
  ),
  (
    count: 13,
    length: 47.0,
    width: .82,
    start: 1.85,
    end: 6.22,
    palette: (
      root: Color(0xFF9C5A28),
      face: Color(0xFFF0A94C),
      tip: Color(0xFFFFDA83),
    ),
  ),
  (
    count: 10,
    length: 29.0,
    width: .64,
    start: 2.10,
    end: 6.46,
    palette: (
      root: Color(0xFF9E5A2C),
      face: Color(0xFFF3AA4A),
      tip: Color(0xFFFFDD91),
    ),
  ),
];

({Paint face, Paint vein}) _chrysanthemumPetalPaint(
  _ChrysanthemumPalette palette,
  double light,
) => (
  face: Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 3),
      const Offset(100, -10),
      [palette.root, palette.face, _mix(palette.root, palette.tip, light)],
      const [0, .48, 1],
    ),
  vein: Paint()
    ..color = _a(palette.tip, .27)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = .77,
);

final _chrysanthemumRings = _chrysanthemumRingSpecs.indexed
    .map((entry) {
      final (row, spec) = entry;
      return (
        start: spec.start,
        end: spec.end,
        petals: List.generate(spec.count, (i) {
          final seed = 7000 + row * 64 + i;
          final angle =
              i / spec.count * _tau +
              row * .29 +
              (holidayRandom(seed) - .5) * .15;
          final light =
              .82 +
              .18 *
                  (.56 * holidayRandom(seed + 1200) +
                      .44 * (.5 + .5 * math.sin(angle)));
          return (
            angle: angle,
            length: spec.length * (.88 + holidayRandom(seed + 300) * .25),
            width: spec.width * (.80 + holidayRandom(seed + 600) * .32),
            delay: holidayRandom(seed + 900) * .70,
            paint: _chrysanthemumPetalPaint(spec.palette, light),
          );
        }, growable: false),
      );
    })
    .toList(growable: false);

const _chrysanthemumDewTips = {
  2: (radius: 4.6, gathersAt: 4.55),
  5: (radius: 5.7, gathersAt: 5.08),
  8: (radius: 3.6, gathersAt: 5.40),
};

final _chrysanthemumPollen = List.generate(17, (i) {
  final angle = i * 2.39996;
  final radius = 2.1 * math.sqrt(i);
  return (
    x: math.cos(angle) * radius,
    y: math.sin(angle) * radius,
    size: .8 + .85 * holidayRandom(8800 + i),
  );
}, growable: false);

void _paintChrysanthemumPetal(
  Canvas canvas,
  double length,
  double width,
  double angle,
  ({Paint face, Paint vein}) paint,
) {
  canvas.save();
  canvas.rotate(angle);
  canvas.scale(length / 100, width);
  canvas.drawPath(_chrysanthemumPetal, paint.face);
  canvas.drawPath(_chrysanthemumFold, _chrysanthemumFoldPaint);
  canvas.drawPath(_chrysanthemumVein, paint.vein);
  canvas.restore();
}

void _chrysanthemumBloom(Canvas canvas, double seconds) {
  final settling = 1 - holidaySmooth(10.65, _loop, seconds);
  final dew = <({Offset center, double size, double opacity, double time})>[];
  canvas.save();
  canvas.scale(1, .75);
  canvas.rotate(-.14 + .019 * math.sin(_phase(seconds, 2, .8)));
  for (final (row, ring) in _chrysanthemumRings.indexed) {
    for (final (index, petal) in ring.petals.indexed) {
      final opening =
          holidaySmooth(
            ring.start + petal.delay,
            ring.end + petal.delay,
            seconds,
          ) *
          settling;
      final closed = .30 + row * .045;
      final length = petal.length * (closed + (1 - closed) * opening);
      final angle =
          petal.angle +
          (1 - opening) * .37 +
          .023 * math.sin(_phase(seconds, 2, index * .71));
      final width = petal.width * (.67 + .33 * opening);
      _paintChrysanthemumPetal(canvas, length, width, angle, petal.paint);

      final drop = row == 0 ? _chrysanthemumDewTips[index] : null;
      if (drop != null) {
        final formed =
            holidaySmooth(drop.gathersAt, drop.gathersAt + 1.6, seconds) *
            settling;
        final size = drop.radius * formed;
        final tip = length * .965;
        final sin = math.sin(angle), cos = math.cos(angle);
        dew.add((
          center: Offset(
            tip * cos + 5.6 * width * sin,
            tip * sin - 5.6 * width * cos + size * .48,
          ),
          size: size,
          opacity: formed,
          time: seconds + index * .22,
        ));
      }
    }
  }
  _ellipse(canvas, 0, 0, 9.3, 8, const Color(0xFFAD692E), 1);
  for (final grain in _chrysanthemumPollen) {
    _ellipse(
      canvas,
      grain.x,
      grain.y,
      grain.size,
      grain.size * 1.12,
      const Color(0xFFFFDA7D),
      .71,
    );
  }
  for (final drop in dew) {
    _dewDrop(canvas, drop.center, drop.size, drop.opacity, drop.time, 1.23);
  }
  canvas.restore();
}

final _chrysanthemumBudPaint = _chrysanthemumPetalPaint(
  _chrysanthemumAmber,
  .79,
);

void _chrysanthemumBud(Canvas canvas, double seconds) {
  canvas.save();
  canvas.translate(-80, -100);
  canvas.rotate(-.29 + .06 * math.sin(_phase(seconds, 2, .2)));
  for (final (angle, length, width) in const [
    (-2.8, 15.0, .54),
    (-2.26, 20.0, .62),
    (-1.72, 22.0, .65),
    (-1.26, 19.0, .59),
    (-.82, 15.0, .49),
  ]) {
    _paintChrysanthemumPetal(
      canvas,
      length,
      width,
      angle,
      _chrysanthemumBudPaint,
    );
  }
  _ellipse(canvas, 0, 0, 9, 4.5, const Color(0xFF586B53), .96, -.12);
  canvas.restore();
}

void _hanlu(Canvas canvas, double seconds) {
  final light = holidayChrysanthemumLight(seconds);
  _glow(canvas, 397, 70, 244, const Color(0xFF7799B8), .21 + .20 * light);
  _glow(canvas, 512, 161, 124, const Color(0xFFAB9B73), .12 + .14 * light);
  for (var i = 0; i < 4; i++) {
    final drift = 36 * math.sin(_phase(seconds, 1, i * 1.3));
    canvas.save();
    canvas.translate(321 + i * 62.0 + drift, 158 + i * 17.0);
    canvas.scale(1, .11 + i * .019);
    _glow(
      canvas,
      0,
      0,
      150 - i * 9.0,
      const Color(0xFFAFCBE3),
      .11 + .025 * math.sin(_phase(seconds, 1, i.toDouble())),
    );
    canvas.restore();
  }

  canvas.save();
  canvas.translate(389, 243);
  canvas.rotate(.040 * math.sin(_phase(seconds, 2, .26)));
  _stroke(canvas, _chrysanthemumStems, const Color(0xFF354947), .84, 5.4);
  _stroke(canvas, _chrysanthemumStems, const Color(0xFF869974), .77, 2.1);
  for (final (i, leaf) in _chrysanthemumFoliage.indexed) {
    canvas.save();
    canvas.translate(leaf.position.dx, leaf.position.dy);
    canvas.rotate(leaf.angle + .054 * math.sin(_phase(seconds, 2, i * .49)));
    canvas.scale(leaf.length, leaf.width);
    canvas.drawPath(_chrysanthemumLeaf, _chrysanthemumLeafPaint);
    _stroke(canvas, _chrysanthemumLeafVein, const Color(0xFFADBE94), .58, .85);
    canvas.restore();
  }
  _chrysanthemumBud(canvas, seconds);
  canvas.translate(23, -126);
  _chrysanthemumBloom(canvas, seconds);
  canvas.restore();
}

final _chrysanthemumBadgePaint = _chrysanthemumPetalPaint(
  _chrysanthemumAmber,
  .99,
);

void _chrysanthemumBadge(Canvas canvas, double seconds) {
  final sway = .11 * math.sin(_phase(seconds, 2, .4));
  canvas.save();
  canvas.translate(-7, -1);
  canvas.rotate(sway);
  for (var i = 0; i < 9; i++) {
    _paintChrysanthemumPetal(
      canvas,
      17,
      .34,
      i * _tau / 9,
      _chrysanthemumBadgePaint,
    );
  }
  _ellipse(canvas, 0, 0, 5, 4.7, const Color(0xFFC27837), 1);
  _ellipse(canvas, -.75, -.82, 2.4, 2.2, const Color(0xFFFFDC81), 1);
  canvas.restore();
  _dewDrop(canvas, Offset(17 + sway * 9, 5), 7.6, .99, seconds, 1.16);
}
