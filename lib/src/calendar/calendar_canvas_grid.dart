import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'calendar_components.dart';

/// Date layout shared by Canvas painters and custom Widget cells.
class CalendarCanvasGrid extends StatelessWidget {
  const CalendarCanvasGrid({
    super.key,
    required this.cells,
    required this.painters,
    required this.dayWidgets,
    required this.rowHeight,
    required this.onDaySelected,
    this.markerTotals = const {},
  });

  static const maxAnnouncedMarkers = 8;

  final List<CalendarDayCellData?> cells;
  final List<CustomPainter?> painters;
  final List<Widget?> dayWidgets;
  final double rowHeight;
  final ValueChanged<DateTime> onDaySelected;
  final Map<int, int> markerTotals;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final localizations =
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) ??
        const DefaultMaterialLocalizations();
    final widgetIndices = [
      for (var index = 0; index < dayWidgets.length; index++)
        if (dayWidgets[index] != null) index,
    ];
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _GridLayout(
            width: constraints.maxWidth,
            rowHeight: rowHeight,
            cellCount: cells.length,
            direction: direction,
          );
          if (widgetIndices.isEmpty) {
            return _buildCanvas(layout, localizations, 0, cells.length, true);
          }

          // Interleave consecutive painters and Widgets in date order. Custom
          // cells and painters can both paint outside their own rectangles.
          final layers = <Widget>[];
          var start = 0;
          var firstCanvas = true;
          for (final index in [...widgetIndices, cells.length]) {
            if (painters
                .getRange(start, index)
                .any((painter) => painter != null)) {
              layers.add(
                Positioned.fill(
                  key: ValueKey(start),
                  child: RepaintBoundary(
                    child: _buildCanvas(
                      layout,
                      localizations,
                      start,
                      index,
                      firstCanvas,
                    ),
                  ),
                ),
              );
              firstCanvas = false;
            }
            if (index == cells.length) break;
            final cell = cells[index]!;
            layers.add(
              Positioned.fromRect(
                key: ValueKey(cell.date),
                rect: layout.rectFor(index),
                child: Semantics(
                  container: true,
                  sortKey: OrdinalSortKey(index.toDouble()),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: cell.isDisabled
                        ? null
                        : () => onDaySelected(cell.date),
                    child: dayWidgets[index],
                  ),
                ),
              ),
            );
            start = index + 1;
          }
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: layers,
          );
        },
      ),
    );
  }

  Widget _buildCanvas(
    _GridLayout layout,
    MaterialLocalizations localizations,
    int start,
    int end,
    bool firstCanvas,
  ) {
    return GestureDetector(
      // Individual date actions are supplied by the painter's semantics.
      excludeFromSemantics: true,
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (details) {
        final index = layout.indexAt(details.localPosition);
        if (index == null || index < start || index >= end) return;
        final cell = cells[index];
        if (cell != null && !cell.isDisabled) onDaySelected(cell.date);
      },
      child: CustomPaint(
        key: firstCanvas ? const ValueKey('calendar-canvas-grid') : null,
        painter: _CalendarGridPainter(
          cells: cells,
          painters: painters,
          start: start,
          end: end,
          layout: layout,
          localizations: localizations,
          onDaySelected: onDaySelected,
          markerTotals: markerTotals,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GridLayout {
  const _GridLayout({
    required this.width,
    required this.rowHeight,
    required this.cellCount,
    required this.direction,
  });

  final double width;
  final double rowHeight;
  final int cellCount;
  final TextDirection direction;

  Rect rectFor(int index) {
    final column = direction == TextDirection.rtl ? 6 - index % 7 : index % 7;
    final cellWidth = width / 7;
    return Rect.fromLTWH(
      column * cellWidth,
      (index ~/ 7) * rowHeight,
      cellWidth,
      rowHeight,
    );
  }

  int? indexAt(Offset position) {
    if (width <= 0 ||
        rowHeight <= 0 ||
        position.dx < 0 ||
        position.dx >= width ||
        position.dy < 0 ||
        position.dy >= (cellCount ~/ 7) * rowHeight) {
      return null;
    }
    final visualColumn = (position.dx / (width / 7)).floor().clamp(0, 6);
    final column = direction == TextDirection.rtl
        ? 6 - visualColumn
        : visualColumn;
    return (position.dy / rowHeight).floor() * 7 + column;
  }
}

class _CalendarGridPainter extends CustomPainter {
  _CalendarGridPainter({
    required this.cells,
    required this.painters,
    required this.start,
    required this.end,
    required this.layout,
    required this.localizations,
    required this.onDaySelected,
    required this.markerTotals,
  }) : super(repaint: Listenable.merge(painters.getRange(start, end)));

  final List<CalendarDayCellData?> cells;
  final List<CustomPainter?> painters;
  final int start;
  final int end;
  final _GridLayout layout;
  final MaterialLocalizations localizations;
  final ValueChanged<DateTime> onDaySelected;
  final Map<int, int> markerTotals;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = start; index < end; index++) {
      final painter = painters[index];
      if (painter == null) continue;
      final rect = layout.rectFor(index);
      canvas.save();
      canvas.translate(rect.left, rect.top);
      painter.paint(canvas, rect.size);
      canvas.restore();
    }
  }

  @override
  bool hitTest(Offset position) {
    final index = layout.indexAt(position);
    return index != null &&
        index >= start &&
        index < end &&
        painters[index] != null;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    return [
      for (var index = start; index < end; index++)
        if (cells[index] case final cell?)
          CustomPainterSemantics(
            key: ValueKey(cell.date),
            rect: layout.rectFor(index),
            properties: SemanticsProperties(
              label: localizations.formatFullDate(cell.date),
              value: _semanticsValue(cell, markerTotals[index]),
              textDirection: layout.direction,
              sortKey: OrdinalSortKey(index.toDouble()),
              button: true,
              enabled: !cell.isDisabled,
              selected: cell.isSelected,
              onTap: cell.isDisabled ? null : () => onDaySelected(cell.date),
            ),
          ),
    ];
  };

  String _semanticsValue(CalendarDayCellData cell, int? total) {
    const maxMarkers = CalendarCanvasGrid.maxAnnouncedMarkers;
    const maxLabelLength = 128;
    final labels = [if (cell.lunarText.isNotEmpty) cell.lunarText];
    final markers = cell.markers;
    final count = markers.length;
    for (var i = 0; i < count && i < maxMarkers; i++) {
      final label = markers[i].label;
      if (label.isEmpty) continue;
      if (label.length <= maxLabelLength) {
        labels.add(label);
      } else {
        final prefix = String.fromCharCodes(label.runes.take(maxLabelLength));
        labels.add(prefix.length == label.length ? label : '$prefix…');
      }
    }
    final remaining = (total ?? count) - maxMarkers;
    if (remaining > 0) {
      labels.add('+${localizations.formatDecimal(remaining)}');
    }
    return labels.join(', ');
  }

  @override
  bool shouldRepaint(covariant _CalendarGridPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.painters != painters ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.layout.width != layout.width ||
        oldDelegate.layout.rowHeight != layout.rowHeight ||
        oldDelegate.layout.direction != layout.direction;
  }

  @override
  bool shouldRebuildSemantics(covariant _CalendarGridPainter oldDelegate) {
    return shouldRepaint(oldDelegate) ||
        oldDelegate.markerTotals != markerTotals ||
        oldDelegate.localizations != localizations ||
        oldDelegate.onDaySelected != onDaySelected;
  }
}
