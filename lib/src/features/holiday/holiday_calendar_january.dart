import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';
import 'holiday_glass_scene.dart';
import 'holiday_scene_artwork.dart';

class HolidayJanuaryArtwork extends StatelessWidget {
  const HolidayJanuaryArtwork.xiaohan({super.key, required this.frames})
    : _background = _xiaohanBackground,
      _motion = _xiaohanMotion;

  const HolidayJanuaryArtwork.dahan({super.key, required this.frames})
    : _background = _dahanBackground,
      _motion = _dahanMotion;

  final ValueListenable<HolidaySceneFrame> frames;
  final ui.Picture Function() _background;
  final void Function(Canvas, double) _motion;

  static ui.Picture _xiaohanBackground() =>
      recordHolidayGlassBackdrop(HolidayScene.xiaohan);

  static ui.Picture _dahanBackground() =>
      recordHolidayGlassBackdrop(HolidayScene.dahan);

  static void _xiaohanMotion(Canvas canvas, double seconds) =>
      paintHolidayGlassMotion(canvas, HolidayScene.xiaohan, seconds);

  static void _dahanMotion(Canvas canvas, double seconds) =>
      paintHolidayGlassMotion(canvas, HolidayScene.dahan, seconds);

  @override
  Widget build(BuildContext context) => HolidaySceneArtwork(
    frames: frames,
    recordBackground: _background,
    paintMotion: _motion,
    glass: true,
    fadeToHeader: true,
  );
}
