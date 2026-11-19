part of 'holiday_glass_scene.dart';

const _deepSnowIce = Color(0xFFE1F1FF);
const _deepSnowGold = Color(0xFFFFC16A);
const _deepSnowFarFlakes = 86;

final _deepSnowPeaks = Path()
  ..addPolygon(const [
    Offset(206, 170),
    Offset(268, 127),
    Offset(304, 103),
    Offset(340, 58),
    Offset(352, 68),
    Offset(380, 112),
    Offset(405, 124),
    Offset(456, 66),
    Offset(469, 63),
    Offset(493, 92),
    Offset(528, 118),
    Offset(552, 111),
    Offset(584, 145),
    Offset(584, 225),
    Offset(206, 225),
  ], true);

final _deepSnowPeakLight = Path()
  ..addPolygon(const [
    Offset(284, 121),
    Offset(340, 58),
    Offset(352, 68),
    Offset(379, 111),
    Offset(353, 98),
    Offset(342, 84),
    Offset(329, 99),
    Offset(319, 96),
  ], true)
  ..addPolygon(const [
    Offset(427, 99),
    Offset(456, 66),
    Offset(469, 63),
    Offset(493, 92),
    Offset(471, 84),
    Offset(461, 84),
    Offset(452, 93),
    Offset(447, 87),
  ], true);

final _deepSnowRidge = Path()
  ..moveTo(216, 229)
  ..cubicTo(252, 213, 283, 201, 319, 204)
  ..cubicTo(357, 206, 393, 232, 431, 219)
  ..cubicTo(479, 201, 514, 199, 584, 207)
  ..lineTo(584, 269)
  ..lineTo(259, 269)
  ..cubicTo(248, 253, 233, 240, 216, 229)
  ..close();

final _deepSnowFir = Path()
  ..moveTo(0, -1)
  ..lineTo(.26, -.71)
  ..lineTo(.14, -.73)
  ..lineTo(.48, -.46)
  ..lineTo(.29, -.48)
  ..lineTo(.67, -.24)
  ..lineTo(.45, -.25)
  ..lineTo(.84, -.02)
  ..quadraticBezierTo(.35, .06, .07, 0)
  ..lineTo(.06, .07)
  ..lineTo(-.05, .07)
  ..lineTo(-.05, 0)
  ..quadraticBezierTo(-.36, .06, -.77, -.03)
  ..lineTo(-.43, -.23)
  ..lineTo(-.65, -.21)
  ..lineTo(-.30, -.44)
  ..lineTo(-.48, -.40)
  ..lineTo(-.16, -.63)
  ..lineTo(-.27, -.60)
  ..close();

final _deepSnowFirLight = Path()
  ..moveTo(-.25, -.60)
  ..quadraticBezierTo(-.06, -.61, .21, -.68)
  ..moveTo(-.48, -.40)
  ..quadraticBezierTo(-.12, -.41, .39, -.47)
  ..moveTo(-.65, -.20)
  ..quadraticBezierTo(-.17, -.20, .60, -.25);

final _deepSnowHouseFront = Path()
  ..addPolygon(const [
    Offset(-52, -8),
    Offset(-7, -58),
    Offset(39, -9),
    Offset(39, 57),
    Offset(-52, 57),
  ], true);

final _deepSnowHouseSide = Path()
  ..addPolygon(const [
    Offset(39, -9),
    Offset(73, -28),
    Offset(73, 37),
    Offset(39, 57),
  ], true);

final _deepSnowRoof = Path()
  ..addPolygon(const [
    Offset(-8, -62),
    Offset(30, -82),
    Offset(85, -31),
    Offset(47, -10),
  ], true);

final _deepSnowFascia = Path()
  ..addPolygon(const [
    Offset(-61, -6),
    Offset(-8, -62),
    Offset(47, -10),
    Offset(42, -4),
    Offset(-8, -52),
    Offset(-55, -2),
  ], true);

final _deepSnowBoards = Path()
  ..moveTo(-48, 1)
  ..lineTo(37, 1)
  ..moveTo(-48, 13)
  ..lineTo(37, 13)
  ..moveTo(-48, 26)
  ..lineTo(37, 26)
  ..moveTo(-48, 39)
  ..lineTo(37, 39)
  ..moveTo(-48, 52)
  ..lineTo(37, 52)
  ..moveTo(42, 0)
  ..lineTo(71, -16)
  ..moveTo(42, 14)
  ..lineTo(71, -2)
  ..moveTo(42, 28)
  ..lineTo(71, 12)
  ..moveTo(42, 42)
  ..lineTo(71, 26);

final _deepSnowSlateLines = Path()
  ..moveTo(2, -66)
  ..lineTo(56, -15)
  ..moveTo(12, -72)
  ..lineTo(66, -21)
  ..moveTo(22, -77)
  ..lineTo(76, -26)
  ..moveTo(11, -43)
  ..lineTo(47, -63)
  ..moveTo(22, -32)
  ..lineTo(58, -52)
  ..moveTo(32, -22)
  ..lineTo(69, -42);

final _deepSnowStep = Path()
  ..moveTo(-71, 54)
  ..cubicTo(-51, 49, -42, 51, -35, 50)
  ..cubicTo(-26, 48, -14, 52, -7, 50)
  ..cubicTo(6, 45, 11, 51, 24, 50)
  ..cubicTo(41, 49, 54, 43, 67, 44)
  ..quadraticBezierTo(78, 45, 87, 49)
  ..lineTo(68, 63)
  ..cubicTo(51, 68, 42, 67, 29, 69)
  ..cubicTo(14, 71, 2, 69, -15, 71)
  ..cubicTo(-40, 71, -62, 68, -77, 65)
  ..close();

final _deepSnowPeaksPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(237, 168),
    const Offset(497, 223),
    const [Color(0x00546B8D), Color(0xB3526582), Color(0xE33B4865)],
    const [0, .52, 1],
  );
final _deepSnowRidgePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(0, 201),
    const Offset(0, 269),
    const [Color(0x777694B9), Color(0x687694B9), Color(0x005F7A9A)],
    const [0, .40, 1],
  );
final _deepSnowSiding = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-50, -37),
    const Offset(35, 56),
    const [Color(0xFF66545C), Color(0xFF4A3D47), Color(0xFF382F3E)],
    const [0, .46, 1],
  );

final _deepSnowflakes = List.generate(146, (i) {
  final layer = i < _deepSnowFarFlakes
      ? 0
      : i < 114
      ? 1
      : 2;
  return (
    layer: layer,
    x: 172 + holidayRandom(17600 + i) * 392,
    offset: holidayRandom(17800 + i),
    size: (.64 + holidayRandom(18000 + i) * 1.12) * (1 + layer * .74),
    speed: 2 + layer,
    wave: holidayRandom(18200 + i) * _tau,
    lift: holidayRandom(18400 + i),
  );
}, growable: false);

double _deepSnowWindowLight(double seconds) {
  final lit =
      holidaySmooth(2.45, 5.35, seconds) *
      (1 - holidaySmooth(10.3, _loop, seconds));
  return .14 + lit * (.81 + .05 * math.sin(_phase(seconds, 3, .3)));
}

void _deepSnowFlurry(
  Canvas canvas,
  double seconds,
  double wind,
  int from,
  int to,
) {
  final pulse = .78 + .22 * math.sin(_phase(seconds, 2, -.3));
  final wave = _phase(seconds);
  for (var i = from; i < to; i++) {
    final flake = _deepSnowflakes[i];
    final fall = (seconds / _loop * flake.speed + flake.offset) % 1;
    final blow = 35 + (92 + flake.layer * 15) * wind * pulse;
    final x =
        flake.x +
        (fall - .42) * blow +
        12 * math.sin(fall * 6 + flake.wave + wave);
    final y = -14 + fall * (264 + flake.layer * 14);
    final strength = .23 + (.64 + flake.lift * .24) * wind;
    final opacity =
        math.sin(math.pi * fall) * strength * (.43 + flake.layer * .19);
    if (flake.layer == 2 && flake.size > 2.75) {
      _glow(
        canvas,
        x,
        y,
        flake.size * 2.6,
        const Color(0xFFC1DDFA),
        .18 * opacity,
      );
    }
    _ellipse(
      canvas,
      x,
      y,
      flake.size * (.82 + .54 * wind),
      flake.size * .68,
      _deepSnowIce,
      opacity,
      .71,
    );
  }
}

void _deepSnowTree(
  Canvas canvas,
  Offset root,
  double height,
  double width,
  double opacity,
  double settled,
) {
  canvas.save();
  canvas.translate(root.dx, root.dy);
  canvas.scale(width, height);
  canvas.drawPath(
    _deepSnowFir,
    Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -1), const Offset(0, .06), [
        _a(const Color(0xFF557588), opacity),
        _a(const Color(0xFF1E3344), opacity),
      ]),
  );
  _stroke(
    canvas,
    _deepSnowFirLight,
    const Color(0xFFA3C6E0),
    (.18 + .47 * settled) * opacity,
    .044,
  );
  canvas.restore();
}

void _drawDeepSnowRoof(Canvas canvas, double cover) {
  final depth = 2 + 12.5 * cover;
  final snow = Path()
    ..moveTo(-64, -8 - depth * .36)
    ..cubicTo(-49, -22 - depth, -24, -57 - depth, -8, -62 - depth)
    ..quadraticBezierTo(13, -76 - depth, 30, -82 - depth)
    ..cubicTo(44, -78 - depth, 68, -47 - depth, 86, -31 - depth * .55)
    ..quadraticBezierTo(91, -29 - depth * .27, 87, -27)
    ..cubicTo(76, -22, 72, -28, 58, -17)
    ..cubicTo(52, -12, 49, -8, 44, -7)
    ..cubicTo(31, -17, 13, -36, -8, -55)
    ..cubicTo(-21, -43, -47, -12, -59, -5)
    ..quadraticBezierTo(-63, -3, -64, -8 - depth * .36)
    ..close();
  canvas.drawPath(
    snow,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-6, -73 - depth),
        const Offset(40, -5),
        [
          _a(const Color(0xFFF1F9FF), cover * .97),
          _a(const Color(0xFFC4DBF0), cover * .98),
          _a(const Color(0xFF97B9DA), cover * .96),
        ],
        const [0, .48, 1],
      ),
  );
  _stroke(canvas, snow, const Color(0xFFE3F4FE), .38 * cover, 1.15);
}

void _deepSnowHouse(Canvas canvas, double settled, double lamp) {
  canvas.save();
  canvas.translate(433, 165);
  final paint = Paint();
  canvas.drawPath(_deepSnowHouseFront, _deepSnowSiding);
  canvas.drawPath(_deepSnowHouseSide, paint..color = const Color(0xFF342F40));
  _stroke(canvas, _deepSnowHouseFront, const Color(0xFF7E737E), .56, 1.2);
  _stroke(canvas, _deepSnowBoards, const Color(0xFF896F70), .58, .73);
  canvas.drawRect(
    const Rect.fromLTWH(6, 9, 25, 48),
    paint..color = const Color(0xFF242837),
  );
  canvas.drawRect(
    const Rect.fromLTWH(10, 12, 17, 44),
    paint..color = const Color(0xFF4D3A41),
  );
  _line(canvas, 18, 15, 18, 55, const Color(0xFF8A6862), .45, .9);
  _ellipse(canvas, 23, 35, 1.7, 1.7, const Color(0xFFC29165), .89);

  _glow(canvas, -26, 21, 56, _deepSnowGold, .49 * lamp);
  canvas.drawRect(
    const Rect.fromLTWH(-45, 4, 36, 34),
    paint..color = const Color(0xFF282534),
  );
  canvas.drawRect(
    const Rect.fromLTWH(-41, 8, 28, 26),
    Paint()
      ..shader =
          ui.Gradient.linear(const Offset(-40, 9), const Offset(-13, 33), [
            _mix(const Color(0xFF774D46), const Color(0xFFFFDF98), lamp),
            _mix(const Color(0xFF312732), const Color(0xFFE98A4A), lamp),
          ]),
  );
  _line(canvas, -27, 9, -27, 34, const Color(0xFF492B34), .85, 1.9);
  _line(canvas, -41, 20, -13, 20, const Color(0xFF492B34), .83, 1.7);
  _line(canvas, -44, 36, -10, 36, const Color(0xFFAB8770), .74, 1.3);

  canvas.drawPath(_deepSnowRoof, paint..color = const Color(0xFF3A4359));
  _stroke(canvas, _deepSnowSlateLines, const Color(0xFF708098), .63, 1.06);
  canvas.drawPath(_deepSnowFascia, paint..color = const Color(0xFF4C4A5B));
  _drawDeepSnowRoof(canvas, .13 + .87 * settled);

  canvas.save();
  canvas.translate(0, -.8 - 3.7 * settled);
  canvas.drawPath(
    _deepSnowStep,
    Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 44), const Offset(0, 71), [
        _a(const Color(0xFFD3E7F8), .19 + .76 * settled),
        _a(const Color(0xFF87A7CE), .10 + .49 * settled),
      ]),
  );
  canvas.restore();
  canvas.translate(-31, 57);
  canvas.scale(1, .29);
  _glow(canvas, 0, 0, 41, _deepSnowGold, .27 * lamp);
  canvas.restore();
}

void _daxue(Canvas canvas, double seconds) {
  final wind = holidayDeepSnowWind(seconds);
  final settled = holidayDeepSnowDrift(seconds);
  final lamp = _deepSnowWindowLight(seconds);
  _glow(canvas, 403, 90, 279, const Color(0xFF779CD4), .24 + .23 * wind);
  _glow(canvas, 496, 170, 165, const Color(0xFFA9C8EF), .13 + .12 * settled);
  canvas.drawPath(_deepSnowPeaks, _deepSnowPeaksPaint);
  canvas.drawPath(
    _deepSnowPeakLight,
    Paint()..color = _a(const Color(0xFF8EADD3), .18 + .14 * wind),
  );
  canvas.drawPath(_deepSnowRidge, _deepSnowRidgePaint);
  _deepSnowFlurry(canvas, seconds, wind, 0, _deepSnowFarFlakes);
  _deepSnowTree(canvas, const Offset(318, 208), 76, 23, .72, settled);
  _deepSnowTree(canvas, const Offset(349, 217), 98, 27, .91, settled);
  _deepSnowTree(canvas, const Offset(553, 208), 112, 32, .89, settled);
  _deepSnowHouse(canvas, settled, lamp);
  _deepSnowFlurry(
    canvas,
    seconds,
    wind,
    _deepSnowFarFlakes,
    _deepSnowflakes.length,
  );
}

final _deepSnowBadgeHouse = Path()
  ..addPolygon(const [
    Offset(-18, -4),
    Offset(-4, -18),
    Offset(13, -5),
    Offset(13, 14),
    Offset(-18, 14),
  ], true)
  ..addPolygon(const [
    Offset(13, -5),
    Offset(23, -10),
    Offset(23, 8),
    Offset(13, 14),
  ], true);

void _deepSnowCabinBadge(Canvas canvas, double seconds) {
  final settled = holidayDeepSnowDrift(seconds);
  final lamp = _deepSnowWindowLight(seconds);
  final paint = Paint()..color = const Color(0xFF657A97);
  canvas.drawPath(_deepSnowBadgeHouse, paint);
  final roof = Path()
    ..moveTo(-23, -2)
    ..lineTo(-4, -22 - settled * 2)
    ..lineTo(6, -26 - settled * 2)
    ..quadraticBezierTo(15, -22, 26, -11)
    ..lineTo(14, -4)
    ..lineTo(-4, -18)
    ..lineTo(-19, -1)
    ..close();
  canvas.drawPath(
    roof,
    paint
      ..color = _mix(
        const Color(0xFFB2CAE3),
        const Color(0xFFEFF8FF),
        .39 + .56 * settled,
      ),
  );
  _glow(canvas, -5, 6, 16, _deepSnowGold, .39 * lamp);
  canvas.drawRect(
    const Rect.fromLTWH(-11, 1, 12, 10),
    paint..color = _mix(const Color(0xFFAD7E5C), const Color(0xFFFFD17F), lamp),
  );
  _line(canvas, -5, 2, -5, 11, const Color(0xFF664C59), .9, 1.1);
  _line(canvas, -20, 15, 22, 9, const Color(0xFFC4DBF5), .88, 1.9);
}
