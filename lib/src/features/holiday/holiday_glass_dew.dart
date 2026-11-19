part of 'holiday_glass_scene.dart';

const _dewSilver = Color(0xFFE1F4ED);
const _dewMoss = [Color(0xFF284337), Color(0xFF46685A), Color(0xFF668575)];
const _dewSage = [Color(0xFF2B4E42), Color(0xFF628064), Color(0xFF8E9E73)];
const _dewOlive = [Color(0xFF2A5045), Color(0xFF789573), Color(0xFFA8AD78)];

typedef _DewBead = ({double position, double radius, double delay});

class _DewBlade {
  _DewBlade(
    this.root,
    this.first,
    this.second,
    this.tip, {
    required this.width,
    required this.colors,
    required this.sway,
    this.delay = 0,
    this.bead,
  });

  final Offset root, first, second, tip;
  final double width, sway, delay;
  final List<Color> colors;
  final _DewBead? bead;

  late final _blade = _face(-1);
  late final _fold = _face(0);
  late final _midrib = _curve(.15, .94, 0);
  late final _fill = Paint()
    ..shader = ui.Gradient.linear(root, tip, colors, const [0, .60, 1]);

  double angleAt(double seconds) => math.sin(_phase(seconds, 2, -delay)) * sway;

  Offset _spine(double u) {
    final v = 1 - u;
    return root * (v * v * v) +
        first * (3 * v * v * u) +
        second * (3 * v * u * u) +
        tip * (u * u * u);
  }

  Offset surface(double u, double side) {
    final tangent =
        _spine(math.min(1, u + .001)) - _spine(math.max(0, u - .001));
    final taper = math.pow(math.sin(math.pi * u), 1.1).toDouble();
    final fold = side < 0
        ? 1 + .10 * math.sin(u * 16)
        : .45 * (1 + .22 * math.sin(u * 11));
    final offset = side * (width * taper * fold + 1.8 * (1 - u));
    return _spine(u) +
        Offset(-tangent.dy, tangent.dx) * (offset / tangent.distance);
  }

  Path _curve(double from, double to, double side) => Path()
    ..addPolygon([
      for (var step = 0; step <= 56; step++)
        surface(from + (to - from) * step / 56, side),
    ], false);

  Path _face(double side) => Path()
    ..addPolygon([
      for (var step = 0; step <= 56; step++) surface(step / 56, side),
      for (var step = 55; step >= 0; step--) surface(step / 56, 1),
    ], true);

  void paint(Canvas canvas, double seconds) {
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.rotate(angleAt(seconds));
    canvas.translate(-root.dx, -root.dy);
    canvas.drawPath(_blade, _fill);
    canvas.drawPath(_fold, _dewFoldPaint);
    _stroke(canvas, _midrib, const Color(0xFFC8D8AA), .29, .65);
    final bead = this.bead;
    if (bead != null) {
      final formed =
          holidaySmooth(bead.delay, bead.delay + 1.2, seconds) *
          (1 - holidaySmooth(10.5, 12.85, seconds));
      _dewDrop(
        canvas,
        surface(bead.position, -.20),
        bead.radius * formed,
        .80 * formed,
        seconds + bead.position,
      );
    }
    canvas.restore();
  }
}

final _dewFoldPaint = Paint()..color = const Color(0x5C102F28);
final _dewDripBlade = _DewBlade(
  const Offset(361, 238),
  const Offset(394, 166),
  const Offset(468, 136),
  const Offset(492, 174),
  width: 7.4,
  colors: _dewOlive,
  sway: .052,
);

// The blade order keeps the tips at different depths and the crowns together.
final _dewGrass = [
  _DewBlade(
    const Offset(346, 238),
    const Offset(330, 159),
    const Offset(291, 124),
    const Offset(243, 135),
    width: 6.3,
    colors: _dewMoss,
    sway: -.054,
  ),
  _DewBlade(
    const Offset(356, 239),
    const Offset(346, 158),
    const Offset(301, 119),
    const Offset(307, 81),
    width: 5,
    colors: _dewMoss,
    sway: .055,
    delay: .21,
  ),
  _DewBlade(
    const Offset(353, 240),
    const Offset(355, 148),
    const Offset(382, 94),
    const Offset(364, 58),
    width: 4.3,
    colors: _dewSage,
    sway: .043,
    delay: .42,
    bead: (position: .73, radius: 2.2, delay: .48),
  ),
  _DewBlade(
    const Offset(369, 238),
    const Offset(379, 156),
    const Offset(401, 107),
    const Offset(446, 84),
    width: 5,
    colors: _dewMoss,
    sway: .065,
    delay: .63,
  ),
  _dewDripBlade,
  _DewBlade(
    const Offset(332, 239),
    const Offset(314, 197),
    const Offset(264, 169),
    const Offset(229, 186),
    width: 5.8,
    colors: _dewSage,
    sway: .071,
    delay: .21,
  ),
  _DewBlade(
    const Offset(341, 238),
    const Offset(317, 192),
    const Offset(322, 148),
    const Offset(280, 118),
    width: 8.6,
    colors: _dewSage,
    sway: .065,
    delay: .42,
    bead: (position: .61, radius: 2.5, delay: .21),
  ),
  _DewBlade(
    const Offset(355, 239),
    const Offset(346, 195),
    const Offset(369, 137),
    const Offset(341, 96),
    width: 6.8,
    colors: _dewOlive,
    sway: .063,
    delay: .63,
    bead: (position: .83, radius: 1.9, delay: .72),
  ),
  _DewBlade(
    const Offset(364, 239),
    const Offset(354, 192),
    const Offset(386, 151),
    const Offset(396, 124),
    width: 4.7,
    colors: _dewSage,
    sway: .051,
  ),
  _DewBlade(
    const Offset(374, 238),
    const Offset(394, 181),
    const Offset(438, 169),
    const Offset(453, 156),
    width: 5.7,
    colors: _dewOlive,
    sway: .052,
    delay: .21,
    bead: (position: .67, radius: 2.9, delay: .38),
  ),
  _DewBlade(
    const Offset(331, 241),
    const Offset(317, 226),
    const Offset(287, 220),
    const Offset(253, 224),
    width: 4.8,
    colors: _dewMoss,
    sway: .065,
    delay: .42,
  ),
  _DewBlade(
    const Offset(348, 240),
    const Offset(326, 224),
    const Offset(320, 187),
    const Offset(296, 172),
    width: 6,
    colors: _dewOlive,
    sway: .049,
    delay: .63,
  ),
  _DewBlade(
    const Offset(357, 241),
    const Offset(361, 211),
    const Offset(344, 190),
    const Offset(349, 163),
    width: 3.3,
    colors: _dewMoss,
    sway: .078,
  ),
  _DewBlade(
    const Offset(359, 241),
    const Offset(379, 221),
    const Offset(379, 203),
    const Offset(410, 186),
    width: 6,
    colors: _dewSage,
    sway: .067,
    delay: .21,
  ),
  _DewBlade(
    const Offset(371, 241),
    const Offset(398, 219),
    const Offset(423, 214),
    const Offset(461, 224),
    width: 4.8,
    colors: _dewSage,
    sway: .083,
    delay: .42,
  ),
];

void _dewDrop(
  Canvas canvas,
  Offset center,
  double radius,
  double opacity,
  double seconds, [
  double stretch = 1,
]) {
  if (opacity <= .01 || radius <= .1) return;
  final x = center.dx, y = center.dy;
  _glow(canvas, x, y, radius * 2.8, const Color(0xFFBDE4DD), opacity * .25);
  final glint = .53 + .47 * math.sin(_phase(seconds, 1, .65));
  final shape = Rect.fromCenter(
    center: center,
    width: radius * 1.74,
    height: radius * 2.06 * stretch,
  );
  canvas.drawOval(
    shape,
    Paint()
      ..shader = ui.Gradient.radial(
        center + Offset(0, radius * .12),
        radius * 1.35,
        [
          _a(const Color(0xFFFCFFF1), opacity * .96),
          _a(const Color(0xFFE0F7E2), opacity * (.75 + glint * .15)),
          _a(const Color(0xFF8AB4AC), opacity * .45),
          _a(const Color(0xFF4B787C), opacity * .57),
          _a(const Color(0xFFB6E1DC), opacity * .34),
        ],
        const [0, .18, .45, .77, 1],
        TileMode.clamp,
        null,
        center - Offset(radius * .35, radius * .43),
        radius * .04,
      ),
  );
  canvas.drawOval(
    shape,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius > 7 ? 1 : .68
      ..color = _a(_dewSilver, opacity * .76),
  );
  _ellipse(
    canvas,
    x - radius * .27,
    y - radius * .46,
    radius * .29,
    radius * .18,
    const Color(0xFFFBFFF2),
    opacity * (.78 + glint * .22),
    -.58,
  );
  _ellipse(
    canvas,
    x + radius * .23,
    y + radius * .59 * stretch,
    radius * .27,
    radius * .13,
    const Color(0xFFD8FBE8),
    opacity * .70,
    -.24,
  );
}

class _DewPlume {
  _DewPlume(this.root, double length, this.lean, this.opacity) {
    _stem
      ..moveTo(0, 0)
      ..quadraticBezierTo(6, -length * .58, -4, -length);
    for (var i = 0; i < 12; i++) {
      final y = -length * (.63 + i * .032);
      final distance = 7 + math.sin(i / 11 * math.pi) * 9;
      _branches
        ..moveTo(0, y + 5)
        ..quadraticBezierTo(-distance * .42, y - 4, -distance, y - 10)
        ..moveTo(0, y + 5)
        ..quadraticBezierTo(distance * .36, y - 6, distance * .82, y - 10);
      _buds.addAll([Offset(-distance, y - 10), Offset(distance * .82, y - 10)]);
    }
  }

  final Offset root;
  final double lean, opacity;
  final _stem = Path();
  final _branches = Path();
  final _buds = <Offset>[];

  void paint(Canvas canvas, double seconds) {
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.rotate(lean + math.sin(_phase(seconds, 1, lean)) * .05);
    _stroke(canvas, _stem, const Color(0xFF9AA589), opacity * .74, 1.25);
    _stroke(canvas, _branches, const Color(0xFFD0D4B4), opacity * .68, 1.05);
    for (var i = 0; i < _buds.length; i++) {
      final bud = _buds[i];
      _ellipse(
        canvas,
        bud.dx,
        bud.dy,
        1.25,
        i.isEven ? 2.8 : 2.4,
        const Color(0xFFE0E0C2),
        opacity * (i.isEven ? .72 : .67),
        i.isEven ? -.47 : .42,
      );
    }
    canvas.restore();
  }
}

final _dewPlumes = [
  _DewPlume(const Offset(346, 239), 174, -.49, .34),
  _DewPlume(const Offset(367, 239), 185, .28, .37),
];

void _dewDrip(Canvas canvas, double seconds) {
  const release = 7.15;
  final fall = holidayClamp((seconds - release) / 1.04);
  if (fall == 1) return;

  final attachedTime = math.min(seconds, release);
  final slide = holidaySmooth(3.15, 6.35, attachedTime);
  final hanging = holidaySmooth(.83, 1, slide);
  final grown = holidayDewGrowth(attachedTime);
  final radius = 2.6 + 5.8 * grown;
  final root = _dewDripBlade.root;
  final leaf = _dewDripBlade.surface(.61 + .39 * slide, -.20);
  final tension = holidaySmooth(6.65, release, attachedTime);
  final offset =
      leaf - root + Offset(0, hanging * radius * (1.03 + .18 * tension));
  final angle = _dewDripBlade.angleAt(attachedTime);
  final cos = math.cos(angle), sin = math.sin(angle);
  // Freeze the swaying tip's position at release, then accelerate downward.
  final center =
      root +
      Offset(
        offset.dx * cos - offset.dy * sin + 2.8 * fall,
        offset.dx * sin + offset.dy * cos + 10 * fall + 59 * fall * fall,
      );
  final opacity = grown * (1 - holidaySmooth(.69, 1, fall));
  final stretch = .88 + .39 * hanging + .13 * math.sin(math.pi * fall);
  _dewDrop(canvas, center, radius, opacity, seconds, stretch);
}

void _bailu(Canvas canvas, double seconds) {
  final morning =
      holidaySmooth(.15, 6.6, seconds) *
      (1 - holidaySmooth(10.5, _loop, seconds));
  _glow(canvas, 339, 36, 203, const Color(0xFFDFDBB5), .12 + morning * .18);
  _glow(canvas, 495, 182, 190, const Color(0xFF5D9D8C), .13);

  for (var i = 0; i < 3; i++) {
    final drift = 18 * math.sin(_phase(seconds, 1, i * .75));
    canvas.save();
    canvas.translate(238 + i * 114.0 + drift, 184 + i * 14.0);
    canvas.scale(1, .19);
    _glow(
      canvas,
      0,
      0,
      166,
      const Color(0xFFBADBD2),
      .08 * (1 - .57 * morning),
    );
    canvas.restore();
  }

  // Give the native date and weekday label room beside the grass.
  canvas.save();
  canvas.translate(38, 0);
  for (final plume in _dewPlumes) {
    plume.paint(canvas, seconds);
  }
  for (final blade in _dewGrass) {
    blade.paint(canvas, seconds);
  }
  _dewDrip(canvas, seconds);
  canvas.restore();
}

final _dewBadgeLeaf = Path()
  ..moveTo(-27, 12)
  ..cubicTo(-10, -20, 16, -23, 30, -5)
  ..cubicTo(8, -11, -10, 0, -27, 12)
  ..close();
final _dewBadgeMidrib = Path()
  ..moveTo(-24, 10)
  ..quadraticBezierTo(2, -12, 27, -6);
final _dewBadgePaint = Paint()
  ..shader = ui.Gradient.linear(
    const Offset(-24, 9),
    const Offset(18, -14),
    const [Color(0xFF679D8C), Color(0xFFC8DFAA)],
  );

void _dewBadge(Canvas canvas, double seconds) {
  canvas.drawPath(_dewBadgeLeaf, _dewBadgePaint);
  _stroke(canvas, _dewBadgeMidrib, const Color(0xFFE0F4CF), .86, 1.55);
  final sway = 2.1 * math.sin(_phase(seconds, 2, .4));
  _dewDrop(canvas, Offset(23 + sway, 6), 9.7, 1, seconds, 1.18);
}
