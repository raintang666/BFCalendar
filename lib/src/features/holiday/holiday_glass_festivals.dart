part of 'holiday_glass_scene.dart';

const _festGold = Color(0xFFFFC777);
const _festCream = Color(0xFFFFE9B2);
const _festVermilion = Color(0xFFFF5D41);
const _festBlue = Color(0xFF9ACDFF);
const _festJade = Color(0xFF7BD4BD);

void _festivalFill(Canvas g, Path path, Color color, [double alpha = 1]) =>
    g.drawPath(path, Paint()..color = _a(color, alpha));

void _festivalShade(
  Canvas g,
  Path path,
  Offset start,
  Offset end,
  List<Color> colors, [
  List<double>? stops,
]) => g.drawPath(
  path,
  Paint()..shader = ui.Gradient.linear(start, end, colors, stops),
);

final _festivalStars = List.generate(
  58,
  (i) => (
    x: holidayRandom(i + 246) * 584,
    y: holidayRandom(i + 411) * 174,
    size: .45 + holidayRandom(i + 603) * 1.25,
  ),
);

void _festStars(Canvas g, double t, Color color, double opacity) {
  for (final (i, star) in _festivalStars.indexed) {
    final pulse = .5 + .5 * math.sin(_phase(t, 2, i * 5.0));
    _ellipse(
      g,
      star.x,
      star.y,
      star.size,
      star.size,
      color,
      opacity * (.25 + .75 * pulse),
    );
  }
}

void _festDust(Canvas g, double t, int count) {
  for (var i = 0; i < count; i++) {
    final star = _festivalStars[i];
    final progress = (star.y / 174 + t / _loop * (i % 2 + 1)) % 1;
    final x =
        star.x + math.sin(_phase(t, 2, i.toDouble())) * (5 + star.size * 4);
    final y = 245 * (1 - progress);
    final opacity = math.sin(math.pi * progress) * .53;
    _ellipse(g, x, y, star.size, star.size, _festGold, opacity);
    if (i % 5 == 0) _glow(g, x, y, 9, _festGold, opacity * .42);
  }
}

// 元旦 · Rockets emerge from the skyline and open into layered bursts.
void _newYearSkyline(Canvas g) {
  final wall = Paint()..color = const Color(0xE80E172B);
  final window = Paint();
  for (var i = 0; i < 35; i++) {
    final x = i * 17.2;
    final w = 6 + holidayRandom(i + 43) * 14;
    final h = 12 + math.pow(holidayRandom(i + 71), 1.7).toDouble() * 40;
    final lights = holidayRandom(i + 333);
    g.drawRect(Rect.fromLTWH(x, 225 - h, w, h + 46), wall);
    if (lights > .34) {
      window.color = _a(_festGold, .23 + .25 * lights);
      g.drawRect(Rect.fromLTWH(x + w * .54, 233 - h, 1.6, 2.7), window);
      g.drawRect(Rect.fromLTWH(x + w * .26, 240 - h, 1.5, 2.2), window);
    }
  }
}

final _newYearSparks = List.generate(
  holidayNewYearBursts.length,
  (index) => List.generate(44, (i) {
    final seed = index * 97 + i;
    final angle = i / 44 * _tau + holidayRandom(seed + 12) * .13;
    final speed =
        (.65 + .39 * holidayRandom(seed + 31)) * (i % 5 == 0 ? .54 : 1);
    return Offset(math.cos(angle) * speed, math.sin(angle) * speed);
  }),
);

void _newYearFestival(Canvas g, double t) {
  _festStars(g, t, _festBlue, .64);
  final sparkPaint = Paint()
    ..strokeWidth = 1.35
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus;
  for (final (index, burst) in holidayNewYearBursts.indexed) {
    final (at: at, x: x, y: y, radius: radius, color: color) = burst;
    final age = t - at;
    if (age < -.54 || age > 1.86) continue;
    if (age < 0) {
      final progress = holidaySmooth(-.54, 0, age);
      final head = holidayLerp(235, y, progress);
      _line(
        g,
        x - 5 * (1 - progress),
        head + 17,
        x,
        head,
        color,
        progress * .7,
        1.6,
      );
      _glow(g, x, head, 9, _festCream, progress * .8);
      continue;
    }
    final opacity = 1 - holidaySmooth(.08, 1.84, age);
    final prev = math.max(0.0, age - .14);
    final distance = radius * (1 - math.exp(-2.5 * age));
    final tail = radius * (1 - math.exp(-2.5 * prev));
    final origin = Offset(x, y + age * age * 20);
    final tailStart = Offset(x, y + prev * prev * 20);
    _glow(g, x, y, radius * 1.9, color, .25 * math.exp(-2.8 * age));
    for (final (i, velocity) in _newYearSparks[index].indexed) {
      final flicker = .72 + .28 * math.cos(i * 3 + age * 30);
      final end = origin + velocity * distance;
      sparkPaint.color = _a(color, opacity * flicker);
      g.drawLine(tailStart + velocity * tail, end, sparkPaint);
      if (i % 4 == 0) {
        _ellipse(g, end.dx, end.dy, 1.45, 1.45, _festCream, opacity * flicker);
      }
    }
  }
}

final _festDiamond = Path()
  ..moveTo(0, -68)
  ..lineTo(68, 0)
  ..lineTo(0, 68)
  ..lineTo(-68, 0)
  ..close();

final _festDiamondBorder = Path()
  ..moveTo(0, -59)
  ..lineTo(59, 0)
  ..lineTo(0, 59)
  ..lineTo(-59, 0)
  ..close()
  ..moveTo(0, -54)
  ..lineTo(54, 0)
  ..lineTo(0, 54)
  ..lineTo(-54, 0)
  ..close();

final _festRoof = Path()
  ..moveTo(-20, 37)
  ..quadraticBezierTo(23, 43, 66, 14)
  ..lineTo(119, 5)
  ..quadraticBezierTo(195, 33, 278, 10)
  ..lineTo(326, 24)
  ..quadraticBezierTo(420, 42, 450, 3)
  ..quadraticBezierTo(502, 26, 612, 18)
  ..lineTo(612, -17)
  ..lineTo(-20, -17)
  ..close();

final _festLotusPetal = Path()
  ..moveTo(0, 5)
  ..cubicTo(-16, 5, -24, -11, -17, -21)
  ..quadraticBezierTo(-12, -17, -4, -15)
  ..quadraticBezierTo(7, -7, 0, 5)
  ..close();

final _festFlame = Path()
  ..moveTo(0, -9)
  ..quadraticBezierTo(-5, -12, -1, -17)
  ..quadraticBezierTo(0, -20, 1, -24)
  ..quadraticBezierTo(8, -16, 5, -11)
  ..quadraticBezierTo(3, -8, 0, -9)
  ..close();

final _festHull = Path()
  ..moveTo(-110, -2)
  ..quadraticBezierTo(-89, 13, -47, 11)
  ..lineTo(65, 11)
  ..quadraticBezierTo(91, 5, 99, -15)
  ..lineTo(111, -7)
  ..quadraticBezierTo(99, 31, 65, 33)
  ..lineTo(-69, 33)
  ..quadraticBezierTo(-101, 27, -110, -2)
  ..close();

final _festDragon = Path()
  ..moveTo(72, 22)
  ..quadraticBezierTo(81, 9, 84, -16)
  ..quadraticBezierTo(81, -32, 94, -39)
  ..lineTo(99, -49)
  ..lineTo(104, -40)
  ..quadraticBezierTo(111, -43, 121, -36)
  ..lineTo(133, -36)
  ..lineTo(137, -31)
  ..lineTo(130, -22)
  ..lineTo(116, -23)
  ..lineTo(110, -18)
  ..lineTo(132, -16)
  ..lineTo(127, -10)
  ..lineTo(109, -10)
  ..quadraticBezierTo(101, 6, 99, 16)
  ..close();

final _festRiverHills = Path()
  ..moveTo(-20, 132)
  ..quadraticBezierTo(54, 67, 128, 121)
  ..quadraticBezierTo(216, 33, 296, 119)
  ..quadraticBezierTo(361, 62, 426, 114)
  ..quadraticBezierTo(510, 30, 599, 109)
  ..lineTo(599, 166)
  ..lineTo(-20, 166)
  ..close();

final _festCloud = Path()
  ..moveTo(-132, 11)
  ..cubicTo(-90, -2, -63, -7, -24, -7)
  ..quadraticBezierTo(-2, -24, 36, -18)
  ..quadraticBezierTo(65, -22, 84, -7)
  ..quadraticBezierTo(106, -4, 137, 3)
  ..quadraticBezierTo(69, 8, 22, 11)
  ..quadraticBezierTo(-39, 17, -132, 11)
  ..close();

final _festMoonHills = Path()
  ..moveTo(-20, 193)
  ..quadraticBezierTo(80, 135, 147, 166)
  ..quadraticBezierTo(210, 116, 285, 157)
  ..quadraticBezierTo(316, 128, 386, 161)
  ..quadraticBezierTo(481, 120, 605, 149)
  ..lineTo(605, 207)
  ..lineTo(-20, 207)
  ..close();

final _festGateRoof = Path()
  ..moveTo(-80, 0)
  ..quadraticBezierTo(-54, -4, -41, -19)
  ..quadraticBezierTo(0, -15, 41, -19)
  ..quadraticBezierTo(54, -4, 80, 0)
  ..lineTo(70, 5)
  ..lineTo(-70, 5)
  ..close();

final _festGateBody = Path()
  ..moveTo(-59, 3)
  ..lineTo(59, 3)
  ..lineTo(59, 45)
  ..lineTo(-59, 45)
  ..close();

final _festRoofRidge = Path()
  ..moveTo(-77, 0)
  ..quadraticBezierTo(-33, -5, 0, -4)
  ..quadraticBezierTo(33, -5, 77, 0);

final _festCalendarPage = Path()
  ..moveTo(-19, -11)
  ..quadraticBezierTo(-19, -16, -14, -16)
  ..lineTo(15, -16)
  ..quadraticBezierTo(20, -16, 20, -11)
  ..lineTo(20, 9)
  ..lineTo(11, 19)
  ..lineTo(-14, 19)
  ..quadraticBezierTo(-19, 19, -19, 14)
  ..close();

final _festCalendarHeader = Path()
  ..moveTo(-19, -11)
  ..quadraticBezierTo(-19, -16, -14, -16)
  ..lineTo(15, -16)
  ..quadraticBezierTo(20, -16, 20, -11)
  ..lineTo(20, -6)
  ..lineTo(-19, -6)
  ..close();

final _festCalendarFold = Path()
  ..moveTo(11, 19)
  ..lineTo(11, 12)
  ..quadraticBezierTo(11, 9, 14, 9)
  ..lineTo(20, 9)
  ..close();

final _festCalendarOne = Path()
  ..moveTo(-5, 1)
  ..lineTo(0, -2)
  ..lineTo(0, 12)
  ..moveTo(-5, 12)
  ..lineTo(5, 12);

final _festHelmetDome = Path()
  ..moveTo(-21, 6)
  ..quadraticBezierTo(-20, -12, -10, -16)
  ..quadraticBezierTo(0, -22, 12, -15)
  ..quadraticBezierTo(22, -10, 23, 6)
  ..close();

final _festHelmetBrim = Path()
  ..moveTo(-25, 5)
  ..quadraticBezierTo(-12, 8, 10, 6)
  ..lineTo(25, 4)
  ..quadraticBezierTo(30, 5, 30, 8)
  ..quadraticBezierTo(20, 15, -5, 15)
  ..quadraticBezierTo(-20, 14, -25, 11)
  ..quadraticBezierTo(-30, 9, -25, 5)
  ..close();

final _festHelmetRidge = Path()
  ..moveTo(-5, 5)
  ..quadraticBezierTo(-5, -13, 2, -18)
  ..quadraticBezierTo(7, -19, 9, -16)
  ..quadraticBezierTo(4, -9, 4, 5)
  ..close();

final _festFlagCloth = Path()
  ..moveTo(0, 0)
  ..lineTo(30, 0)
  ..lineTo(30, 20)
  ..lineTo(0, 20)
  ..close();

// The hand-drawn 福 is independent of the device's installed Chinese fonts.
final _fortuneGlyph = Path()
  ..moveTo(-22, -23)
  ..lineTo(-16, -17)
  ..moveTo(-28, -11)
  ..lineTo(-10, -11)
  ..quadraticBezierTo(-15, 2, -28, 10)
  ..moveTo(-19, 1)
  ..lineTo(-19, 25)
  ..moveTo(-17, 2)
  ..lineTo(-9, 9)
  ..moveTo(-5, -22)
  ..lineTo(24, -22)
  ..addRect(const Rect.fromLTRB(-2, -13, 21, -1))
  ..addRect(const Rect.fromLTRB(-5, 5, 24, 25))
  ..moveTo(9, 5)
  ..lineTo(9, 25)
  ..moveTo(-5, 15)
  ..lineTo(24, 15);

void _fortunePaper(Canvas g, double x, double y, double scale, double t) {
  g.save();
  g.translate(x, y);
  g.rotate(math.sin(_phase(t)) * .056);
  g.scale(scale);
  _glow(g, 9, 0, 106, _festVermilion, .44);
  _festivalShade(
    g,
    _festDiamond,
    const Offset(-40, -62),
    const Offset(41, 66),
    const [Color(0xFFCA3528), Color(0xFF96211E), Color(0xFF56131B)],
    const [0, .52, 1],
  );
  _stroke(g, _festDiamond, _festGold, .72, 1.15);
  _stroke(g, _festDiamondBorder, _festGold, .64, .88);
  for (final (px, py) in const [
    (0.0, -47.0),
    (47.0, 0.0),
    (0.0, 47.0),
    (-47.0, 0.0),
  ]) {
    _ellipse(g, px, py, 2, 2, _festCream, .9);
  }
  _stroke(g, _fortuneGlyph, _festCream, .97, 3.6);
  g.restore();
}

void _eveRoof(Canvas g) {
  const lattice = Color(0xFF531D1C);
  for (var j = 0; j < 8; j++) {
    final x = 257.0 + j * 42;
    _line(g, x, 14, x, 181, lattice, .64, 4);
    _line(g, x, 52, x + 42, 91, _festGold, .13);
    _line(g, x, 91, x + 42, 52, _festGold, .13);
  }
  for (final y in const [49.0, 94.0, 183.0]) {
    _line(g, 257, y, 584, y, lattice, .74, 4);
  }
  _festivalFill(g, _festRoof, const Color(0xFF1C131D));
  _stroke(g, _festRoof, _festGold, .23, 1.5);
  _line(g, 428, 21, 428, 40, _festGold, .74);
}

void _newYearsEve(Canvas g, double t) {
  final warmth = .83 + .17 * math.sin(_phase(t, 2));
  _glow(g, 435, 97, 239, const Color(0xFFC93D25), .51 * warmth);
  _glow(g, 436, 160, 144, _festGold, .36 * warmth);
  _eveRoof(g);
  _fortunePaper(g, 428, 102, .96, t);
  _festDust(g, t, 22);
}

void _festWater(Canvas g, double t, double y, Color color) {
  _glow(g, 418, y + 28, 258, color, .19);
  for (var i = 0; i < 42; i++) {
    final x = holidayRandom(i + 690) * 584;
    final h = y + math.pow(holidayRandom(i + 90), 1.5) * 125;
    final breath = .5 + .5 * math.sin(_phase(t, 3, i.toDouble()));
    final half = 3 + holidayRandom(i + 771) * 18;
    _line(
      g,
      x - half,
      h,
      x + half,
      h,
      color,
      .1 + .22 * breath,
      .65 + .7 * breath,
    );
  }
}

void _lotusLight(Canvas g, double x, double y, double scale, double t) {
  g.save();
  g.translate(x, y);
  g.scale(scale);
  final breath = .85 + .15 * math.sin(_phase(t, 8, x));
  _glow(g, 0, -5, 64, _festGold, .65 * breath);
  for (final (angle, color) in const [
    (-.56, Color(0xFFC33B40)),
    (1.22, _festVermilion),
    (-.11, Color(0xFFFD6C55)),
    (.72, Color(0xFFFF9A64)),
  ]) {
    g.save();
    g.rotate(angle);
    _festivalShade(
      g,
      _festLotusPetal,
      const Offset(0, 7),
      const Offset(-18, -22),
      [const Color(0xFF6D1F38), color, _festCream],
      const [0, .62, 1],
    );
    _stroke(g, _festLotusPetal, _festGold, .6, .75);
    g.restore();
  }
  _festivalFill(g, _festFlame, _festCream, breath);
  g.restore();
}

const _riverLanterns = [
  (287.0, 153.0, .55),
  (477.0, 123.0, .57),
  (545.0, 168.0, .84),
  (384.0, 185.0, 1.52),
  (487.0, 206.0, 1.14),
  (124.0, 140.0, .33),
];

void _lanternFestival(Canvas g, double t) {
  _festStars(g, t, _festCream, .42);
  _festWater(g, t, 126, const Color(0xFFB96470));
  for (final (i, (x0, y0, scale)) in _riverLanterns.indexed) {
    final x = x0 + math.sin(_phase(t, 1, i.toDouble())) * 19;
    final y = y0 + math.sin(_phase(t, 2, i.toDouble())) * 4;
    for (var j = 0; j < 5; j++) {
      final dx = math.sin(_phase(t, 3, (j + i).toDouble())) * 9;
      final half = scale * (14 - j * 2);
      final row = y + j * 7 + 7;
      _line(
        g,
        x + dx - half,
        row,
        x + dx + half,
        row,
        _festGold,
        .51 - j * .076,
        1.4,
      );
    }
    _lotusLight(g, x, y, scale, t);
  }
}

void _dragonBoat(Canvas g, double x, double y, double scale, double t) {
  g.save();
  g.translate(x, y);
  g.scale(scale);
  for (var i = 0; i < 5; i++) {
    final px = -54.0 + i * 24;
    final paddlePhase = _phase(t, 8, i * .12);
    final hand = px + math.sin(paddlePhase) * 5;
    final ex = px - 13 + 21 * math.cos(paddlePhase);
    final ey = 30 + math.sin(paddlePhase) * 12;
    _line(g, px - 2, -12, px + 3, 12, const Color(0xFFB5402F), .96, 10);
    _ellipse(g, px + 1, -20, 4.3, 5.8, const Color(0xFFE9B381), 1);
    _line(g, px - 5, -24, px + 6, -24, _festGold, .86, 2);
    _line(g, px, -8, hand + 5, 3, _festCream, .87, 2.7);
    _line(g, hand + 9, -7, ex, ey, _festGold, .89, 2.5);
    _ellipse(g, ex, ey, 3.4, 6.5, const Color(0xFFDF9A50), .96, -.35);
    final splash = holidaySmooth(.38, .92, math.sin(paddlePhase));
    for (var j = 0; j < 3; j++) {
      _ellipse(g, ex - j * 5, ey - j * 3, 1.4, 1, _festJade, splash * .84);
    }
  }
  _festivalShade(
    g,
    _festHull,
    const Offset(0, -12),
    const Offset(0, 34),
    const [_festGold, Color(0xFF86A465), Color(0xFF22786A), Color(0xFF1F3943)],
    const [0, .34, .58, 1],
  );
  _stroke(g, _festHull, _festGold, .82, 1.5);
  for (var x = -66.0; x < 87; x += 10) {
    _line(g, x, 18, x + 6, 25, _festGold, .61, .85);
  }
  _festivalShade(
    g,
    _festDragon,
    const Offset(100, -47),
    const Offset(115, 16),
    const [_festGold, Color(0xFFB5BF66), Color(0xFF349176), Color(0xFF144D4F)],
    const [0, .18, .56, 1],
  );
  _stroke(g, _festDragon, _festGold, .93, 1.2);
  _ellipse(g, 109, -33, 3.2, 3.2, _festCream, 1);
  _ellipse(g, 110, -33, 1.4, 1.4, const Color(0xFF2A2127), 1);
  _line(g, 125, -20, 141, -24, _festGold, .78);
  g.restore();
}

void _dragonBoatFestival(Canvas g, double t) {
  _festWater(g, t, 144, _festJade);
  final x = 380 + 36 * math.sin(_phase(t));
  final y = 146 + 3 * math.sin(_phase(t, 4));
  for (var i = 0; i < 11; i++) {
    final u = (i / 11 + t / _loop * 4) % 1;
    _line(
      g,
      x - 79 - u * 133,
      y + 24 + u * 20,
      x - 54 - u * 67,
      y + 27 + u * 18,
      _festJade,
      (1 - u) * .64,
      1.2,
    );
  }
  _dragonBoat(g, x, y, 1.01, t);
}

const _moonPatches = [
  (-16.0, 6.0, 16.0, 23.0, -.22),
  (10.0, -19.0, 16.0, 9.0, -.62),
  (24.0, 11.0, 15.0, 17.0, .82),
  (-4.0, 23.0, 24.0, 8.0, -.15),
  (-31.0, -12.0, 10.0, 13.0, .91),
  (29.0, -21.0, 9.0, 13.0, -.15),
];

void _harvestMoon(Canvas g, double x, double y, double radius) {
  _glow(g, x, y, radius * 3.2, _festGold, .37);
  final face = Path()
    ..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));
  _festivalShade(
    g,
    face,
    Offset(x - radius * .5, y - radius),
    Offset(x + radius * .5, y + radius),
    const [Color(0xFFFFF9D9), _festCream, Color(0xFFE6B972)],
    const [0, .53, 1],
  );
  g.save();
  g.clipPath(face);
  final scale = radius / 52;
  for (final (dx, dy, rx, ry, angle) in _moonPatches) {
    _ellipse(
      g,
      x + dx * scale,
      y + dy * scale,
      rx * scale,
      ry * scale,
      const Color(0xFFB18653),
      .15,
      angle,
    );
  }
  g.restore();
}

void _midAutumn(Canvas g, double t) {
  final open = .5 - .5 * math.cos(_phase(t));
  _festStars(g, t, _festBlue, .57);
  _harvestMoon(g, 426, 91 - open * 12, 51);
  _festivalShade(
    g,
    _festMoonHills,
    const Offset(0, 121),
    const Offset(0, 207),
    const [Color(0xF5203150), Color(0x26121A2A)],
  );
  for (final (x, y, size, opacity) in [
    (381 - open * 161, 87.0, 1.2, .83),
    (486 + open * 83, 117.0, .91, .73),
    (223 - open * 46, 54.0, .72, .47),
  ]) {
    g.save();
    g.translate(x, y);
    g.scale(size);
    _festivalShade(g, _festCloud, const Offset(0, -17), const Offset(0, 15), [
      _a(const Color(0xFF474D6F), opacity),
      _a(const Color(0xFF19203A), opacity),
    ]);
    _stroke(g, _festCloud, _festCream, opacity * .25, .7);
    g.restore();
  }
  _festWater(g, t, 169, const Color(0xFF768CC0));
  for (var i = 0; i < 17; i++) {
    final w = 6 + holidayRandom(i + 973) * 32;
    final dx = math.sin(_phase(t, 2, i.toDouble())) * (9 + i);
    final y = 176.0 + i * 5;
    _line(
      g,
      426 + dx - w,
      y,
      426 + dx + w,
      y,
      _festGold,
      open * .52 * (1 - i / 19),
      1.2,
    );
  }
}

void _litFestivalGate(Canvas g, double x, double y, double scale, double t) {
  g.save();
  g.translate(x, y);
  g.scale(scale);
  _festivalShade(g, _festGateBody, Offset.zero, const Offset(0, 45), const [
    Color(0xFF6A2628),
    Color(0xFF2A131F),
  ]);
  for (var i = -2; i <= 2; i++) {
    final dx = i * 20.0;
    _line(g, dx - 6, 7, dx - 6, 43, const Color(0xFFB7492F), .72, 2);
    g.drawRect(
      Rect.fromLTWH(dx - 2.5, 14, 6, 18),
      Paint()
        ..color = _a(_festGold, .7 + .2 * math.sin(_phase(t, 3, i.toDouble()))),
    );
    _glow(g, dx + 1, 20, 15, _festGold, .31);
  }
  _festivalFill(g, _festGateRoof, const Color(0xFF6C2528));
  _stroke(g, _festGateRoof, _festGold, .88, 1.3);
  _stroke(g, _festRoofRidge, _festCream, .81);
  _line(g, -73, 44, 73, 44, _festGold, .77, 1.25);
  g.restore();
}

void _nationalDay(Canvas g, double t) {
  for (var layer = 0; layer < 3; layer++) {
    final height = 19 + layer * 12;
    final phase = _phase(t, 1, layer * 1.48);
    double yAt(double x) =>
        35 +
        layer * 37 +
        (x - 280) * -.127 +
        math.sin(x * .011 + phase) * (23 + layer * 3);
    final ribbon = Path()..moveTo(-16, yAt(-16));
    for (var x = -8.0; x <= 608; x += 8) {
      ribbon.lineTo(x, yAt(x));
    }
    for (var x = 608.0; x >= -16; x -= 8) {
      ribbon.lineTo(x, yAt(x) + height);
    }
    ribbon.close();
    _festivalShade(
      g,
      ribbon,
      const Offset(0, 125),
      const Offset(584, 19),
      const [
        Color(0x5C591528),
        Color(0x8FAF2835),
        Color(0xB5FF5D41),
        Color(0x94981F2D),
      ],
      const [0, .35, .63, 1],
    );
    _stroke(g, ribbon, _festGold, .18 + layer * .074, .9);
  }
  _festDust(g, t, 35);
  _litFestivalGate(g, 420, 140, 1.28, t);
  _litFestivalGate(g, 420, 104, .91, t);
}

void _newYearDateBadge(Canvas g, double t) {
  _glow(g, 0, 1, 31, _festBlue, .5);
  _festivalShade(
    g,
    _festCalendarPage,
    const Offset(-12, -16),
    const Offset(12, 19),
    const [Color(0xFFF4FAFF), Color(0xFFA6CBFA)],
  );
  _festivalShade(
    g,
    _festCalendarHeader,
    const Offset(0, -17),
    const Offset(0, -6),
    const [Color(0xFF5898EC), Color(0xFF315CA6)],
  );
  _festivalFill(g, _festCalendarFold, const Color(0xFF6A9DDD));
  _stroke(g, _festCalendarPage, const Color(0xFFEEF8FF), .9, 1.45);
  _stroke(g, _festCalendarOne, const Color(0xFF20417F), .99, 3.5);
  for (final x in const [-10.0, 11.0]) {
    _line(g, x, -21, x, -12, _festGold, .98, 3.8);
  }
  final glint = .7 + .3 * math.sin(_phase(t, 2));
  _line(g, 22, -17, 32, -17, _festCream, glint, 1.7);
  _line(g, 27, -22, 27, -12, _festCream, glint, 1.7);
}

void _labourDateBadge(Canvas g) {
  _glow(g, 1, 1, 32, _festGold, .43);
  _festivalShade(
    g,
    _festHelmetDome,
    const Offset(-7, -19),
    const Offset(13, 9),
    const [_festCream, _festGold, Color(0xFFD07225)],
    const [0, .46, 1],
  );
  _festivalShade(
    g,
    _festHelmetRidge,
    const Offset(1, -19),
    const Offset(1, 5),
    const [Color(0xFFFFF1B5), Color(0xFFF09D3E)],
  );
  _festivalShade(
    g,
    _festHelmetBrim,
    const Offset(-3, 5),
    const Offset(-3, 15),
    const [Color(0xFFFFDD8C), _festGold, Color(0xFFA84C1A)],
    const [0, .46, 1],
  );
  _stroke(g, _festHelmetDome, _festCream, .82, 1.45);
  _stroke(g, _festHelmetBrim, _festCream, .77, 1.4);
}

Path _flagStar(double x, double y, double radius, double angle) {
  final points = [
    for (var i = 0; i < 10; i++)
      Offset(x, y) +
          Offset.fromDirection(
            angle + i * _tau / 10,
            i.isEven ? radius : radius * .382,
          ),
  ];
  return Path()..addPolygon(points, true);
}

// Five stars on the official 30 × 20 construction grid.
final _flagStars = Path()
  ..addPath(_flagStar(5, 5, 3, -math.pi / 2), Offset.zero)
  ..addPath(_flagStar(10, 2, 1, math.atan2(3, -5)), Offset.zero)
  ..addPath(_flagStar(12, 4, 1, math.atan2(1, -7)), Offset.zero)
  ..addPath(_flagStar(12, 7, 1, math.atan2(-2, -7)), Offset.zero)
  ..addPath(_flagStar(10, 9, 1, math.atan2(-4, -5)), Offset.zero);

void _nationalDateBadge(Canvas g) {
  _glow(g, 3, -5, 32, _festVermilion, .36);
  _line(g, -20, -21, -20, 21, _festGold, 1, 3.7);
  _ellipse(g, -20, -22, 2.4, 2.4, _festCream, 1);
  g.save();
  g.translate(-18, -18);
  g.scale(1.46);
  _festivalShade(
    g,
    _festFlagCloth,
    Offset.zero,
    const Offset(30, 20),
    const [Color(0xFFED3E35), Color(0xFFD1282D), Color(0xFFAA1C22)],
    const [0, .66, 1],
  );
  _stroke(g, _festFlagCloth, const Color(0xFFF57060), .96, .62);
  _festivalFill(g, _flagStars, const Color(0xFFFFDE39));
  g.restore();
}
