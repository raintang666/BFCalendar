import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'holiday_calendar_data.dart';

/// Records code-drawn scenery once while the shared clock repaints motion only.
class HolidaySceneArtwork extends StatefulWidget {
  const HolidaySceneArtwork({
    super.key,
    required this.frames,
    required this.recordBackground,
    required this.paintMotion,
    this.glass = false,
    this.fadeToHeader = false,
  });

  final ValueListenable<HolidaySceneFrame> frames;
  final ui.Picture Function() recordBackground;
  final void Function(Canvas, double) paintMotion;

  /// Use the approved glass scene's 440px canvas and gradual fade.
  final bool glass;

  /// Finish the fade within the header when the scene is taller than its viewport.
  final bool fadeToHeader;

  @override
  State<HolidaySceneArtwork> createState() => _HolidaySceneArtworkState();
}

class _HolidaySceneArtworkState extends State<HolidaySceneArtwork> {
  late ui.Picture _background = widget.recordBackground();

  @override
  void didUpdateWidget(covariant HolidaySceneArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordBackground != widget.recordBackground) {
      _background.dispose();
      _background = widget.recordBackground();
    }
  }

  @override
  void dispose() {
    _background.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fadeToHeader) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _MotionPainter(
            widget.frames,
            widget.paintMotion,
            fadingBackground: _background,
          ),
          willChange: true,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (_) => ui.Gradient.linear(
          Offset.zero,
          Offset(0, (widget.glass ? 440 : 390) * constraints.maxWidth / 584),
          widget.glass
              ? const [
                  Colors.white,
                  Colors.white,
                  Color(0xC7FFFFFF),
                  Color(0x80FFFFFF),
                  Color(0x42FFFFFF),
                  Color(0x1AFFFFFF),
                  Color(0x08FFFFFF),
                  Color(0x00FFFFFF),
                ]
              : const [
                  Colors.white,
                  Colors.white,
                  Color(0xD1FFFFFF),
                  Color(0x3DFFFFFF),
                  Color(0x00FFFFFF),
                ],
          widget.glass
              ? const [0, .3, .42, .54, .66, .78, .9, 1]
              : const [0, .58, .75, .88, 1],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _BackgroundPainter(_background),
                isComplex: true,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _MotionPainter(widget.frames, widget.paintMotion),
                willChange: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter(this.picture);
  final ui.Picture picture;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 584);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.picture != picture;
}

class _MotionPainter extends CustomPainter {
  _MotionPainter(this.frames, this.draw, {this.fadingBackground})
    : super(repaint: frames);
  final ValueListenable<HolidaySceneFrame> frames;
  final void Function(Canvas, double) draw;
  final ui.Picture? fadingBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final background = fadingBackground;
    if (background != null) {
      // Apply the mask to the artwork without blending it into the card paint.
      canvas.saveLayer(bounds, Paint());
    }
    canvas.save();
    canvas.scale(size.width / 584);
    if (background != null) canvas.drawPicture(background);
    draw(canvas, frames.value.seconds);
    canvas.restore();
    if (background != null) {
      canvas.drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            const [
              Colors.white,
              Colors.white,
              Color(0xD9FFFFFF),
              Color(0xA1FFFFFF),
              Color(0x51FFFFFF),
              Color(0x00FFFFFF),
            ],
            const [0, .43, .61, .76, .87, 1],
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MotionPainter oldDelegate) =>
      oldDelegate.frames != frames ||
      oldDelegate.draw != draw ||
      oldDelegate.fadingBackground != fadingBackground;
}
