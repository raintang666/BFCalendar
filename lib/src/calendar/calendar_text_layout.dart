import 'dart:math' as math;

import 'package:flutter/widgets.dart';

typedef _TextLayoutKey = (
  InlineSpan,
  TextDirection,
  TextScaler,
  Locale?,
  int?,
  String?,
  double,
);

/// Shared, bounded paragraph layouts for the built-in calendar painters.
/// Callers paint the returned layout immediately and must not mutate/dispose it.
class CalendarTextLayout {
  CalendarTextLayout._();

  static const _capacity = 256;
  static final _layouts = <_TextLayoutKey, TextPainter>{};
  static bool _listeningForFonts = false;

  static TextPainter layout({
    required InlineSpan text,
    required TextDirection textDirection,
    TextScaler textScaler = TextScaler.noScaling,
    Locale? locale,
    int? maxLines,
    String? ellipsis,
    double maxWidth = double.infinity,
  }) {
    if (!_listeningForFonts) {
      PaintingBinding.instance.systemFonts.addListener(_clear);
      _listeningForFonts = true;
    }
    final key = (
      text,
      textDirection,
      textScaler,
      locale,
      maxLines,
      ellipsis,
      maxWidth,
    );
    final cached = _layouts.remove(key);
    if (cached != null) {
      _layouts[key] = cached;
      return cached;
    }
    final painter = TextPainter(
      text: text,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      maxLines: maxLines,
      ellipsis: ellipsis,
    )..layout(maxWidth: maxWidth);
    if (_layouts.length == _capacity) {
      _layouts.remove(_layouts.keys.first)!.dispose();
    }
    _layouts[key] = painter;
    return painter;
  }

  static void _clear() {
    for (final painter in _layouts.values) {
      painter.dispose();
    }
    _layouts.clear();
  }
}

/// Resolves the ambient typography used by the built-in calendar painters.
class CalendarCanvasText {
  CalendarCanvasText.of(BuildContext context)
    : _defaultStyle = DefaultTextStyle.of(context).style,
      _bold = MediaQuery.boldTextOf(context),
      _scaler = MediaQuery.textScalerOf(context),
      direction = Directionality.of(context),
      _locale = Localizations.maybeLocaleOf(context);

  final TextStyle _defaultStyle;
  final bool _bold;
  final TextScaler _scaler;
  final TextDirection direction;
  final Locale? _locale;

  TextPainter layout(
    String label,
    TextStyle style,
    double width, {
    int? maxLines,
  }) {
    return CalendarTextLayout.layout(
      text: TextSpan(
        text: label,
        style: _defaultStyle
            .merge(style)
            .copyWith(fontWeight: _bold ? FontWeight.bold : null),
      ),
      textDirection: direction,
      textScaler: _scaler,
      locale: _locale,
      maxLines: maxLines,
      maxWidth: width.clamp(0.0, double.infinity),
    );
  }

  void paint(
    Canvas canvas,
    String label,
    TextStyle style,
    Rect bounds, {
    Alignment alignment = Alignment.center,
    int? maxLines,
  }) {
    if (bounds.isEmpty) return;
    final text = layout(label, style, bounds.width, maxLines: maxLines);
    final clip = text.width > bounds.width || text.height > bounds.height;
    if (clip) {
      canvas.save();
      canvas.clipRect(bounds);
    }
    text.paint(
      canvas,
      bounds.topLeft +
          alignment.alongOffset(
            Offset(
              bounds.width - text.width,
              (bounds.height - text.height).clamp(0, double.infinity),
            ),
          ),
    );
    if (clip) canvas.restore();
  }

  void paintDayAndLunar(
    Canvas canvas,
    Rect bounds, {
    required String day,
    required TextStyle dayStyle,
    required String lunar,
    required TextStyle lunarStyle,
    required double gap,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    if (bounds.isEmpty) return;
    final dayLine = layout(day, dayStyle, bounds.width);
    final lunarLine = layout(lunar, lunarStyle, bounds.width, maxLines: 1);
    final blockWidth = math.max(dayLine.width, lunarLine.width);
    final centerX =
        bounds.left +
        alignment
            .resolve(direction)
            .alongOffset(Offset(bounds.width - blockWidth, 0))
            .dx +
        blockWidth / 2;
    final top =
        bounds.top +
        ((bounds.height - dayLine.height - gap - lunarLine.height) / 2).clamp(
          0,
          double.infinity,
        );
    dayLine.paint(canvas, Offset(centerX - dayLine.width / 2, top));
    lunarLine.paint(
      canvas,
      Offset(centerX - lunarLine.width / 2, top + dayLine.height + gap),
    );
  }
}
