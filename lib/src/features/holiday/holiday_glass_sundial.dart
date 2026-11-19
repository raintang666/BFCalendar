part of 'holiday_glass_scene.dart';

const _sunGold = Color(0xFFFFE299);
const _dialForeshortening = .414;

final _dialSide = Path()
  ..moveTo(-104, 0)
  ..cubicTo(-104, 24, -58, 43, 0, 43)
  ..cubicTo(58, 43, 104, 24, 104, 0)
  ..lineTo(104, 12)
  ..cubicTo(104, 36, 58, 55, 0, 55)
  ..cubicTo(-58, 55, -104, 36, -104, 12)
  ..close();

final _dialFoot = Path()
  ..moveTo(-51, 32)
  ..lineTo(51, 32)
  ..lineTo(46, 60)
  ..quadraticBezierTo(0, 81, -46, 60)
  ..close();

final _dialNeedle = Path()
  ..moveTo(-7, 3)
  ..lineTo(-3, -42)
  ..lineTo(17, -1)
  ..lineTo(8, 6)
  ..close();

final _needleEdge = Path()
  ..moveTo(-3, -42)
  ..lineTo(17, -1)
  ..lineTo(8, 6)
  ..close();

final _dialFace = Path()..addOval(const Rect.fromLTRB(-104, -43, 104, 43));

final _dialGroove = Path()..addOval(const Rect.fromLTRB(-91, -37.6, 91, 37.6));

final _pedestalPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-51, 35),
    const Offset(51, 66),
    const [Color(0xFF515B59), Color(0xFF3C4C51), Color(0xFF26343C)],
    const [0, .52, 1],
  );

final _dialRimPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-102, 20),
    const Offset(100, 29),
    const [Color(0xFF69716A), Color(0xFF909383), Color(0xFF414F54)],
    const [0, .48, 1],
  );

final _dialFacePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-82, -28),
    const Offset(75, 39),
    const [Color(0xFFB5B7A0), Color(0xFFA2AA9D), Color(0xFF657879)],
    const [0, .44, 1],
  );

final _needleEdgePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-3, -42),
    const Offset(12, 5),
    const [Color(0xFFF4DB9A), Color(0xFFA7AA90), Color(0xFF617573)],
    const [0, .52, 1],
  );

final _dialHours = List.generate(25, (index) {
  final angle = index / 24 * math.pi;
  final major = index % 4 == 0;
  final inner = major ? 79 : 86;
  final x = math.cos(angle);
  final y = math.sin(angle) * _dialForeshortening;
  return (
    angle: angle,
    major: major,
    path: Path()
      ..moveTo(inner * x, inner * y)
      ..lineTo(98 * x, 98 * y),
  );
});

Offset _sunPosition(double progress, double altitude) =>
    Offset(288 + 170 * progress, 94 - 66 * altitude);

final _sunArc = () {
  final path = Path()..moveTo(288, 94);
  for (var step = 1; step <= 32; step++) {
    final progress = step / 32;
    final point = _sunPosition(progress, math.sin(math.pi * progress));
    path.lineTo(point.dx, point.dy);
  }
  return path;
}();

double _dialShadowAngle(double progress) =>
    holidayLerp(.045, math.pi - .045, progress);

void _dialShadow(Canvas canvas, double angle, double altitude, double opacity) {
  if (opacity == 0) return;
  final length = holidayLerp(94, 18, altitude);
  final x = math.cos(angle) * length;
  final y = math.sin(angle) * length * _dialForeshortening;
  final shadow = Path()
    ..moveTo(-5, -1)
    ..quadraticBezierTo(x * .38, y * .4 - 3, x, y)
    ..quadraticBezierTo(x * .4 + 5, y * .52 + 6, 10, 4)
    ..close();
  canvas.drawPath(
    shadow,
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(x, y), [
        _a(const Color(0xFF151F25), .84 * opacity),
        _a(const Color(0xFF242B2E), .60 * opacity),
      ]),
  );
}

void _xiazhi(Canvas canvas, double seconds) {
  final daylight = holidaySolsticeLight(seconds);
  final sun = _sunPosition(daylight.progress, daylight.altitude);
  final opacity = daylight.opacity;
  _glow(
    canvas,
    sun.dx,
    sun.dy,
    182,
    _sunGold,
    (.16 + daylight.altitude * .16) * opacity,
  );
  _stroke(canvas, _sunArc, const Color(0xFFDAD3AC), .18, .8);
  _glow(canvas, sun.dx, sun.dy, 45, _sunGold, .46 * opacity);
  _ellipse(
    canvas,
    sun.dx,
    sun.dy,
    9.2,
    9.2,
    const Color(0xFFFFF5C8),
    .95 * opacity,
  );

  canvas.save();
  canvas.translate(421, 154);
  _ellipse(canvas, 4, 66, 101, 14, const Color(0xFF0D151D), .22);
  canvas.drawPath(_dialFoot, _pedestalPaint);
  canvas.drawPath(_dialSide, _dialRimPaint);
  canvas.drawPath(_dialFace, _dialFacePaint);
  canvas.save();
  canvas.clipPath(_dialFace);
  _glow(
    canvas,
    holidayLerp(-70, 70, daylight.progress),
    -13,
    103,
    const Color(0xFFFFECB2),
    (.32 + daylight.altitude * .34) * opacity,
  );
  canvas.restore();
  _stroke(canvas, _dialFace, const Color(0xFFDAD8B4), .78, 1.2);
  _stroke(canvas, _dialGroove, const Color(0xFF425252), .60, .7);

  final shadowAngle = _dialShadowAngle(daylight.progress);
  for (final hour in _dialHours) {
    _stroke(
      canvas,
      hour.path,
      const Color(0xFF334245),
      hour.major ? .88 : .60,
      hour.major ? 1.6 : .9,
    );
    final lit =
        (1 - holidaySmooth(.02, .15, (hour.angle - shadowAngle).abs())) *
        opacity;
    if (lit > 0) _stroke(canvas, hour.path, const Color(0xFFFFEDA4), lit, 1.4);
  }
  _dialShadow(canvas, shadowAngle, daylight.altitude, opacity);
  canvas.drawPath(_dialNeedle, Paint()..color = const Color(0xFF3A5155));
  canvas.drawPath(_needleEdge, _needleEdgePaint);
  _line(canvas, -3, -42, -7, 3, const Color(0xFFDAD8AE), .64, .9);
  canvas.restore();
}

void _sundialBadge(Canvas canvas, double seconds) {
  final daylight = holidaySolsticeLight(seconds);
  _ellipse(canvas, 0, 4, 24, 10, const Color(0xFF475E5E), 1);
  _ellipse(canvas, 0, 0, 24, 10, const Color(0xFFE1DCB0), 1);
  canvas.save();
  canvas.scale(.24);
  _dialShadow(
    canvas,
    _dialShadowAngle(daylight.progress),
    daylight.altitude,
    daylight.opacity,
  );
  canvas.drawPath(_dialNeedle, Paint()..color = const Color(0xFF324B4C));
  canvas.restore();
  _ellipse(
    canvas,
    holidayLerp(-15, 15, daylight.progress),
    -12 - 8 * daylight.altitude,
    4.9,
    4.9,
    const Color(0xFFFFF2B7),
    daylight.opacity,
  );
}
