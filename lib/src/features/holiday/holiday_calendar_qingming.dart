// Native Canvas port of the approved glass-calendar preview.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

ui.Picture _background() => recordHolidayGlassBackdrop(HolidayScene.qingming);
void _motion(Canvas canvas, double seconds) =>
    paintHolidayGlassMotion(canvas, HolidayScene.qingming, seconds);

class HolidayQingmingArtwork extends StatefulWidget {
  const HolidayQingmingArtwork({super.key, required this.frames});
  final ValueListenable<HolidaySceneFrame> frames;
  @override
  State<HolidayQingmingArtwork> createState() => _HolidayQingmingArtworkState();
}

class _HolidayQingmingArtworkState extends State<HolidayQingmingArtwork> {
  @override
  Widget build(BuildContext context) => HolidaySceneArtwork(
    frames: widget.frames,
    recordBackground: _background,
    paintMotion: _motion,
    glass: true,
  );
}

void paintHolidayQingmingDate(
  Canvas canvas,
  Offset center, {
  required double scale,
  required double seconds,
}) => paintHolidayGlassDate(
  canvas,
  HolidayScene.qingming,
  center,
  scale: scale,
  seconds: seconds,
);
