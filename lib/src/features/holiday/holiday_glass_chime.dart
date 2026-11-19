part of 'holiday_glass_scene.dart';

final _chimeEave = Path()
  ..moveTo(219, -5)
  ..lineTo(584, -5)
  ..lineTo(584, 17)
  ..cubicTo(535, 14, 489, 23, 438, 30)
  ..cubicTo(368, 36, 283, 29, 219, -5)
  ..close();

final _chimeEaveLip = Path()
  ..moveTo(219, -5)
  ..cubicTo(283, 29, 368, 36, 438, 30)
  ..cubicTo(489, 23, 535, 14, 584, 17);

final _chimeHull = Path()
  ..moveTo(-43, 48)
  ..cubicTo(-41, 29, -35, 13, -23, 4)
  ..quadraticBezierTo(-13, -4, 0, -4)
  ..quadraticBezierTo(13, -4, 23, 4)
  ..cubicTo(35, 13, 41, 29, 43, 48)
  ..quadraticBezierTo(0, 66, -43, 48)
  ..close();

final _chimeHighlight = Path()
  ..moveTo(-34, 42)
  ..cubicTo(-32, 27, -25, 14, -16, 9)
  ..moveTo(19, 6)
  ..quadraticBezierTo(28, 17, 34, 34);

final _chimeRearRim = Path()
  ..moveTo(-43, 48)
  ..quadraticBezierTo(0, 35, 43, 48);

final _chimeFrontRim = Path()
  ..moveTo(-43, 48)
  ..quadraticBezierTo(0, 65, 43, 48);

final _chimePaper = Path()
  ..moveTo(-10, 0)
  ..quadraticBezierTo(0, 2, 10, 0)
  ..lineTo(13, 57)
  ..quadraticBezierTo(1, 62, -13, 55)
  ..close();

final _chimePaperFold = Path()
  ..moveTo(0, 2)
  ..quadraticBezierTo(-2, 27, 2, 57);

final _chimeRoofPaint = Paint()
  ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 42), [
    _a(const Color(0xFF202C2F), .94),
    _a(const Color(0xFF415250), .51),
  ]);

void _chimeGlass(Canvas canvas, Color tint, double wind) {
  // The translucent front sits above the far lip and the clapper.
  _ellipse(canvas, 0, 48, 43, 9.5, const Color(0xFF233A3F), .67);
  _stroke(canvas, _chimeRearRim, tint, .57, 1.05);
  final clapperX = wind * 11;
  _line(canvas, 0, 2, clapperX, 49, const Color(0xFFC9B78E), .64, 1.3);
  _ellipse(canvas, clapperX, 48, 5.8, 5, const Color(0xFFB69D71), .94, .15);
  _ellipse(
    canvas,
    clapperX - 1.6,
    46.5,
    1.8,
    1.3,
    const Color(0xFFF5E2AA),
    .82,
  );

  canvas.drawPath(
    _chimeHull,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-35, 8),
        const Offset(39, 49),
        [
          _a(_mix(tint, const Color(0xFFF8FDE8), .58), .49),
          _a(tint, .34),
          _a(_mix(tint, const Color(0xFF24464C), .42), .17),
          _a(tint, .44),
          _a(tint, .19),
        ],
        const [0, .30, .60, .83, 1],
      ),
  );
  _stroke(
    canvas,
    _chimeHull,
    _mix(tint, const Color(0xFFEFF9E8), .44),
    .69,
    1.3,
  );
  _stroke(
    canvas,
    _chimeHighlight,
    const Color(0xFFEFF9E8),
    .57 + wind.abs() * .19,
    1.8,
  );
  _stroke(
    canvas,
    _chimeFrontRim,
    _mix(tint, const Color(0xFFE7F6E7), .35),
    .92,
    2.45,
  );
}

void _chushu(Canvas canvas, double seconds) {
  final cooling = holidayChushuCooling(seconds);
  final tint = holidayChushuTint(seconds);
  final wind = holidayChushuWind(seconds);
  _glow(canvas, 417, 78, 228, tint, .23);
  _glow(
    canvas,
    192 - cooling * 54,
    60,
    230,
    const Color(0xFFE1A46D),
    .17 * (1 - cooling),
  );
  _glow(canvas, 326, 173, 241, const Color(0xFF639FAF), .18 * cooling);
  canvas.drawPath(_chimeEave, _chimeRoofPaint);
  _stroke(canvas, _chimeEaveLip, tint, .28, 1.2);

  for (var i = 0; i < 5; i++) {
    final travel = (seconds / _loop * 2 + i * .185) % 1;
    final x = 270 + travel * 298;
    final y = 108 + i * 18 + math.sin(_phase(seconds, 1, i.toDouble())) * 7;
    final air = Path()
      ..moveTo(x - 84, y + 2)
      ..cubicTo(x - 59, y - 19, x - 26, y + 14, x, y - 5);
    _stroke(
      canvas,
      air,
      tint,
      (.13 + wind.abs() * .18) * math.sin(math.pi * travel),
      1.05,
    );
  }

  canvas.save();
  canvas.translate(415, 29);
  canvas.rotate(wind * .22);
  _line(canvas, 0, 0, 0, 37, const Color(0xFFD7D3A9), .81, 1.4);
  _ellipse(canvas, 0, 37, 4, 2.3, const Color(0xFFD5BA87), .84);
  canvas.translate(0, 42);
  _chimeGlass(canvas, tint, -wind);

  canvas.translate(-wind * 11, 53);
  final stripSwing =
      .52 * math.sin(_phase(seconds, 2, -.71)) +
      .15 * math.sin(_phase(seconds, 3, .35));
  canvas.rotate(stripSwing);
  _line(canvas, 0, 0, 0, 17, const Color(0xFFD1C7A6), .78, 1.1);
  canvas.translate(0, 17);
  canvas.drawPath(
    _chimePaper,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(-10, 0),
        const Offset(13, 57),
        [
          _a(_mix(tint, const Color(0xFFF1EACB), .72), .91),
          _a(_mix(tint, const Color(0xFFDBD5AC), .48), .79),
          _a(tint, .46),
        ],
        const [0, .60, 1],
      ),
  );
  _stroke(canvas, _chimePaperFold, const Color(0xFFECEFD2), .45, .9);
  canvas.restore();
}

void _chimeBadge(Canvas canvas, double seconds) {
  final wind = holidayChushuWind(seconds);
  final tint = holidayChushuTint(seconds);
  canvas.save();
  canvas.translate(0, -13);
  canvas.scale(.52);
  canvas.rotate(wind * .13);
  _line(canvas, 0, -13, 0, -3, tint, .93, 2);
  _chimeGlass(canvas, tint, -wind);
  _line(
    canvas,
    -wind * 11,
    52,
    wind * 6,
    67,
    const Color(0xFFEAE1B9),
    .92,
    2.2,
  );
  canvas.restore();
}
