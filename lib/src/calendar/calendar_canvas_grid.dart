import 'dart:math' as math;
import 'dart:ui' as ui;

// Preserve the calendar's date announcements in apps using Flutter's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, MaterialLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'calendar_components.dart';
import 'calendar_retained_day_painter.dart';

/// Date layout shared by Canvas painters and custom Widget cells.
class CalendarCanvasGrid extends StatefulWidget {
  const CalendarCanvasGrid({
    super.key,
    required this.cells,
    required this.painters,
    required this.dayWidgets,
    required this.rowHeight,
    required this.onDaySelected,
    this.markerTotals = const {},
    this.retainRowArtwork = false,
  });

  static const maxAnnouncedMarkers = 8;

  final bool retainRowArtwork;

  final List<CalendarDayCellData?> cells;
  final List<CustomPainter?> painters;
  final List<Widget?> dayWidgets;
  final double rowHeight;
  final ValueChanged<DateTime> onDaySelected;
  final Map<int, int> markerTotals;

  @override
  State<CalendarCanvasGrid> createState() => _CalendarCanvasGridState();
}

class _CalendarCanvasGridState extends State<CalendarCanvasGrid> {
  var _rows = <(int, int), _RowArtwork?>{};
  double? _width;
  TextDirection? _direction;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_invalidateFonts);
  }

  void _invalidateFonts() {
    if (_rows.isNotEmpty) setState(_clearArtwork);
  }

  void _clearArtwork() {
    for (final artwork in _rows.values) {
      artwork?.dispose();
    }
    _rows = {};
  }

  @override
  void dispose() {
    _clearArtwork();
    PaintingBinding.instance.systemFonts.removeListener(_invalidateFonts);
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarCanvasGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.painters != oldWidget.painters) {
      _clearArtwork();
    }
  }

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
      for (var index = 0; index < widget.dayWidgets.length; index++)
        if (widget.dayWidgets[index] != null) index,
    ];
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _GridLayout(
            width: constraints.maxWidth,
            rowHeight: widget.rowHeight,
            cellCount: widget.cells.length,
            direction: direction,
          );
          if (_width != layout.width || _direction != direction) {
            _clearArtwork();
            _width = layout.width;
            _direction = direction;
          }
          if (widgetIndices.isEmpty) {
            return _buildCanvas(
              layout,
              localizations,
              0,
              widget.cells.length,
              true,
            );
          }

          // Interleave consecutive painters and Widgets in date order. Custom
          // cells and painters can both paint outside their own rectangles.
          final layers = <Widget>[];
          var start = 0;
          var firstCanvas = true;
          for (final index in [...widgetIndices, widget.cells.length]) {
            if (widget.painters
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
            if (index == widget.cells.length) break;
            final cell = widget.cells[index]!;
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
                        : () => widget.onDaySelected(cell.date),
                    child: widget.dayWidgets[index],
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
    final first = widget.painters.getRange(start, end).nonNulls.firstOrNull;
    final canCachePixels =
        start == 0 &&
        end == widget.cells.length &&
        end > 7 &&
        first is CalendarRetainedDayPainter &&
        first.cacheStretchPixels &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        layout.width / 7 >= 42 &&
        MediaQuery.textScalerOf(context) == TextScaler.noScaling;
    final motion = canCachePixels
        ? CalendarStretchMotion.maybeOf(context)
        : null;
    final rows = widget.retainRowArtwork || motion != null ? _rows : null;
    if (rows == null) _rows.remove((start, end))?.dispose();
    final rasterScale = motion == null
        ? null
        : MediaQuery.devicePixelRatioOf(context);
    _rows[(start, end)]?.configureImage(motion?.images, rasterScale);
    return GestureDetector(
      // Individual date actions are supplied by the painter's semantics.
      excludeFromSemantics: true,
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (details) {
        final index = layout.indexAt(details.localPosition);
        if (index == null || index < start || index >= end) return;
        final cell = widget.cells[index];
        if (cell != null && !cell.isDisabled) widget.onDaySelected(cell.date);
      },
      child: CustomPaint(
        key: firstCanvas ? const ValueKey('calendar-canvas-grid') : null,
        painter: _CalendarGridPainter(
          rows: rows,
          rasterScale: rasterScale,
          motion: motion,
          cells: widget.cells,
          painters: widget.painters,
          start: start,
          end: end,
          layout: layout,
          localizations: localizations,
          onDaySelected: widget.onDaySelected,
          markerTotals: widget.markerTotals,
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

typedef _RowPicture = ({
  int row,
  double height,
  Alignment alignment,
  ui.Picture picture,
});

/// Vector artwork for one contiguous run of Canvas cells. During a stretch
/// only its row origins move. Custom Widgets and other painters keep their
/// original paint order, geometry and interaction.
class _RowArtwork {
  _RowArtwork(
    this.pictures,
    this.minimumHeight,
    this.width,
    this.cacheStretchPixels,
  );
  final double width;
  final bool cacheStretchPixels;
  double? _rasterScale;
  CalendarStretchImageCache? _cache;
  bool _warmScheduled = false;
  bool _tooLarge = false;
  List<Rect> _sources = const [];
  static final _imagePaint = Paint()..filterQuality = FilterQuality.none;
  final List<_RowPicture> pictures;
  final double minimumHeight;

  static _RowArtwork? create(
    List<CustomPainter?> painters,
    _GridLayout layout,
    int start,
    int end,
  ) {
    final run = painters.getRange(start, end).nonNulls;
    final first = run.firstOrNull;
    if (first is! CalendarRetainedDayPainter ||
        run.any(
          (day) =>
              day is! CalendarRetainedDayPainter ||
              day.contentAlignment != first.contentAlignment,
        )) {
      return null;
    }

    final pictures = <_RowPicture>[];
    final width = layout.width / 7;
    double minimumHeight = 0;
    for (var row = start ~/ 7; row * 7 < end; row++) {
      final from = math.max(start, row * 7);
      final to = math.min(end, (row + 1) * 7);
      final days = painters
          .getRange(from, to)
          .whereType<CalendarRetainedDayPainter>();
      if (days.isEmpty) continue;
      final height = days
          .map((day) => day.contentHeight(width))
          .reduce(math.max);
      final footer = days.map((day) => day.footerHeight).reduce(math.max);
      minimumHeight = math.max(minimumHeight, height + footer);

      void record(double extent, Alignment placement, {bool isFooter = false}) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final size = Size(width, extent);
        for (var i = from; i < to; i++) {
          final day = painters[i] as CalendarRetainedDayPainter?;
          if (day == null || (isFooter && day.footerHeight == 0)) continue;
          canvas.save();
          canvas.translate(layout.rectFor(i).left, 0);
          if (isFooter) {
            day.paintFooter(canvas, size);
          } else {
            day.paintContent(canvas, size);
          }
          canvas.restore();
        }
        pictures.add((
          row: row,
          height: extent,
          alignment: placement,
          picture: recorder.endRecording(),
        ));
      }

      record(height, first.contentAlignment);
      if (footer > 0) record(footer, Alignment.bottomCenter, isFooter: true);
    }
    return _RowArtwork(
      pictures,
      minimumHeight,
      layout.width,
      start == 0 &&
          end == painters.length &&
          run.cast<CalendarRetainedDayPainter>().every(
            (day) => day.cacheStretchPixels,
          ),
    );
  }

  void configureImage(CalendarStretchImageCache? cache, double? scale) {
    if (!cacheStretchPixels || (_cache == cache && _rasterScale == scale)) {
      return;
    }
    _cache?.evict(this);
    _cache = cache;
    _rasterScale = scale;
    _sources = const [];
    _tooLarge = false;
  }

  void _prepareImage(CalendarStretchImageCache cache, double scale) {
    // Build lazily in paint so neighboring PageView pages allocate no textures.
    // Cap pixel count on large displays (6 MiB for an RGBA8 texture).
    final physicalWidth = width * scale;
    final pixelWidth = physicalWidth.ceil();
    final sources = <Rect>[];
    var pixelHeight = 0;
    for (final layer in pictures) {
      final height = layer.height * scale;
      sources.add(
        Rect.fromLTWH(0, pixelHeight.toDouble(), physicalWidth, height),
      );
      pixelHeight += height.ceil() + 1;
    }
    _sources = sources;
    if (pixelWidth <= 0 ||
        pixelHeight <= 0 ||
        pixelWidth > 4096 ||
        pixelHeight > 4096 ||
        pixelWidth * pixelHeight > 1536 * 1024) {
      _tooLarge = true;
      return;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    var index = 0;
    for (final layer in pictures) {
      canvas.save();
      canvas.translate(0, sources[index++].top);
      canvas.scale(scale);
      canvas.drawPicture(layer.picture);
      canvas.restore();
    }
    final picture = recorder.endRecording();
    try {
      cache.store(this, picture.toImageSync(pixelWidth, pixelHeight));
    } finally {
      picture.dispose();
    }
  }

  void paint(Canvas canvas, double rowHeight, {required bool moving}) {
    double topOf(_RowPicture layer) =>
        layer.row * rowHeight +
        (rowHeight - layer.height) * (layer.alignment.y + 1) / 2;
    final cache = _cache;
    final scale = _rasterScale;
    if (cache != null && scale != null && !_tooLarge) {
      if (moving) {
        if (cache.imageFor(this) == null) _prepareImage(cache, scale);
        final image = cache.imageFor(this);
        if (image != null) {
          final transforms = [
            for (final layer in pictures)
              RSTransform(1 / scale, 0, 0, topOf(layer)),
          ];
          canvas.drawAtlas(
            image,
            transforms,
            _sources,
            null,
            null,
            null,
            _imagePaint,
          );
          return;
        }
      } else if (cache.isEmpty && !_warmScheduled) {
        // Paint the first visible frame as vectors. Prepare the next drag
        // afterwards, without allocating textures for neighboring pages.
        _warmScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _warmScheduled = false;
          if (_cache == cache && _rasterScale == scale && cache.isEmpty) {
            _prepareImage(cache, scale);
          }
        });
      }
    }
    for (final layer in pictures) {
      final top = topOf(layer);
      canvas.save();
      canvas.translate(0, top);
      canvas.drawPicture(layer.picture);
      canvas.restore();
    }
  }

  void dispose() {
    _cache?.evict(this);
    _cache = null;
    for (final layer in pictures) {
      layer.picture.dispose();
    }
  }
}

class _CalendarGridPainter extends CustomPainter {
  _CalendarGridPainter({
    required this.rows,
    required this.rasterScale,
    required this.motion,
    required this.cells,
    required this.painters,
    required this.start,
    required this.end,
    required this.layout,
    required this.localizations,
    required this.onDaySelected,
    required this.markerTotals,
  }) : super(repaint: Listenable.merge(painters.getRange(start, end)));

  final Map<(int, int), _RowArtwork?>? rows;
  final double? rasterScale;
  final CalendarStretchMotion? motion;
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
    // PageView also lays out neighboring months. Only record the rows of
    // pages that it actually paints, reusing them from the first visible frame.
    final artwork = rows?.putIfAbsent((
      start,
      end,
    ), () => _RowArtwork.create(painters, layout, start, end));
    if (artwork != null && layout.rowHeight >= artwork.minimumHeight) {
      artwork.configureImage(motion?.images, rasterScale);
      artwork.paint(canvas, layout.rowHeight, moving: motion?.active ?? false);
      return;
    }
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
    return oldDelegate.rows != rows ||
        oldDelegate.rasterScale != rasterScale ||
        oldDelegate.motion?.active != motion?.active ||
        oldDelegate.motion?.images != motion?.images ||
        oldDelegate.cells != cells ||
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
