import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

ui.Picture _background() => recordHolidayGlassBackdrop(HolidayScene.lidong);

void _motion(Canvas canvas, double seconds) =>
    paintHolidayGlassMotion(canvas, HolidayScene.lidong, seconds);

class HolidayLidongArtwork extends StatelessWidget {
  const HolidayLidongArtwork({super.key, required this.frames});
  final ValueListenable<HolidaySceneFrame> frames;

  @override
  Widget build(BuildContext context) => HolidaySceneArtwork(
    frames: frames,
    recordBackground: _background,
    paintMotion: _motion,
    glass: true,
    fadeToHeader: true,
  );
}
