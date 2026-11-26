import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A day whose artwork has a fixed height and moves as a unit inside a taller
/// row. Only the calendar's own painters opt in. Other painters always receive
/// the actual cell size, including during a drag.
abstract class CalendarRetainedDayPainter extends CustomPainter {
  const CalendarRetainedDayPainter();

  /// Opt in when the row contains enough static artwork to benefit from
  /// rasterizing it once during a full-screen drag.
  bool get cacheStretchPixels => false;

  double contentHeight(double width);
  Alignment get contentAlignment;

  /// Height of any artwork anchored to the bottom edge, in logical pixels.
  double get footerHeight => 0;
  void paintFooter(Canvas canvas, Size size) {}

  void paintContent(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    paintContent(canvas, size);
    if (footerHeight > 0) paintFooter(canvas, size);
  }
}

/// At most one month's texture is kept per interactive calendar.
class CalendarStretchImageCache {
  Object? _owner;
  ui.Image? _image;

  bool get isEmpty => _image == null;
  ui.Image? imageFor(Object owner) => identical(owner, _owner) ? _image : null;

  void store(Object owner, ui.Image image) {
    clear();
    _owner = owner;
    _image = image;
  }

  void evict(Object owner) {
    if (identical(owner, _owner)) clear();
  }

  void clear() {
    _image?.dispose();
    _image = null;
    _owner = null;
  }
}

class CalendarStretchMotion extends InheritedWidget {
  const CalendarStretchMotion({
    super.key,
    required this.active,
    required this.images,
    this.maxMonthBodyHeight,
    required super.child,
  });

  final bool active;
  final CalendarStretchImageCache images;
  final double? maxMonthBodyHeight;

  static CalendarStretchMotion? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalendarStretchMotion>();

  @override
  bool updateShouldNotify(CalendarStretchMotion oldWidget) =>
      active != oldWidget.active ||
      images != oldWidget.images ||
      maxMonthBodyHeight != oldWidget.maxMonthBodyHeight;
}
