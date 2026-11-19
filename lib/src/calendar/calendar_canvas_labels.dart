import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'calendar_text_layout.dart';

/// A label that can paint on its own or share the weekday bar's Canvas.
class CalendarCanvasLabel extends StatelessWidget {
  const CalendarCanvasLabel(
    this.text, {
    super.key,
    required this.style,
    this.alignment = Alignment.center,
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final typography = CalendarCanvasText.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final paragraph = typography.layout(text, style, constraints.maxWidth);
        return SizedBox(
          width: paragraph.width,
          height: paragraph.height,
          child: CalendarCanvasLabels(labels: [this]),
        );
      },
    );
  }
}

/// Draws a row of equal-width weekday or month-title slots.
class CalendarCanvasLabels extends StatelessWidget {
  const CalendarCanvasLabels({
    super.key,
    required this.labels,
    this.padding = EdgeInsets.zero,
    this.background = const Color(0x00000000),
    this.bottomDivider,
  });

  final List<CalendarCanvasLabel?> labels;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color? bottomDivider;

  @override
  Widget build(BuildContext context) {
    final text = CalendarCanvasText.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CalendarLabelsPainter(
          labels: labels,
          padding: padding.resolve(text.direction),
          background: background,
          bottomDivider: bottomDivider,
          text: text,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CalendarLabelsPainter extends CustomPainter {
  const _CalendarLabelsPainter({
    required this.labels,
    required this.padding,
    required this.background,
    required this.bottomDivider,
    required this.text,
  });

  final List<CalendarCanvasLabel?> labels;
  final EdgeInsets padding;
  final Color background;
  final Color? bottomDivider;
  final CalendarCanvasText text;

  Rect _labelBounds(Size size, int index) {
    final content = padding.deflateRect(Offset.zero & size);
    final width = (content.width / labels.length).clamp(0.0, double.infinity);
    final column = text.direction == TextDirection.rtl
        ? labels.length - 1 - index
        : index;
    return Rect.fromLTWH(
      content.left + column * width,
      content.top,
      width,
      content.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    if (background.a > 0) {
      canvas.drawRect(bounds, Paint()..color = background);
    }
    for (var index = 0; index < labels.length; index++) {
      final label = labels[index];
      if (label == null) continue;
      text.paint(
        canvas,
        label.text,
        label.style,
        _labelBounds(size, index),
        alignment: label.alignment,
      );
    }
    if (bottomDivider case final color?) {
      final content = padding.deflateRect(bounds);
      final divider = Rect.fromLTWH(
        content.left,
        content.bottom - 2.5,
        content.width,
        0.5,
      );
      canvas.drawRect(divider.intersect(bounds), Paint()..color = color);
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        if (!size.isEmpty)
          for (var index = 0; index < labels.length; index++)
            if (labels[index] case final label?)
              CustomPainterSemantics(
                key: ValueKey(index),
                rect: _labelBounds(size, index),
                properties: SemanticsProperties(
                  label: label.text,
                  textDirection: text.direction,
                  sortKey: OrdinalSortKey(index.toDouble()),
                ),
              ),
      ];

  @override
  bool shouldRepaint(covariant _CalendarLabelsPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.padding != padding ||
      oldDelegate.background != background ||
      oldDelegate.bottomDivider != bottomDivider ||
      oldDelegate.text != text;
}
