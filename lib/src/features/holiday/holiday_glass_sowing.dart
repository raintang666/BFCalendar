part of 'holiday_glass_scene.dart';

const _sowingPeriod = HolidayCalendarDesign.sowingCycleSeconds;
const _farmerOrigin = Offset(333, 94);
const _hip = Offset(0, 36);
const _shoulder = Offset(11, 0);
const _seedGold = Color(0xFFFECF83);

final _trousers = Path()
  ..moveTo(-11, 31)
  ..lineTo(10, 31)
  ..lineTo(23, 95)
  ..lineTo(11, 97)
  ..lineTo(-1, 59)
  ..lineTo(-16, 97)
  ..lineTo(-28, 95)
  ..lineTo(-16, 50)
  ..close();

final _trouserSeams = Path()
  ..moveTo(-12, 49)
  ..lineTo(-22, 86)
  ..moveTo(8, 51)
  ..lineTo(17, 86);

final _tunic = Path()
  ..moveTo(-11, -8)
  ..quadraticBezierTo(-1, -13, 13, -4)
  ..lineTo(18, 36)
  ..quadraticBezierTo(4, 44, -18, 35)
  ..lineTo(-19, 11)
  ..close();

final _tunicSeams = Path()
  ..moveTo(-3, -6)
  ..lineTo(4, 7)
  ..lineTo(12, -1)
  ..moveTo(3, 7)
  ..lineTo(0, 33)
  ..moveTo(-14, 29)
  ..lineTo(16, 32);

final _profile = Path()
  ..moveTo(12, -26)
  ..lineTo(19, -20)
  ..lineTo(13, -17)
  ..close();

final _seedBasket = Path()
  ..moveTo(-24, 21)
  ..quadraticBezierTo(-10, 16, 3, 23)
  ..lineTo(-1, 38)
  ..quadraticBezierTo(-10, 44, -20, 36)
  ..close();

final _hatCone = Path()
  ..moveTo(-30, 2)
  ..quadraticBezierTo(-10, -16, 2, -19)
  ..quadraticBezierTo(16, -12, 30, 2)
  ..close();

final _hatRim = Path()
  ..moveTo(-31, 1)
  ..quadraticBezierTo(0, 11, 31, 1);

final _tunicPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-21, -2),
    const Offset(18, 34),
    const [Color(0xFFC49A64), Color(0xFF8B704C), Color(0xFF524F3E)],
    const [0, .5, 1],
  );

final _hatPaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-24, -10),
    const Offset(22, 4),
    const [Color(0xFFEFCA86), Color(0xFFB68C51), Color(0xFF6E5537)],
    const [0, .52, 1],
  );

void _sowingLandscape(Canvas canvas) {
  _glow(canvas, 434, 54, 237, const Color(0xFFEAA44A), .24);
  _glow(canvas, 464, 205, 164, const Color(0xFF86AD7D), .12);
  _glow(canvas, 434, 51, 64, const Color(0xFFEEBC6B), .16);
  _ellipse(canvas, 434, 51, 18, 18, const Color(0xFFEFC580), .17);
  for (var i = 0; i < 4; i++) {
    final ridge = Path()
      ..moveTo(183, 180.0 + i * 19)
      ..cubicTo(333, 142.0 + i * 21, 454, 194.0 + i * 13, 610, 161.0 + i * 20);
    _stroke(canvas, ridge, const Color(0xFFB6A268), .13 - i * .019, 1.1);
  }
}

void _strawHat(Canvas canvas, Offset center, double scale, double angle) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  canvas.drawPath(_hatCone, _hatPaint);
  _ellipse(canvas, 0, 2, 33, 5, const Color(0xFFB89157), 1);
  for (var i = -5; i <= 5; i++) {
    _line(canvas, 2, -17, i * 5.7, 2, const Color(0xFFEFCE8F), .34, .55);
  }
  _stroke(canvas, _hatRim, const Color(0xFFF3D397), .75, .85);
  canvas.restore();
}

({double lean, Offset wrist, Offset elbow, double direction}) _sowingPose(
  double progress,
) {
  final cast =
      holidaySmooth(.12, .43, progress) *
      (1 - holidaySmooth(.50, .76, progress));
  final wrist = Offset(18 + 51 * cast, 24 - 39 * cast);
  final arm = wrist - _shoulder;
  final halfReach = arm.distance / 2;
  final bend = math.sqrt(31 * 31 - halfReach * halfReach);
  final elbow =
      (_shoulder + wrist) / 2 + Offset(-arm.dy, arm.dx) * (bend / arm.distance);
  return (
    lean: -.082 + cast * .13,
    wrist: wrist,
    elbow: elbow,
    direction: arm.direction,
  );
}

void _sowingFarmer(Canvas canvas, double progress) {
  final pose = _sowingPose(progress);
  canvas.save();
  canvas.translate(_farmerOrigin.dx, _farmerOrigin.dy);
  _ellipse(canvas, -2, 98, 40, 4.6, const Color(0xFFE8B76F), .13);
  canvas.drawPath(_trousers, Paint()..color = const Color(0xFF414C40));
  _stroke(canvas, _trouserSeams, const Color(0xFF8E9671), .38, .9);
  _line(canvas, -27, 96, -14, 97, const Color(0xFF7E7F66), .96, 3);
  _line(canvas, 11, 97, 25, 96, const Color(0xFF7E7F66), .96, 3);

  // Rotate the upper body at the hips while both feet stay planted.
  canvas.translate(0, _hip.dy);
  canvas.rotate(pose.lean);
  canvas.translate(0, -_hip.dy);
  canvas.drawPath(_tunic, _tunicPaint);
  _stroke(canvas, _tunicSeams, const Color(0xFFE5C488), .52, 1);
  _line(canvas, 5, -17, 5, -6, const Color(0xFFA47E58), 1, 6);
  _ellipse(canvas, 7, -23, 8.8, 11.5, const Color(0xFFBC9466), 1, .1);
  canvas.drawPath(_profile, Paint()..color = const Color(0xFFC6996B));
  _strawHat(canvas, const Offset(5, -32), .89, -.13);

  final elbow = pose.elbow, wrist = pose.wrist;
  _line(
    canvas,
    _shoulder.dx,
    _shoulder.dy,
    elbow.dx,
    elbow.dy,
    const Color(0xFF9F7D50),
    1,
    9,
  );
  _line(
    canvas,
    elbow.dx,
    elbow.dy,
    wrist.dx,
    wrist.dy,
    const Color(0xFFC69D6E),
    1,
    5.4,
  );
  _ellipse(
    canvas,
    wrist.dx + 2,
    wrist.dy,
    4.5,
    2.9,
    const Color(0xFFCDA473),
    1,
    pose.direction,
  );
  _line(canvas, -13, 1, -25, 18, const Color(0xFFA07E52), 1, 8);
  _line(canvas, -25, 18, -13, 26, const Color(0xFFB78D61), 1, 4.6);
  canvas.drawPath(_seedBasket, Paint()..color = const Color(0xFF926B41));
  _ellipse(canvas, -10, 23, 14, 4, const Color(0xFFDBB369), .96);
  for (var i = 0; i < 4; i++) {
    _line(
      canvas,
      -21.0 + i * 6,
      25,
      -17.0 + i * 4,
      37,
      const Color(0xFFEBC57F),
      .45,
      .65,
    );
  }
  _line(canvas, -21, 30, 0, 32, const Color(0xFFE5C279), .5, .6);
  _line(canvas, -19, 35, -2, 37, const Color(0xFFE5C279), .45, .6);
  canvas.restore();
}

final _sowingSeeds = List.generate(24, (i) {
  final born = .30 + holidayRandom(i + 2300) * .106;
  final pose = _sowingPose(born);
  final hand = pose.wrist + const Offset(4, 0) - _hip;
  final cos = math.cos(pose.lean), sin = math.sin(pose.lean);
  return (
    born: born,
    flight: .24 + holidayRandom(i + 2430) * .10,
    start:
        _farmerOrigin +
        _hip +
        Offset(cos * hand.dx - sin * hand.dy, sin * hand.dx + cos * hand.dy),
    end: Offset(
      430 + i * 5.75 + holidayRandom(i + 2350) * 9,
      182 + holidayRandom(i + 2400) * 33,
    ),
    lift: 39 + holidayRandom(i + 2450) * 24,
    shootSize: .67 + .46 * holidayRandom(i + 2510),
    grows: i % 4 == 0,
  );
});

const _shootBlades = [
  (length: 24, bend: -17),
  (length: 34, bend: -10),
  (length: 32, bend: 3),
  (length: 26, bend: 13),
];

void _riceTuft(
  Canvas canvas,
  Offset root,
  double seconds,
  double growth,
  double opacity,
) {
  canvas.save();
  canvas.translate(root.dx, root.dy);
  for (final blade in _shootBlades) {
    final length = blade.length * growth;
    final sway = math.sin(_phase(seconds, 2, root.dx * .023));
    final bend = (blade.bend + sway * 2.3) * growth;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(bend * .14, -length * .57, bend, -length)
      ..quadraticBezierTo(bend * .52 + 1.6, -length * .38, 1, 0);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(bend, -length),
          [
            _a(const Color(0xFF2D704D), opacity * .82),
            _a(const Color(0xFF6BB165), opacity),
            _a(const Color(0xFFC4E490), opacity),
          ],
          const [0, .54, 1],
        ),
    );
  }
  canvas.restore();
}

void _mangzhong(Canvas canvas, double seconds) {
  final progress = seconds % _sowingPeriod / _sowingPeriod;
  final fade = 1 - holidaySmooth(.92, 1, progress);
  _sowingFarmer(canvas, progress);
  for (final seed in _sowingSeeds) {
    final elapsed = progress - seed.born;
    if (elapsed < 0) continue;
    final p = elapsed / seed.flight;
    if (p < 1) {
      // Each arc starts at the hand's position at release and ends at its own root.
      final point =
          Offset.lerp(seed.start, seed.end, p)! -
          Offset(0, seed.lift * 4 * p * (1 - p));
      final travel = seed.end - seed.start;
      final angle = math.atan2(
        travel.dy - seed.lift * 4 * (1 - 2 * p),
        travel.dx,
      );
      final opacity = holidayLerp(.45, .99, holidaySmooth(0, .17, p));
      if (seed.grows) {
        _glow(canvas, point.dx, point.dy, 8, _seedGold, .2 * opacity);
      }
      _ellipse(
        canvas,
        point.dx,
        point.dy,
        2.65,
        1.24,
        _seedGold,
        opacity,
        angle,
      );
    } else {
      final landed = elapsed - seed.flight;
      final shine = (1 - holidaySmooth(0, .055, landed)) * fade;
      _glow(canvas, seed.end.dx, seed.end.dy, 7, _seedGold, .21 * shine);
      if (seed.grows && landed > .018) {
        final growth = holidaySmooth(.018, .24, landed) * seed.shootSize;
        _riceTuft(canvas, seed.end, seconds, growth, fade * .86);
      }
    }
  }
}

void _sowingBadge(Canvas canvas, double seconds) {
  _strawHat(canvas, const Offset(0, -4), .65, -.2);
  for (var i = 0; i < 3; i++) {
    final progress = (seconds / _sowingPeriod + i * .2) % 1;
    _ellipse(
      canvas,
      10 + progress * 24,
      -10 + progress * progress * 25,
      1,
      2,
      _seedGold,
      math.sin(progress * math.pi),
    );
  }
}
