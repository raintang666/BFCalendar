// Native Canvas port of the approved glass-calendar preview.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

ui.Picture _background() => recordHolidayGlassBackdrop(HolidayScene.xiaoshu);
void _motion(Canvas canvas, double seconds) =>
    paintHolidayGlassMotion(canvas, HolidayScene.xiaoshu, seconds);

class HolidayXiaoshuArtwork extends StatelessWidget {
  const HolidayXiaoshuArtwork({super.key, required this.frames});
  final ValueListenable<HolidaySceneFrame> frames;
  @override
  Widget build(BuildContext context) => HolidaySceneArtwork(
    frames: frames,
    recordBackground: _background,
    paintMotion: _motion,
    glass: true,
  );
}

void paintHolidayXiaoshuDate(
  Canvas canvas,
  Offset center, {
  required double scale,
  required double seconds,
}) => paintHolidayGlassDate(
  canvas,
  HolidayScene.xiaoshu,
  center,
  scale: scale,
  seconds: seconds,
);
