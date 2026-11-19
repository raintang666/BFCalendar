part of 'holiday_glass_scene.dart';

final _wheatStem = Path()
  ..moveTo(-18, 23)
  ..cubicTo(-12, 5, -5, -26, 0, -52)
  ..quadraticBezierTo(5, -98, 2, -157);

final _wheatLeaves = Path()
  ..moveTo(-9, -16)
  ..cubicTo(-36, -31, -64, -62, -123, -43)
  ..cubicTo(-77, -45, -50, -15, -9, -16)
  ..close()
  ..moveTo(-8, -27)
  ..cubicTo(14, -53, 47, -61, 93, -92)
  ..cubicTo(63, -55, 25, -46, -8, -27)
  ..close();

final _wheatVeins = Path()
  ..moveTo(-8, -16)
  ..cubicTo(-52, -25, -78, -46, -112, -44)
  ..moveTo(-8, -27)
  ..quadraticBezierTo(47, -64, 83, -85);

final _glume = Path()
  ..moveTo(0, 3)
  ..cubicTo(-13, -4, -16, -21, -10, -32)
  ..quadraticBezierTo(-6, -39, 0, -44)
  ..quadraticBezierTo(9, -38, 13, -25)
  ..cubicTo(16, -13, 10, -1, 0, 3)
  ..close();

final _wheatAwn = Path()
  ..moveTo(0, -42)
  ..quadraticBezierTo(1, -53, -4, -64);

final _wheatGrain = Path()
  ..moveTo(0, 0)
  ..cubicTo(-8, -3, -11, -18, -6, -29)
  ..quadraticBezierTo(-3, -35, 0, -36)
  ..cubicTo(7, -31, 10, -21, 9, -11)
  ..quadraticBezierTo(7, -2, 0, 0)
  ..close();

final _grainVein = Path()
  ..moveTo(1, -1)
  ..quadraticBezierTo(-4, -18, 0, -32);

final _dateKernel = Path()
  ..moveTo(0, 15)
  ..cubicTo(-9, 15, -13, 6, -12, -3)
  ..quadraticBezierTo(-10, -14, 0, -21)
  ..quadraticBezierTo(10, -14, 12, -3)
  ..cubicTo(13, 6, 9, 15, 0, 15)
  ..close();

final _dateKernelCrease = Path()
  ..moveTo(1, 10)
  ..quadraticBezierTo(-5, -2, 0, -15);

final _wheatLeafPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-89, -71),
    const Offset(64, -58),
    [
      _a(const Color(0xFF45786E), .12),
      _a(const Color(0xFF539A7C), .64),
      _a(const Color(0xFFADCC8F), .26),
    ],
    const [0, .46, 1],
  );

final _glumePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-13, -14),
    const Offset(14, -14),
    [
      _a(const Color(0xFF438068), .19),
      _a(const Color(0xFFA8D59B), .19),
      _a(const Color(0xFF599F88), .19),
    ],
    const [0, .54, 1],
  );

final _dateKernelPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-11, -15),
    const Offset(10, 10),
    const [Color(0xFFE6F3B0), Color(0xFFB2D795), Color(0xFF56A48D)],
    const [0, .42, 1],
  );

void _wheatBackdrop(Canvas canvas) {
  _glow(canvas, 412, 104, 252, const Color(0xFF59A78A), .27);
  _glow(canvas, 159, 20, 228, const Color(0xFF6890AE), .13);
  canvas.save();
  canvas.translate(405, 64);
  canvas.rotate(.26);
  canvas.scale(.64, 1.54);
  _glow(canvas, 0, 0, 126, const Color(0xFFA9DAB1), .12);
  canvas.restore();
}

void _spikelet(
  Canvas canvas,
  double y,
  double angle,
  double scale,
  double filling,
) {
  canvas.save();
  canvas.translate(2, y);
  canvas.rotate(angle);
  canvas.scale(scale);
  canvas.drawPath(_glume, _glumePaint);
  _stroke(canvas, _glume, const Color(0xFF9DD3A9), .34 + filling * .25, .72);
  _stroke(canvas, _wheatAwn, const Color(0xFFB9D6A4), .56, .62);

  // Each grain grows within a fixed outer husk.
  canvas.clipPath(_glume);
  canvas.scale(holidayLerp(.30, 1, filling), holidayLerp(.49, 1, filling));
  final alpha = .26 + filling * .72;
  canvas.drawPath(
    _wheatGrain,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-9, -4),
        const Offset(9, -30),
        [
          _a(const Color(0xFF307058), alpha),
          _a(const Color(0xFF9BCE92), alpha),
          _a(const Color(0xFFDAE8AE), alpha),
          _a(const Color(0xFF539F7C), alpha),
        ],
        const [0, .38, .64, 1],
      ),
  );
  _stroke(
    canvas,
    _grainVein,
    const Color(0xFF396F53),
    .25 + filling * .32,
    .78,
  );
  canvas.clipPath(_wheatGrain);
  final sheen = 4 * filling * (1 - filling);
  _glow(
    canvas,
    -2,
    holidayLerp(-1, -33, filling),
    15,
    const Color(0xFFF5FFB5),
    .82 * sheen,
  );
  canvas.restore();
}

void _xiaoman(Canvas canvas, double seconds) {
  _glow(
    canvas,
    435,
    98,
    115,
    const Color(0xFFB0D59D),
    .16 * holidayWheatFill(seconds),
  );
  canvas.save();
  canvas.translate(398, 222);
  canvas.rotate(
    .19 + math.sin(_phase(seconds, 2)) * .12 + math.sin(_phase(seconds)) * .045,
  );
  canvas.scale(1.18);
  canvas.drawPath(_wheatLeaves, _wheatLeafPaint);
  _stroke(canvas, _wheatVeins, const Color(0xFF98C694), .36, .86);
  _stroke(canvas, _wheatStem, const Color(0xFF75A97D), .86, 2.15);
  for (var tier = 0; tier < 6; tier++) {
    final y = -46.0 - tier * 16;
    final tierScale = 1.07 - tier * .102;
    final angle = .86 - tier * .087;
    // The higher tiers fill later and retain more space in the husk.
    final filling = holidayWheatFill(seconds, tier) * (1 - tier * .065);
    _spikelet(canvas, y, -angle, tierScale, filling);
    _spikelet(canvas, y - 7, angle * .92, tierScale * .94, filling);
  }
  _spikelet(canvas, -141, .06, .49, holidayWheatFill(seconds, 5) * .54);
  final light = .82 + math.sin(_phase(seconds, 1, .55)) * .14;
  _droplet(canvas, -49, -32, 4.2, light);
  _droplet(canvas, 21, -114, 2.7, light);
  canvas.restore();
}

void _wheatBadge(Canvas canvas, double seconds) {
  const kernels = [
    (x: -11.0, y: 1.0, angle: -.66, scale: .91),
    (x: 10.0, y: -3.0, angle: .51, scale: 1.05),
  ];
  for (final kernel in kernels) {
    canvas.save();
    canvas.translate(kernel.x, kernel.y);
    canvas.rotate(kernel.angle);
    canvas.scale(kernel.scale);
    canvas.drawPath(_dateKernel, _dateKernelPaint);
    _stroke(canvas, _dateKernel, const Color(0xFFD9EDAC), .7, 1.5);
    _stroke(canvas, _dateKernelCrease, const Color(0xFF226752), .66, 2.1);
    canvas.restore();
  }
  _droplet(canvas, -2, -20, 4.4, .82 + .14 * math.sin(_phase(seconds)));
}
