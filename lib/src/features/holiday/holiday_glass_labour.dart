part of 'holiday_glass_scene.dart';

final _festTowerOutline = Path()
  ..moveTo(515, 204)
  ..lineTo(515, 25)
  ..lineTo(527, 10)
  ..lineTo(540, 25)
  ..lineTo(540, 204)
  ..close();

final _festBoomOutline = Path()
  ..moveTo(297, 61)
  ..lineTo(319, 48)
  ..lineTo(569, 48)
  ..lineTo(579, 61)
  ..close();

final _festCraneCables = Path()
  ..moveTo(325, 78)
  ..lineTo(527, 10)
  ..lineTo(568, 78);

final _festCraneCab = Path()
  ..moveTo(500, 54)
  ..lineTo(518, 54)
  ..lineTo(518, 72)
  ..lineTo(494, 72)
  ..lineTo(494, 60)
  ..close();

final _festCabGlass = Path()
  ..moveTo(501, 57)
  ..lineTo(513, 57)
  ..lineTo(513, 65)
  ..lineTo(496, 65)
  ..lineTo(496, 62)
  ..close();

final _festLiftHook = Path()
  ..moveTo(0, -5)
  ..lineTo(0, 1)
  ..cubicTo(0, 8, 8, 8, 8, 2);

final _festFrameBack = Path()
  ..moveTo(383, 153)
  ..lineTo(409, 140)
  ..lineTo(486, 140)
  ..lineTo(493, 153)
  ..lineTo(493, 223)
  ..lineTo(383, 223)
  ..close();

final _festFrameFront = Path()
  ..moveTo(384, 153)
  ..lineTo(493, 153)
  ..lineTo(493, 224)
  ..lineTo(384, 224)
  ..close();

final _festWorksiteHorizon = Path()
  ..moveTo(-7, 216)
  ..lineTo(47, 216)
  ..lineTo(47, 182)
  ..lineTo(73, 182)
  ..lineTo(73, 203)
  ..lineTo(107, 203)
  ..lineTo(107, 181)
  ..lineTo(130, 181)
  ..lineTo(130, 209)
  ..lineTo(192, 209)
  ..lineTo(192, 185)
  ..lineTo(213, 185)
  ..lineTo(213, 205)
  ..lineTo(257, 205)
  ..lineTo(257, 167)
  ..lineTo(279, 167)
  ..lineTo(279, 190)
  ..lineTo(317, 190)
  ..lineTo(317, 213)
  ..lineTo(537, 213)
  ..lineTo(537, 169)
  ..lineTo(557, 169)
  ..lineTo(557, 193)
  ..lineTo(589, 193)
  ..lineTo(589, 245)
  ..lineTo(-7, 245)
  ..close();

final _festBeamPlatform = Path()
  ..moveTo(274, 192)
  ..lineTo(346, 192)
  ..lineTo(359, 200)
  ..lineTo(263, 200)
  ..close();

final _festSteelBeam = Path()
  ..moveTo(-54, -5)
  ..lineTo(-48, -10)
  ..lineTo(59, -10)
  ..lineTo(54, -5)
  ..lineTo(54, 3)
  ..lineTo(-54, 3)
  ..close();

const _craneBoomOffset = 30.0;
const _craneRailY = 63 + _craneBoomOffset;
const _craneSteel = Color(0xFFFFB557);
const _windowLights = [
  Offset(399, 184),
  Offset(423, 203),
  Offset(447, 185),
  Offset(471, 205),
  Offset(423, 184),
  Offset(447, 204),
  Offset(471, 184),
];

void _craneStructure(Canvas g) {
  _festivalShade(
    g,
    _festTowerOutline,
    const Offset(513, 80),
    const Offset(541, 80),
    const [Color(0xFF7A4D2B), Color(0xFF423128), Color(0xFFBD7335)],
    const [0, .48, 1],
  );
  _stroke(g, _festTowerOutline, _craneSteel, .77, 1.4);
  for (var y = 68.0; y < 194; y += 17) {
    _line(g, 516, y, 539, y, _craneSteel, .59, .95);
    _line(g, 516, y, 539, y + 17, _craneSteel, .66, 1.2);
  }
  _stroke(g, _festCraneCables, _festGold, .58, .9);
  g.save();
  g.translate(0, _craneBoomOffset);
  _festivalShade(
    g,
    _festBoomOutline,
    const Offset(0, 48),
    const Offset(0, 61),
    const [Color(0xFF9D6231), Color(0xFF64452C), Color(0xFFB0783C)],
    const [0, .52, 1],
  );
  _stroke(g, _festBoomOutline, _festGold, .83, 1.3);
  for (var x = 320.0; x < 561; x += 14) {
    _line(g, x, 60, x + 7, 49, _festGold, .58, .9);
    _line(g, x + 7, 49, x + 14, 60, _festGold, .58, .9);
  }
  _festivalFill(g, _festCraneCab, const Color(0xFF64432A));
  _stroke(g, _festCraneCab, _festGold, .83);
  _festivalFill(g, _festCabGlass, const Color(0xFFAFD1CE), .75);
  g.drawRect(
    const Rect.fromLTWH(550, 61, 19, 12),
    Paint()..color = const Color(0xFFDA8E40),
  );
  g.drawRect(
    const Rect.fromLTWH(552, 67, 15, 4),
    Paint()..color = const Color(0xFF48352B),
  );
  g.restore();
}

void _labourBackdrop(Canvas g) {
  _glow(g, 419, 134, 236, const Color(0xFF5282B7), .4);
  _glow(g, 527, 163, 191, const Color(0xFFFC8F3F), .25);
  _festivalShade(
    g,
    _festWorksiteHorizon,
    const Offset(0, 165),
    const Offset(0, 245),
    const [Color(0xD42E435D), Color(0x121E2738)],
  );
  for (var i = 0; i < 4; i++) {
    final y = 105.0 + i * 28;
    _line(g, 244, y, 584, y, _festBlue, .091, .72);
  }
  for (var i = 0; i < 9; i++) {
    final x = 252.0 + i * 38;
    _line(g, x, 77, x, 216, _festBlue, .062, .72);
  }
  _festivalFill(g, _festBeamPlatform, const Color(0xFF545C68), .78);
  _stroke(g, _festBeamPlatform, const Color(0xFF9DABB0), .52);
  for (var i = 0; i < 6; i++) {
    _line(g, 273.0 + i * 13, 199, 280.0 + i * 13, 193, _festGold, .72, 1.3);
  }
  _festivalShade(
    g,
    _festFrameBack,
    const Offset(364, 149),
    const Offset(457, 217),
    const [Color(0xD1566880), Color(0xCF394559), Color(0x2E262E41)],
    const [0, .45, 1],
  );
  _festivalFill(g, _festFrameFront, const Color(0xFF232D3E), .87);
  _stroke(g, _festFrameBack, const Color(0xFF829DB0), .4, 1.1);
  for (final x in const [391.0, 415.0, 440.0, 465.0, 487.0]) {
    _line(g, x, 154, x, 226, const Color(0xFF7C96AC), .66, 2.2);
  }
  for (final y in const [162.0, 183.0, 205.0, 227.0]) {
    _line(g, 384, y, 493, y, const Color(0xFF9AACB9), .53, 1.8);
  }
  _craneStructure(g);
}

void _buildingWindows(Canvas g, double t, double reset) {
  final paint = Paint();
  for (final (i, window) in _windowLights.indexed) {
    final visible = holidaySmooth(8.18 + i * .31, 8.7 + i * .31, t) * reset;
    if (visible <= 0) continue;
    final x = window.dx, y = window.dy;
    _glow(g, x + 5, y - 9, 19, _festGold, .35 * visible);
    g.drawRect(
      Rect.fromLTWH(x, y - 14, 10, 9),
      paint..color = _a(_festGold, .84 * visible),
    );
    _line(
      g,
      x + 5,
      y - 14,
      x + 5,
      y - 5,
      const Color(0xFF7B4524),
      .45 * visible,
      .7,
    );
  }
}

void _steelBeam(Canvas g, double x, double y, double opacity) {
  if (opacity <= 0) return;
  g.save();
  g.translate(x, y);
  _festivalShade(
    g,
    _festSteelBeam,
    const Offset(-7, -10),
    const Offset(-5, 4),
    [
      _a(const Color(0xFFE4EADA), opacity),
      _a(const Color(0xFFAABFC8), opacity),
      _a(const Color(0xFF4D637A), opacity),
    ],
    const [0, .38, 1],
  );
  _stroke(g, _festSteelBeam, const Color(0xFFD1E1E5), .74 * opacity, .8);
  _line(g, -54, -5, 54, -5, _festCream, .74 * opacity, .8);
  for (final end in const [-52.0, 52.0]) {
    _line(g, end, -6, end, 3, _festGold, .85 * opacity, 1.5);
  }
  g.restore();
}

/// Hoist, traverse, seat the beam, then retract the hook as the windows light.
void _labourDay(Canvas g, double t) {
  const release = 8.1;
  final depart = holidaySmooth(2.85, 5.95, t);
  final turnBack = holidaySmooth(9.15, 12.05, t);
  final lifting = holidaySmooth(.68, 2.85, t);
  final lowering = holidaySmooth(6.15, release, t);
  final retract = holidaySmooth(release, 9.2, t);
  final trolley = holidayLerp(310, 438, depart - turnBack);
  final beamY = 184 - 56 * lifting + 24 * lowering;
  final hookY = beamY - 30 - 27 * retract + 59 * holidaySmooth(11.8, 13, t);
  final reset = 1 - holidaySmooth(11.4, 12.75, t);
  final highlight = holidayLabourLight(t);
  _glow(g, 527, 163, 191, const Color(0xFFFC8F3F), highlight);
  _buildingWindows(g, t, reset);

  final beacon = .55 + .35 * math.sin(_phase(t, 6));
  _glow(g, 527, 11, 15, _festVermilion, beacon * .62);
  _ellipse(g, 527, 11, 2.4, 2.4, _festCream, beacon);
  _line(
    g,
    trolley - 5,
    _craneRailY,
    trolley + 5,
    _craneRailY,
    _festCream,
    1,
    3.5,
  );
  _line(
    g,
    trolley,
    _craneRailY + 1,
    trolley,
    hookY,
    const Color(0xFFCADADD),
    .8,
  );
  g.save();
  g.translate(trolley, hookY);
  _stroke(g, _festLiftHook, _festGold, .98, 1.5);
  g.restore();

  if (t < release) {
    final sway = math.sin(_phase(t, 2)) * math.sin(math.pi * depart) * 4;
    _line(
      g,
      trolley + 3,
      hookY + 5,
      trolley - 35 + sway,
      beamY - 8,
      _festCream,
      .92,
      1.2,
    );
    _line(
      g,
      trolley + 3,
      hookY + 5,
      trolley + 37 + sway,
      beamY - 8,
      _festCream,
      .92,
      1.2,
    );
    _steelBeam(g, trolley + sway, beamY, 1);
  } else {
    _steelBeam(g, 438, 152, reset);
    _steelBeam(g, 310, 184, holidaySmooth(11.9, 12.9, t));
    final reattached = holidaySmooth(12.68, 13, t) * .92;
    _line(g, 313, hookY + 5, 275, 176, _festCream, reattached, 1.2);
    _line(g, 313, hookY + 5, 347, 176, _festCream, reattached, 1.2);
    for (final x in const [391.0, 487.0]) {
      _glow(g, x, 152, 31, _festGold, highlight * 3.8);
    }
  }
}
