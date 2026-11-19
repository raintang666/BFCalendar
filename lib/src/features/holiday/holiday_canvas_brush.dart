// Shared native Canvas operations for the approved code-drawn solar scenes.
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HolidayCanvasBrush {
  HolidayCanvasBrush(this.canvas);
  final Canvas canvas;
  Object fillStyle = '#000000', strokeStyle = '#000000';
  num lineWidth = 1, globalAlpha = 1;
  String lineCap = 'butt', font = '17px serif', textAlign = 'left';
  Path _path = Path();
  bool _hasPoint = false;
  final _states =
      <
        ({
          Object fill,
          Object stroke,
          num width,
          num alpha,
          String cap,
          String font,
          String align,
        })
      >[];
  void save() {
    canvas.save();
    _states.add((
      fill: fillStyle,
      stroke: strokeStyle,
      width: lineWidth,
      alpha: globalAlpha,
      cap: lineCap,
      font: font,
      align: textAlign,
    ));
  }

  void restore() {
    canvas.restore();
    final s = _states.removeLast();
    fillStyle = s.fill;
    strokeStyle = s.stroke;
    lineWidth = s.width;
    globalAlpha = s.alpha;
    lineCap = s.cap;
    font = s.font;
    textAlign = s.align;
  }

  void translate(num x, num y) => canvas.translate(x.toDouble(), y.toDouble());
  void scale(num x, [num? y]) =>
      canvas.scale(x.toDouble(), (y ?? x).toDouble());
  void rotate(num a) => canvas.rotate(a.toDouble());
  void beginPath() {
    _path = Path();
    _hasPoint = false;
  }

  void moveTo(num x, num y) {
    _path.moveTo(x.toDouble(), y.toDouble());
    _hasPoint = true;
  }

  void lineTo(num x, num y) {
    _path.lineTo(x.toDouble(), y.toDouble());
    _hasPoint = true;
  }

  void closePath() => _path.close();
  void bezierCurveTo(num a, num b, num c, num d, num e, num f) {
    _path.cubicTo(
      a.toDouble(),
      b.toDouble(),
      c.toDouble(),
      d.toDouble(),
      e.toDouble(),
      f.toDouble(),
    );
    _hasPoint = true;
  }

  void quadraticCurveTo(num a, num b, num c, num d) {
    _path.quadraticBezierTo(
      a.toDouble(),
      b.toDouble(),
      c.toDouble(),
      d.toDouble(),
    );
    _hasPoint = true;
  }

  void arc(num x, num y, num r, num start, num end) {
    final rect = Rect.fromCircle(
      center: Offset(x.toDouble(), y.toDouble()),
      radius: r.toDouble(),
    );
    _path.arcTo(rect, start.toDouble(), (end - start).toDouble(), !_hasPoint);
    _hasPoint = true;
  }

  void ellipse(num x, num y, num rx, num ry, num angle, num start, num end) {
    final path = Path()
      ..addArc(
        Rect.fromLTRB(
          -rx.toDouble(),
          -ry.toDouble(),
          rx.toDouble(),
          ry.toDouble(),
        ),
        start.toDouble(),
        (end - start).toDouble(),
      );
    final cos = math.cos(angle), sin = math.sin(angle);
    _path.addPath(
      path,
      Offset(x.toDouble(), y.toDouble()),
      matrix4: Float64List.fromList([
        cos,
        sin,
        0,
        0,
        -sin,
        cos,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
    _hasPoint = true;
  }

  Paint _paint(Object style, {bool stroke = false}) {
    final paint = Paint()
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = lineWidth.toDouble()
      ..strokeCap = lineCap == 'round' ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;
    if (style is HolidayCanvasInk) {
      paint.shader = style.shader(globalAlpha);
    } else {
      final c = _parseColor(style as String);
      paint.color = c.withValues(
        alpha: c.a * globalAlpha.clamp(0.0, 1.0).toDouble(),
      );
    }
    return paint;
  }

  void fill() => canvas.drawPath(_path, _paint(fillStyle));
  void stroke() => canvas.drawPath(_path, _paint(strokeStyle, stroke: true));
  void clip() => canvas.clipPath(_path);
  void fillRect(num x, num y, num w, num h) => canvas.drawRect(
    Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
    _paint(fillStyle),
  );
  HolidayCanvasInk createLinearGradient(num x0, num y0, num x1, num y1) =>
      HolidayCanvasInk.linear(
        Offset(x0.toDouble(), y0.toDouble()),
        Offset(x1.toDouble(), y1.toDouble()),
      );
  HolidayCanvasInk createRadialGradient(
    num x0,
    num y0,
    num r0,
    num x1,
    num y1,
    num r1,
  ) => HolidayCanvasInk.radial(
    Offset(x1.toDouble(), y1.toDouble()),
    r1.toDouble(),
  );
  void fillText(String text, num x, num y) {
    final painter = _wineText;
    painter.paint(
      canvas,
      Offset(
        x.toDouble() - (textAlign == 'center' ? painter.width / 2 : 0),
        y.toDouble() -
            painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }
}

final _wineText = TextPainter(
  text: const TextSpan(
    text: '酒',
    style: TextStyle(fontSize: 17, color: Color(0xFF635F50)),
  ),
  textDirection: TextDirection.ltr,
)..layout();
final _hexColors = <String, Color>{};
Color _parseColor(String s) {
  if (s.startsWith('#')) {
    return _hexColors.putIfAbsent(s, () {
      var hex = s.substring(1);
      if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
      return Color(int.parse(hex, radix: 16) | 0xFF000000);
    });
  }
  final values = s
      .substring(s.indexOf('(') + 1, s.length - 1)
      .split(',')
      .map(double.parse)
      .toList();
  return Color.fromRGBO(
    values[0].round(),
    values[1].round(),
    values[2].round(),
    values.length > 3 ? values[3] : 1,
  );
}

class HolidayCanvasInk {
  HolidayCanvasInk.linear(this.start, this.end) : radius = null;
  HolidayCanvasInk.radial(this.start, this.radius) : end = Offset.zero;
  final Offset start, end;
  final double? radius;
  final colors = <Color>[], stops = <double>[];
  void addColorStop(num stop, String color) {
    stops.add(stop.toDouble());
    colors.add(_parseColor(color));
  }

  ui.Shader shader(num alpha) {
    final resolved = colors
        .map((c) => c.withValues(alpha: c.a * alpha.clamp(0.0, 1.0).toDouble()))
        .toList();
    return radius == null
        ? ui.Gradient.linear(start, end, resolved, stops)
        : ui.Gradient.radial(start, radius!, resolved, stops);
  }
}
