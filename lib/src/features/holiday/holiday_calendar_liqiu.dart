// Native Canvas port of the approved glass-calendar preview.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

ui.Picture _background() => recordHolidayGlassBackdrop(HolidayScene.liqiu);
void _motion(Canvas canvas, double seconds) =>
    paintHolidayGlassMotion(canvas, HolidayScene.liqiu, seconds);

class HolidayLiqiuArtwork extends StatelessWidget {
  const HolidayLiqiuArtwork({super.key, required this.frames});
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

void paintHolidayLiqiuDate(
  Canvas canvas,
  Offset center, {
  required double scale,
  required double seconds,
}) => paintHolidayGlassDate(
  canvas,
  HolidayScene.liqiu,
  center,
  scale: scale,
  seconds: seconds,
);
