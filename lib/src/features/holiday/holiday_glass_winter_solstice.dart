part of 'holiday_glass_scene.dart';

final _dumplingOutline = Path()
  ..moveTo(-34, 5)
  ..cubicTo(-35, 0, -29, -2, -26, -7)
  ..quadraticBezierTo(-27, -11, -21, -12)
  ..quadraticBezierTo(-21, -18, -15, -16)
  ..quadraticBezierTo(-13, -22, -7, -19)
  ..quadraticBezierTo(-4, -24, 1, -21)
  ..quadraticBezierTo(6, -23, 10, -19)
  ..quadraticBezierTo(16, -20, 19, -15)
  ..quadraticBezierTo(25, -15, 27, -9)
  ..quadraticBezierTo(33, -7, 32, -2)
  ..quadraticBezierTo(37, 3, 34, 7)
  ..cubicTo(31, 17, 10, 22, -7, 20)
  ..cubicTo(-21, 19, -29, 14, -34, 5)
  ..close();

final _dumplingSeam = Path()
  ..moveTo(-29, 3)
  ..cubicTo(-22, -5, -14, -15, 0, -16)
  ..cubicTo(12, -17, 23, -7, 29, 1);

final _dumplingPleats = Path()
  ..moveTo(-25, -7)
  ..quadraticBezierTo(-23, -4, -23, 0)
  ..moveTo(-20, -12)
  ..quadraticBezierTo(-18, -10, -18, -5)
  ..moveTo(-14, -16)
  ..quadraticBezierTo(-12, -14, -12, -9)
  ..moveTo(-7, -19)
  ..quadraticBezierTo(-5, -16, -5, -12)
  ..moveTo(1, -20)
  ..quadraticBezierTo(4, -18, 4, -13)
  ..moveTo(9, -19)
  ..quadraticBezierTo(12, -16, 11, -11)
  ..moveTo(17, -16)
  ..quadraticBezierTo(20, -12, 18, -8)
  ..moveTo(24, -12)
  ..quadraticBezierTo(27, -9, 24, -5)
  ..moveTo(29, -7)
  ..quadraticBezierTo(32, -5, 28, -2);

final _dumplingRim = Path()
  ..moveTo(-25, 9)
  ..cubicTo(-16, 15, 8, 18, 23, 11);

const _platedDumplings = [
  (x: 366.0, y: 188.0, scale: .79, tilt: -.16, light: .72),
  (x: 418.0, y: 181.0, scale: .84, tilt: .12, light: .77),
  (x: 471.0, y: 183.0, scale: .76, tilt: .27, light: .73),
  (x: 344.0, y: 207.0, scale: .82, tilt: -.22, light: .91),
  (x: 403.0, y: 219.0, scale: .92, tilt: .05, light: .99),
];
const _dumplingRest = Offset(470, 215);
final _celadonPlate = Path()..addOval(const Rect.fromLTWH(-133, -37, 266, 74));
final _celadonRim = Path()
  ..addArc(const Rect.fromLTWH(-125, -32, 250, 64), .12, math.pi - .24);
final _celadonGlaze = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-70, -31),
    const Offset(95, 36),
    const [Color(0xFF8AA99F), Color(0xFF5B837E), Color(0xFF3D656B)],
    const [0, .52, 1],
  );

void _paintDumpling(
  Canvas g,
  double x,
  double y,
  double scale,
  double tilt, {
  double light = 1,
}) {
  g.save();
  g.translate(x, y);
  g.rotate(tilt);
  g.scale(scale);
  g.drawPath(
    _dumplingOutline,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-12, -24),
        const Offset(19, 21),
        [
          _mix(const Color(0xFFC7C8C4), const Color(0xFFFFF3D8), light),
          _mix(const Color(0xFFA7AEAB), const Color(0xFFEED7B3), light),
          _mix(const Color(0xFF9C9D96), const Color(0xFFE0C7A3), light),
          _mix(const Color(0xFF657677), const Color(0xFFA7907B), light),
        ],
        const [0, .40, .74, 1],
      ),
  );
  _stroke(g, _dumplingOutline, const Color(0xFF60504D), .50, 1.05);
  _stroke(g, _dumplingSeam, const Color(0xFFFFF5E0), .58 + .27 * light, 1.12);
  _stroke(g, _dumplingPleats, const Color(0xFF9A775D), .67, 1.34);
  g.save();
  g.translate(-.7, -.65);
  _stroke(g, _dumplingPleats, const Color(0xFFFCEFD5), .78, .83);
  g.restore();
  _stroke(g, _dumplingRim, const Color(0xFFFBE6C5), .38, 1.5);
  g.restore();
}

void _paintCeladonPlate(Canvas g, double warmth) {
  g.save();
  g.translate(423, 206);
  _ellipse(g, 1, 23, 139, 22, const Color(0xFF181E25), .65);
  _ellipse(g, 0, 4, 133, 38, const Color(0xFF253E40), 1);
  g.drawPath(_celadonPlate, _celadonGlaze);
  _stroke(g, _celadonPlate, const Color(0xFFAACCBF), .60, 1.21);
  _ellipse(g, 0, -1, 120, 28, const Color(0xFF496C68), 1);
  _ellipse(g, 0, -1, 117, 24.5, const Color(0xFF517872), .84);
  _stroke(g, _celadonRim, const Color(0xFFB9D6CA), .30 + .19 * warmth, 1.2);
  g.restore();
}

void _paintDumplingChopstick(
  Canvas g,
  double x,
  double y,
  int side,
  double opacity,
) {
  if (opacity <= .01) return;
  final endX = x + 150;
  final endY = y - 68 + side * 3;
  final shaft = Path()
    ..moveTo(x - .5, y - 1.05)
    ..lineTo(endX - 1.1, endY - 3.1)
    ..quadraticBezierTo(endX + 3, endY - 2.6, endX + 2, endY + 2.65)
    ..lineTo(x + .4, y + 1.05)
    ..close();
  g.drawPath(
    shaft,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(x, y),
        Offset(endX, endY),
        [
          _a(const Color(0xFFE0A767), opacity),
          _a(const Color(0xFFA6653D), opacity),
          _a(const Color(0xFF6E3B30), opacity),
        ],
        const [0, .53, 1],
      ),
  );
  _stroke(g, shaft, const Color(0xFF603F35), opacity * .62, .75);
  _line(
    g,
    x + 2,
    y - .5,
    endX - 3,
    endY - 1.9,
    const Color(0xFFF5CC92),
    opacity * .6,
    .68,
  );
}

void _dongzhi(Canvas g, double t) {
  final lift = holidayDumplingLift(t);
  final warmth = holidayDumplingWarmth(t);
  _glow(g, 429, 168, 193, const Color(0xFFDE9F70), .13 + .20 * warmth);
  g.save();
  g.translate(430, 229);
  g.scale(1, .18);
  _glow(g, 0, 0, 151, const Color(0xFFD8A27C), .17 + .10 * warmth);
  g.restore();

  _paintCeladonPlate(g, warmth);
  for (final dumpling in _platedDumplings) {
    _ellipse(
      g,
      dumpling.x + 2,
      dumpling.y + 11,
      dumpling.scale * 30,
      8.7,
      const Color(0xFF253B3A),
      .58,
    );
    _paintDumpling(
      g,
      dumpling.x,
      dumpling.y,
      dumpling.scale,
      dumpling.tilt,
      light: dumpling.light,
    );
  }

  final x =
      _dumplingRest.dx - 21.5 * lift + 2 * lift * math.sin(_phase(t, 2, .55));
  final y = _dumplingRest.dy - 94 * lift;
  final tilt = .09 - .26 * lift + .049 * lift * math.sin(_phase(t, 2));
  _ellipse(
    g,
    _dumplingRest.dx + 4 - lift * 5,
    _dumplingRest.dy + 10,
    29 + 5 * lift,
    8.7 + 4 * lift,
    const Color(0xFF1D3533),
    .55 - .39 * lift,
  );

  final approach =
      holidaySmooth(.48, 3.18, t) * (1 - holidaySmooth(10.98, 12.56, t));
  final pinch =
      holidaySmooth(2.36, 3.38, t) * (1 - holidaySmooth(10.88, 11.35, t));
  final gripX = x + ui.lerpDouble(68, 11, approach)!;
  final gripY = y + ui.lerpDouble(-48, -10, approach)!;
  final gap = ui.lerpDouble(15, 4.4, pinch)!;
  final visible =
      holidaySmooth(.39, 1.64, t) * (1 - holidaySmooth(11.53, 12.8, t));
  _paintDumplingChopstick(g, gripX - gap * .62, gripY - gap, -1, .85 * visible);
  _paintDumpling(g, x, y, .93, tilt);
  _paintDumplingChopstick(g, gripX + gap * .62, gripY + gap, 1, visible);
}

void _dumplingDateBadge(Canvas g, double t) {
  final lift = holidayDumplingLift(t);
  final tilt = -.17 + .13 * lift + .038 * math.sin(_phase(t, 1, .5));
  _paintDumpling(g, 0, 1 - 5.4 * lift, .76, tilt);
}
