part of 'holiday_glass_scene.dart';

const _winterSteamColor = Color(0xFFE5EEF1);
const _winterBrass = Color(0xFFE7AA6C);

final _winterKettle = Path()
  ..moveTo(-42, -49)
  ..quadraticBezierTo(-2, -59, 42, -49)
  ..cubicTo(54, -39, 63, -23, 60, -7)
  ..cubicTo(57, 13, 33, 22, 1, 23)
  ..cubicTo(-32, 23, -54, 13, -59, -4)
  ..cubicTo(-65, -24, -54, -40, -42, -49)
  ..close();

final _winterSpout = Path()
  ..moveTo(-47, -36)
  ..cubicTo(-62, -34, -73, -41, -87, -54)
  ..lineTo(-92, -59)
  ..quadraticBezierTo(-99, -57, -95, -49)
  ..cubicTo(-86, -39, -76, -29, -72, -16)
  ..quadraticBezierTo(-64, -6, -52, -6)
  ..close();

final _winterHandle = Path()
  ..moveTo(-40, -34)
  ..cubicTo(-51, -70, -29, -101, -1, -102)
  ..cubicTo(28, -103, 51, -70, 41, -34);

final _winterKettleEdge = Path()
  ..moveTo(-58, 0)
  ..cubicTo(-48, 15, -25, 22, 0, 22)
  ..cubicTo(23, 22, 46, 16, 55, 5);

final _winterKettleLid = Path()
  ..moveTo(-38, -50)
  ..cubicTo(-26, -67, 29, -68, 39, -50)
  ..cubicTo(19, -44, -21, -43, -38, -50)
  ..close();

final _winterBrazier = Path()
  ..moveTo(-55, -15)
  ..cubicTo(-57, 4, -52, 28, -42, 33)
  ..cubicTo(-24, 45, 26, 45, 43, 33)
  ..cubicTo(52, 28, 57, 3, 55, -15)
  ..close();

final _winterBrazierRim = Path()
  ..moveTo(-48, -13)
  ..cubicTo(-24, -1, 26, -1, 49, -14);

final _winterFirebox = Path()
  ..moveTo(-26, 27)
  ..lineTo(-26, 16)
  ..cubicTo(-26, 1, -14, -8, 0, -8)
  ..cubicTo(16, -8, 26, 2, 26, 16)
  ..lineTo(26, 27)
  ..quadraticBezierTo(0, 38, -26, 27)
  ..close();

final _winterBrazierBand = Path()
  ..moveTo(-49, 16)
  ..cubicTo(-40, 30, 39, 31, 49, 16);

final _winterCup = Path()
  ..moveTo(-20, 0)
  ..cubicTo(-18, 8, -13, 15, -8, 17)
  ..quadraticBezierTo(0, 21, 8, 17)
  ..cubicTo(14, 15, 18, 6, 20, 0)
  ..close();

class _WinterGlaze {
  _WinterGlaze(this.top, this.middle, this.base, this.rim);

  final Color top, middle, base, rim;

  late final spout = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(-91, -55),
      const Offset(-49, -14),
      [top, middle, base],
      const [0, .64, 1],
    );
  late final lid = Paint()
    ..shader = ui.Gradient.linear(const Offset(0, -67), const Offset(0, -46), [
      top,
      middle,
    ]);
}

final _winterTeaGlaze = _WinterGlaze(
  const Color(0xFF6F8489),
  const Color(0xFF304148),
  const Color(0xFF2B2525),
  const Color(0xFF99B2B5),
);
final _winterBadgeGlaze = _WinterGlaze(
  const Color(0xFFF2C88D),
  const Color(0xFFB06A3B),
  const Color(0xFF733F2D),
  const Color(0xFFF9D59E),
);
final _winterClay = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-51, -9),
    const Offset(42, 30),
    const [Color(0xFF79574D), Color(0xFF4A3335), Color(0xFF674338)],
    const [0, .51, 1],
  );
final _winterFireboxShade = Paint()..color = const Color(0xFF241B22);
final _winterEmbers = List.generate(
  13,
  (i) => (
    x: (holidayRandom(12000 + i) - .5) * 42,
    delay: holidayRandom(12100 + i),
    size: .6 + 1.3 * holidayRandom(12200 + i),
  ),
  growable: false,
);

void _paintWinterKettle(Canvas canvas, double heat, _WinterGlaze glaze) {
  _stroke(canvas, _winterHandle, const Color(0xFF1C2126), 1, 9.6);
  _stroke(canvas, _winterHandle, glaze.rim, .81, 6.2);
  _stroke(canvas, _winterHandle, glaze.base, .34, 3.35);

  canvas.drawPath(_winterSpout, glaze.spout);
  _stroke(canvas, _winterSpout, glaze.rim, .51, 1.05);
  _ellipse(canvas, -92.7, -54.5, 4, 5.15, const Color(0xFF1F252A), 1, -.49);
  _ellipse(canvas, -93.5, -56.4, 2.95, .85, glaze.rim, .8, -.49);

  canvas.drawPath(
    _winterKettle,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-38, -62),
        const Offset(39, 19),
        [
          glaze.top,
          glaze.middle,
          glaze.base,
          _mix(glaze.middle, _winterBrass, .12 + .25 * heat),
        ],
        const [0, .39, .69, 1],
      ),
  );
  _stroke(canvas, _winterKettle, glaze.rim, .52, 1.15);
  _stroke(canvas, _winterKettleEdge, _winterBrass, .40 + .46 * heat, 1.55);
  _ellipse(canvas, -30, -31, 22, 3.6, glaze.rim, .18, -.43);

  canvas.drawPath(_winterKettleLid, glaze.lid);
  _stroke(canvas, _winterKettleLid, glaze.rim, .8, 1.3);
  _ellipse(canvas, 0, -64.5, 7, 4.6, glaze.middle, 1);
  _ellipse(canvas, 0, -66.3, 5.4, 2.1, glaze.rim, .92);
}

void _winterFlame(
  Canvas canvas,
  double seconds,
  double x,
  double height,
  double width,
  double delay,
  double opacity, {
  bool core = false,
}) {
  final sway = math.sin(_phase(seconds, 13, delay));
  final tip = x + (3.6 + width * .25) * sway;
  const base = 28.0;
  final flame = Path()
    ..moveTo(x - width * .86, base)
    ..cubicTo(
      x - width * 1.38,
      base - height * .31,
      tip - width * .66,
      base - height * .66,
      tip,
      base - height,
    )
    ..cubicTo(
      tip + width * .14,
      base - height * .55,
      x + width * 1.47,
      base - height * .43,
      x + width * .92,
      base,
    )
    ..close();
  canvas.drawPath(
    flame,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, base),
        Offset(0, base - height),
        [
          _a(
            core ? const Color(0xFFFFD979) : const Color(0xFFE14E28),
            opacity * .92,
          ),
          _a(core ? const Color(0xFFFFB74F) : const Color(0xFFFA853B), opacity),
          _a(const Color(0xFFF9B05B), opacity * .23),
        ],
        const [0, .57, 1],
      ),
  );
}

void _paintWinterStove(Canvas canvas, double seconds, double heat) {
  canvas.drawPath(_winterBrazier, _winterClay);
  _stroke(canvas, _winterBrazier, const Color(0xFF97725C), .58, 1.4);
  _stroke(canvas, _winterBrazierBand, _winterBrass, .19 + .25 * heat, .93);
  _ellipse(canvas, 0, -16, 55, 12, const Color(0xFF453434), 1);
  _ellipse(canvas, 0, -17, 49, 8.2, const Color(0xFF1F1E22), 1);
  _ellipse(canvas, 0, -17, 38, 5.5, const Color(0xFFC35C30), .19 + .22 * heat);
  _stroke(canvas, _winterBrazierRim, const Color(0xFFC4895E), .64, 1.5);
  canvas.drawPath(_winterFirebox, _winterFireboxShade);

  canvas.save();
  canvas.clipPath(_winterFirebox);
  _glow(canvas, 0, 22, 36, const Color(0xFFF87637), .16 + .62 * heat);
  for (final (x, size, width, delay) in const [
    (-13.0, 27.0, 8.0, .4),
    (1.0, 37.0, 10.0, 1.8),
    (13.0, 29.0, 8.9, 3.5),
  ]) {
    final flicker = .86 + .14 * math.sin(_phase(seconds, 17, delay));
    final height = size * (.22 + .78 * heat) * flicker;
    _winterFlame(canvas, seconds, x, height, width, delay, .28 + .62 * heat);
    _winterFlame(
      canvas,
      seconds,
      x + 1,
      height * .68,
      width * .49,
      delay + .6,
      .28 + .66 * heat,
      core: true,
    );
  }
  for (final ember in _winterEmbers) {
    final rise = (seconds / _loop * 4 + ember.delay) % 1;
    final opacity = math.sin(math.pi * rise) * (.18 + .67 * heat);
    _ellipse(
      canvas,
      ember.x + math.sin(rise * 7) * 3.4,
      28 - 32 * rise * heat,
      ember.size,
      ember.size * .77,
      const Color(0xFFFFDB7D),
      opacity,
    );
  }
  canvas.restore();
  _stroke(
    canvas,
    _winterFirebox,
    const Color(0xFFC58356),
    .57 + .26 * heat,
    1.38,
  );
}

void _winterSteam(Canvas canvas, double seconds) {
  final boil =
      holidaySmooth(2.22, 5.45, seconds) *
      (1 - holidaySmooth(10.1, _loop, seconds));
  final wave = _phase(seconds, 2);
  for (var packet = 0; packet < 4; packet++) {
    final rise = (seconds / _loop * 3 + packet * .25) % 1;
    final opacity = boil * math.pow(math.sin(rise * math.pi), .72).toDouble();
    if (opacity <= .01) continue;
    final start = rise * .79;
    final length = .26 + .29 * rise;
    final wisp = Path()
      ..addPolygon([
        for (var sample = 0; sample <= 24; sample++)
          _winterSteamPoint(start + length * sample / 24, wave, packet),
      ], false);
    _stroke(
      canvas,
      wisp,
      const Color(0xFFAECBDE),
      opacity * .13,
      12 + rise * 9,
    );
    _stroke(canvas, wisp, _winterSteamColor, opacity * .20, 5.5 + rise * 3.6);
    _stroke(canvas, wisp, _winterSteamColor, opacity * .41, 1.8 + rise * 1.35);
  }
}

Offset _winterSteamPoint(double u, double wave, int packet) {
  final curl = math.sin(u * 7.2 - wave + packet * .55);
  return Offset(
    337 - 19 * u + (curl * (7 + 10 * u) + (packet - 1.5) * 3.6) * u,
    108 - 64 * u,
  );
}

void _lidong(Canvas canvas, double seconds) {
  final heat = holidayWinterHeat(seconds);
  _glow(canvas, 433, 202, 183, const Color(0xFFF77B37), .075 + .32 * heat);
  canvas.save();
  canvas.translate(426, 240);
  canvas.scale(1, .18);
  _glow(canvas, 0, 0, 142, const Color(0xFFE68445), .15 + .27 * heat);
  canvas.restore();

  canvas.save();
  canvas.translate(429, 204);
  _paintWinterStove(canvas, seconds, heat);
  canvas.translate(0, -42);
  _paintWinterKettle(canvas, heat, _winterTeaGlaze);
  canvas.restore();
  _winterSteam(canvas, seconds);

  canvas.save();
  canvas.translate(318, 218);
  _ellipse(canvas, 0, 18, 25, 5, const Color(0xFF1F252E), .86);
  canvas.drawPath(
    _winterCup,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-20, 0),
        const Offset(20, 11),
        [
          const Color(0xFF4B6069),
          const Color(0xFF263840),
          _mix(const Color(0xFF3D5157), _winterBrass, .20 + .32 * heat),
        ],
        const [0, .63, 1],
      ),
  );
  _ellipse(canvas, 0, 0, 20, 6.4, const Color(0xFF889B99), 1);
  _ellipse(canvas, 0, .1, 17.7, 4.65, const Color(0xFF764833), 1);
  _ellipse(canvas, 4, 1.1, 10, 1.4, _winterBrass, .35 + .43 * heat, -.10);
  canvas.restore();
}

void _winterTeaBadge(Canvas canvas, double seconds) {
  canvas.save();
  canvas.translate(4, 10);
  canvas.scale(.30);
  _paintWinterKettle(canvas, holidayWinterHeat(seconds), _winterBadgeGlaze);
  canvas.restore();
  final curl = 3.1 * math.sin(_phase(seconds, 3, .8));
  final steam = Path()
    ..moveTo(-24, -9)
    ..cubicTo(-30, -13, -19 + curl, -18, -23 + curl, -26);
  _stroke(canvas, steam, _winterSteamColor, .84, 1.72);
}
