import 'dart:collection';
import 'dart:ui' as ui;

import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:calendarview_flutter/src/calendar/calendar_retained_day_painter.dart';
import 'package:calendarview_flutter/src/features/calendar_demo/demo_calendar_components.dart';
import 'package:calendarview_flutter/src/features/colorful/colorful_calendar_components.dart';
import 'package:calendarview_flutter/src/features/index/index_calendar_components.dart';
import 'package:calendarview_flutter/src/features/multi_select/multi_select_calendar_components.dart';
import 'package:calendarview_flutter/src/features/progress/progress_calendar_components.dart';
import 'package:calendarview_flutter/src/features/range/range_calendar_components.dart';
import 'package:calendarview_flutter/src/features/single_select/single_select_calendar_components.dart';
import 'package:calendarview_flutter/src/features/solar/solar_calendar_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _surfaceKey = ValueKey('calendar-canvas-grid');

CalendarController _controller() => CalendarController(
  focusedDay: DateTime(2026, 7, 9),
  minDate: DateTime(2026, 7, 1),
  maxDate: DateTime(2026, 7, 31),
)..setInterceptBlocked(false);

Future<void> _pumpCalendar(
  WidgetTester tester,
  CalendarController controller, {
  CalendarComponentBuilder? builder,
  ValueChanged<DateTime>? onDaySelected,
  CalendarRangeLimitViolationCallback? onRangeLimit,
  CalendarMultiSelectOutOfSizeCallback? onMultiLimit,
  CalendarRangeSelectedCallback? onRangeSelected,
  CalendarMultiSelectedCallback? onMultiSelected,
  TextDirection direction = TextDirection.ltr,
  double? collapseProgress,
  double? bodyHeight,
  double textScale = 1,
  double width = 390,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: direction,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: CalendarView(
                  controller: controller,
                  componentBuilder: builder,
                  pageOrientation: CalendarPageOrientation.horizontal,
                  handleDaySelection: true,
                  onDaySelected: onDaySelected ?? (_) {},
                  onSelectOutOfRange: onRangeLimit,
                  onMultiSelectOutOfSize: onMultiLimit,
                  onRangeSelected: onRangeSelected,
                  onMultiSelected: onMultiSelected,
                  collapsePreviewProgress: collapseProgress,
                  monthBodyHeightOverride: bodyHeight,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Offset _cellCenter(WidgetTester tester, int index, {double rowHeight = 62}) {
  final rect = tester.getRect(find.byKey(_surfaceKey).first);
  return rect.topLeft +
      Offset((index % 7 + .5) * rect.width / 7, (index ~/ 7 + .5) * rowHeight);
}

void main() {
  testWidgets('existing default builder overrides survive Canvas style swaps', (
    tester,
  ) async {
    final controller = _controller();
    await _pumpCalendar(tester, controller, builder: const _OverrideBuilder());
    expect(find.text('CUSTOM-9'), findsOneWidget);
    expect(find.byKey(_surfaceKey), findsOneWidget);
    expect(find.text('8'), findsNothing);

    await _pumpCalendar(tester, controller);
    expect(find.text('CUSTOM-9'), findsNothing);
    expect(find.byKey(_surfaceKey), findsOneWidget);

    await _pumpCalendar(tester, controller, builder: const _OverrideBuilder());
    expect(find.text('CUSTOM-9'), findsOneWidget);
  });

  testWidgets('a custom date keeps its own action alongside Canvas dates', (
    tester,
  ) async {
    final controller = _controller()..setDisplayMode(CalendarDisplayMode.week);
    final selected = <DateTime>[];
    var badgeTaps = 0;
    await _pumpCalendar(
      tester,
      controller,
      builder: _BadgeBuilder(() => badgeTaps++),
      direction: TextDirection.rtl,
      onDaySelected: selected.add,
    );

    expect(find.byKey(_surfaceKey), findsOneWidget);
    expect(find.semantics.byLabel('Open event'), findsOne);
    await tester.tap(find.text('Open event'));
    expect(badgeTaps, 1);
    expect(selected, isEmpty);

    final customCell = find.byKey(ValueKey(DateTime(2026, 7, 9)));
    await tester.tapAt(tester.getTopLeft(customCell) + const Offset(4, 4));
    await tester.pump();
    expect(selected, [DateTime(2026, 7, 9)]);

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(CalendarView)),
    );
    final friday = localizations.formatFullDate(DateTime(2026, 7, 10));
    tester.semantics.tap(find.semantics.byLabel(friday));
    await tester.pump();
    await tester.tapAt(_cellCenter(tester, 3)); // July 8 in RTL.
    await tester.pump();
    expect(selected, [
      DateTime(2026, 7, 9),
      DateTime(2026, 7, 10),
      DateTime(2026, 7, 8),
    ]);
  });

  testWidgets('one Canvas handles date taps, hidden cells and padding', (
    tester,
  ) async {
    final controller = _controller();
    final selected = <DateTime>[];
    await _pumpCalendar(tester, controller, onDaySelected: selected.add);

    expect(find.byKey(_surfaceKey), findsOneWidget);
    expect(find.text('9'), findsNothing);
    await tester.tapAt(_cellCenter(tester, 0)); // Hidden June 28.
    final rect = tester.getRect(find.byKey(_surfaceKey));
    await tester.tapAt(Offset(rect.left - 5, rect.top + 31));
    expect(selected, isEmpty);
    await tester.tapAt(_cellCenter(tester, 11)); // July 9.
    await tester.pump();
    expect(selected, [DateTime(2026, 7, 9)]);
    expect(controller.selection.single, DateTime(2026, 7, 9));
  });

  testWidgets('disabled and out of bounds dates have no tap action', (
    tester,
  ) async {
    final controller = _controller()
      ..setMonthViewShowMode(MonthViewShowMode.allMonth)
      ..setDisabledDatePredicate((date) => date.day == 9);
    final selected = <DateTime>[];
    await _pumpCalendar(tester, controller, onDaySelected: selected.add);
    await tester.tapAt(_cellCenter(tester, 0)); // Before minDate.
    await tester.tapAt(_cellCenter(tester, 11)); // Disabled July 9.
    await tester.tapAt(_cellCenter(tester, 34)); // After maxDate.
    expect(selected, isEmpty);
    await tester.tapAt(_cellCenter(tester, 12));
    expect(selected, [DateTime(2026, 7, 10)]);
  });

  testWidgets('RTL and Monday week start share painting and hit coordinates', (
    tester,
  ) async {
    final controller = _controller()..setWeekStart(DateTime.monday);
    final selected = <DateTime>[];
    await _pumpCalendar(
      tester,
      controller,
      direction: TextDirection.rtl,
      onDaySelected: selected.add,
    );
    // July 1 is logical column 2, visual column 4.
    await tester.tapAt(_cellCenter(tester, 4));
    expect(selected, [DateTime(2026, 7, 1)]);
  });

  testWidgets('week mode maps a single row to its actual dates', (
    tester,
  ) async {
    final controller = _controller()..setDisplayMode(CalendarDisplayMode.week);
    final selected = <DateTime>[];
    await _pumpCalendar(tester, controller, onDaySelected: selected.add);
    expect(tester.getSize(find.byKey(_surfaceKey)).height, 62);
    await tester.tapAt(_cellCenter(tester, 5));
    expect(selected, [DateTime(2026, 7, 10)]);
  });

  testWidgets(
    'collapsed month hit testing follows the translated selected row',
    (tester) async {
      final controller = _controller();
      final selected = <DateTime>[];
      await _pumpCalendar(
        tester,
        controller,
        collapseProgress: 1,
        onDaySelected: selected.add,
      );
      // The selected week is translated to the top of the visible body.
      final calendar = tester.getRect(find.byType(CalendarView));
      final surface = tester.getRect(find.byKey(_surfaceKey));
      await tester.tapAt(
        Offset(
          surface.left + surface.width * 5.5 / 7,
          calendar.top + 60 + 46 + 31,
        ),
      );
      expect(selected, [DateTime(2026, 7, 10)]);
    },
  );

  testWidgets(
    'custom painter receives stretched size and live repaint signals',
    (tester) async {
      final controller = _controller();
      final signal = ValueNotifier(0);
      addTearDown(signal.dispose);
      final sizes = <Size>[];
      final builder = _LiveCellBuilder(signal, sizes.add);
      await _pumpCalendar(
        tester,
        controller,
        builder: builder,
        bodyHeight: 400,
      );
      expect(sizes.last.height, 80);
      await _pumpCalendar(
        tester,
        controller,
        builder: builder,
        bodyHeight: 450,
      );
      expect(sizes.last.height, 90);
      sizes.clear();
      signal.value++;
      await tester.pump();
      expect(sizes.single.height, 90);
    },
  );

  testWidgets('stretched month uses its displayed row height for taps', (
    tester,
  ) async {
    final controller = _controller();
    final selected = <DateTime>[];
    await _pumpCalendar(
      tester,
      controller,
      bodyHeight: 400,
      onDaySelected: selected.add,
    );
    await tester.tapAt(_cellCenter(tester, 25, rowHeight: 80));
    expect(selected, [DateTime(2026, 7, 23)]);
  });

  testWidgets('multi select keeps success and limit callbacks', (tester) async {
    final controller = _controller()
      ..setSelectionMode(CalendarSelectionMode.multi)
      ..setMaxMultiSelectSize(1);
    final limits = <DateTime>[];
    final sizes = <int>[];
    await _pumpCalendar(
      tester,
      controller,
      onMultiLimit: (day, max) => limits.add(day),
      onMultiSelected: (day, size, max) => sizes.add(size),
    );
    await tester.tapAt(_cellCenter(tester, 11));
    await tester.pumpAndSettle();
    await tester.tapAt(_cellCenter(tester, 12));
    await tester.pumpAndSettle();
    expect(controller.selectedMultiDates, [DateTime(2026, 7, 9)]);
    expect(limits, [DateTime(2026, 7, 10)]);
    await tester.tapAt(_cellCenter(tester, 11));
    await tester.pumpAndSettle();
    expect(controller.selectedMultiDates, isEmpty);
    expect(sizes, [1, 0]);
  });

  testWidgets('range selection keeps success and limit callbacks', (
    tester,
  ) async {
    final controller = _controller()
      ..setSelectionMode(CalendarSelectionMode.range);
    controller.setRangeSelectionLimits(minRange: 2, maxRange: 4);
    final violations = <CalendarRangeLimitViolation>[];
    final ranges = <DateRangeValue>[];
    await _pumpCalendar(
      tester,
      controller,
      onRangeLimit: (day, violation) => violations.add(violation),
      onRangeSelected: ranges.add,
    );
    await tester.tapAt(_cellCenter(tester, 11));
    await tester.pumpAndSettle();
    await tester.tapAt(_cellCenter(tester, 18)); // July 16, too far.
    await tester.pumpAndSettle();
    expect(violations, [CalendarRangeLimitViolation.aboveMaxRange]);
    await tester.tapAt(_cellCenter(tester, 13));
    await tester.pumpAndSettle();
    expect(controller.rangeSelection.start, DateTime(2026, 7, 9));
    expect(controller.rangeSelection.end, DateTime(2026, 7, 11));
    expect(ranges.last.isComplete, isTrue);
  });

  testWidgets(
    'Canvas exposes selected, disabled and actionable date semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = _controller()
        ..setDisabledDatePredicate((day) => day.day == 10);
      await _pumpCalendar(tester, controller);
      final paint = tester.widget<CustomPaint>(find.byKey(_surfaceKey));
      final entries = paint.painter!.semanticsBuilder!(
        tester.getSize(find.byKey(_surfaceKey)),
      );
      final selected = entries.firstWhere(
        (entry) => entry.key == ValueKey(DateTime(2026, 7, 9)),
      );
      final disabled = entries.firstWhere(
        (entry) => entry.key == ValueKey(DateTime(2026, 7, 10)),
      );
      expect(selected.properties.selected, isTrue);
      expect(disabled.properties.enabled, isFalse);
      expect(disabled.properties.onTap, isNull);
      final target = entries.firstWhere(
        (entry) => entry.key == ValueKey(DateTime(2026, 7, 11)),
      );
      tester.semantics.tap(find.semantics.byLabel(target.properties.label!));
      await tester.pumpAndSettle();
      expect(controller.selection.single, DateTime(2026, 7, 11));
      semantics.dispose();
    },
  );

  testWidgets('default Canvas bounds its snapshot of a dense marker day', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final day = DateTime(2026, 7, 9);
    final prefix = List.filled(128, '😀').join();
    final list = _DenseMarkers(
      CalendarMarker(label: '${prefix}more', color: Colors.red),
    );
    final controller = _controller()..setMarkers({day: list});
    addTearDown(controller.dispose);
    await _pumpCalendar(tester, controller);

    final paint = tester.widget<CustomPaint>(find.byKey(_surfaceKey));
    final entry = paint
        .painter!
        .semanticsBuilder!(tester.getSize(find.byKey(_surfaceKey)))
        .singleWhere((entry) => entry.key == ValueKey(day));
    expect(entry.properties.value, contains('$prefix…'));
    expect(entry.properties.value, endsWith('marker 7, +9,999,992'));
    expect(list.reads, lessThan(64));
    expect(controller.markers[day], same(list));
    expect(controller.markers[day]!.length, 10000000);
    semantics.dispose();
  });

  testWidgets('custom date builders retain full marker snapshots', (
    tester,
  ) async {
    final day = DateTime(2026, 7, 9);
    final payload = Object();
    final marker = CalendarMarker(
      label: 'before',
      color: Colors.red,
      data: payload,
    );
    final list = List.filled(20, marker);
    final controller = _controller()..setMarkers({day: list});
    addTearDown(controller.dispose);
    final builder = _MarkerCapture(day);
    await _pumpCalendar(tester, controller, builder: builder);

    expect(builder.markers.length, 20);
    expect(builder.markers.first.data, same(payload));
    expect(builder.markers.last, same(marker));
    expect(() => builder.markers.clear(), throwsUnsupportedError);
    list[0] = const CalendarMarker(label: 'new', color: Colors.blue);
    expect(builder.markers.first, same(marker));
    controller.setMarkers({day: list});
    await tester.pumpAndSettle();
    expect(builder.markers.first.label, 'new');
  });

  testWidgets('marker indexes reach custom builders without copying', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final day = DateTime(2026, 7, 9);
    final payload = Object();
    final list = _DenseMarkers(
      CalendarMarker(label: 'event', color: Colors.blue, data: payload),
    );
    final backing = _MarkerLookup(day, list);
    final index = CalendarMarkerIndex(backing);
    final initialized = CalendarController(markers: index);
    addTearDown(initialized.dispose);
    expect(initialized.markers, same(index));

    final controller = _controller()..setMarkers(index);
    addTearDown(controller.dispose);
    final builder = _MarkerCapture(day);
    await _pumpCalendar(tester, controller, builder: builder);
    expect(controller.markers, same(index));
    expect(backing.keyReads, 0);
    expect(list.reads, lessThan(64));
    expect(builder.markers.length, 10000000);
    expect(builder.markers.first.data, same(payload));
    expect(builder.markers.last.label, 'marker 9999999');
    expect(() => builder.markers.clear(), throwsUnsupportedError);
    expect(() => controller.markers.clear(), throwsUnsupportedError);

    final latest = CalendarMarkerIndex({
      day: const [CalendarMarker(label: 'new', color: Colors.blue)],
    });
    controller.setMarkers(latest);
    await tester.pumpAndSettle();
    expect(builder.markers.single.label, 'new');
    semantics.dispose();
  });

  testWidgets('scroll frames reuse cached day data and painters', (
    tester,
  ) async {
    final controller = CalendarController(
      focusedDay: DateTime(2026, 7, 9),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 12, 31),
    );
    final builder = _CountingBuilder();
    await _pumpCalendar(tester, controller, builder: builder);
    final originalBuilds = builder.builds;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump();
    expect(builder.builds, originalBuilds);
    await gesture.up();
    await tester.pumpAndSettle();
    controller.setMarkers({
      DateTime(2026, 7, 9): [
        const CalendarMarker(label: 'event', color: Colors.red),
      ],
    });
    await tester.pumpAndSettle();
    expect(builder.builds, greaterThan(originalBuilds));
  });

  testWidgets('Canvas styles match Widget rendering including scaled text', (
    tester,
  ) async {
    final controller = _controller();
    controller.setMarkers({
      DateTime(2026, 7, 10): [
        const CalendarMarker(label: '75', color: Colors.orange),
      ],
    });
    controller.setSelectionMode(CalendarSelectionMode.range);
    controller.selectDay(DateTime(2026, 7, 9));
    controller.selectDay(DateTime(2026, 7, 11));
    for (final (style, scale, stretchHeight) in [
      (const DefaultCalendarComponentBuilder(), 1.0, null),
      (const DefaultCalendarComponentBuilder(), 2.0, null),
      (const ColorfulCalendarComponentBuilder(), 1.0, null),
      (const IndexCalendarComponentBuilder(), 1.0, null),
      (const MultiSelectCalendarComponentBuilder(), 1.0, null),
      (const ProgressCalendarComponentBuilder(), 1.0, null),
      (const RangeCalendarComponentBuilder(), 1.0, null),
      (const SingleSelectCalendarComponentBuilder(), 1.0, null),
      (const SolarCalendarComponentBuilder(), 1.0, null),
      (const DefaultCalendarComponentBuilder(), 2.0, 413.75),
      (const CustomCalendarComponentBuilder(), 1.0, 413.75),
      (const CustomCalendarComponentBuilder(), 2.0, 450.0),
      (const CustomCalendarComponentBuilder(), 1.0, 450.0),
    ]) {
      final boundaryKey = GlobalKey();
      final images = CalendarStretchImageCache();
      addTearDown(images.clear);
      final pixelRatio =
          style is CustomCalendarComponentBuilder &&
              stretchHeight == 450 &&
              scale == 1
          ? 3.0
          : 1.0;
      Future<void> pump(CalendarComponentBuilder builder) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  devicePixelRatio: pixelRatio,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox(
                      width: 375,
                      child: CalendarStretchMotion(
                        images: images,
                        // Integer row origins allow pixel comparison with the
                        // direct painter, including the selected day and badge.
                        active:
                            style is CustomCalendarComponentBuilder &&
                            stretchHeight == 450,
                        child: CalendarView(
                          controller: controller,
                          componentBuilder: builder,
                          monthBodyHeightOverride: stretchHeight,
                          pageOrientation: CalendarPageOrientation.horizontal,
                          onDaySelected: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(_LegacyBuilder(style));
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ui.Image reference = await boundary.toImage(pixelRatio: pixelRatio);
      await pump(style);
      final actualBoundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final actual = await actualBoundary.toImage(pixelRatio: pixelRatio);
      if (style is DefaultCalendarComponentBuilder) {
        await expectLater(
          actual,
          matchesReferenceImage(reference),
          reason: 'text scale $scale',
        );
      } else {
        await tester.runAsync(() async {
          final expectedData = (await reference.toByteData())!;
          final actualData = (await actual.toByteData())!;
          expect(actual.width, reference.width);
          expect(actual.height, reference.height);
          var changedPixels = 0;
          var largestDelta = 0;
          for (var pixel = 0; pixel < actualData.lengthInBytes; pixel += 4) {
            var changed = false;
            for (var channel = 0; channel < 4; channel++) {
              final delta =
                  (actualData.getUint8(pixel + channel) -
                          expectedData.getUint8(pixel + channel))
                      .abs();
              if (delta > 0) changed = true;
              if (delta > largestDelta) largestDelta = delta;
            }
            if (changed) changedPixels++;
          }
          // Arc rasterization can round differently after combining transforms.
          // Permit only a few edge pixels with a small channel difference.
          expect(
            largestDelta,
            lessThanOrEqualTo(10),
            reason: '${style.runtimeType}',
          );
          expect(
            changedPixels,
            lessThanOrEqualTo(20),
            reason: '${style.runtimeType}',
          );
        });
      }
      actual.dispose();
      reference.dispose();
    }
  });
}

class _MarkerLookup
    extends UnmodifiableMapBase<DateTime, List<CalendarMarker>> {
  _MarkerLookup(this.day, this.markers);

  final DateTime day;
  final List<CalendarMarker> markers;
  int keyReads = 0;

  @override
  Iterable<DateTime> get keys {
    keyReads++;
    return [day];
  }

  @override
  List<CalendarMarker>? operator [](Object? key) => key == day ? markers : null;
}

class _DenseMarkers extends ListBase<CalendarMarker> {
  _DenseMarkers(this.firstMarker);

  final CalendarMarker firstMarker;
  int reads = 0;

  @override
  int get length => 10000000;

  @override
  set length(int value) => throw UnsupportedError('Fixed test list');

  @override
  void operator []=(int index, CalendarMarker value) =>
      throw UnsupportedError('Fixed test list');

  @override
  CalendarMarker operator [](int index) {
    RangeError.checkValidIndex(index, this);
    reads++;
    if (reads > 64) fail('Calendar traversed the large marker list.');
    return index == 0
        ? firstMarker
        : CalendarMarker(label: 'marker $index', color: Colors.blue);
  }
}

class _MarkerCapture extends DefaultCalendarComponentBuilder {
  _MarkerCapture(this.day);

  final DateTime day;
  late List<CalendarMarker> markers;

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    if (data.date == day) markers = data.markers;
    return super.buildDayCell(context, data);
  }
}

class _CountingBuilder extends DefaultCalendarComponentBuilder {
  int builds = 0;

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    builds++;
    return super.buildDayCell(context, data);
  }
}

class _OverrideBuilder extends DefaultCalendarComponentBuilder {
  const _OverrideBuilder();

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return data.date.day == 9
        ? const Center(child: Text('CUSTOM-9'))
        : super.buildDayCell(context, data);
  }
}

class _BadgeBuilder extends DefaultCalendarComponentBuilder {
  const _BadgeBuilder(this.onTap);

  final VoidCallback onTap;

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    if (data.date.day != 9) return super.buildDayCell(context, data);
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: const Text('Open event', style: TextStyle(fontSize: 5)),
      ),
    );
  }
}

class _LiveCellBuilder extends DefaultCalendarComponentBuilder {
  const _LiveCellBuilder(this.repaint, this.onPaint);
  final Listenable repaint;
  final ValueChanged<Size> onPaint;

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    if (data.date.day == 9) {
      return CustomPaint(painter: _LiveCell(repaint, onPaint));
    }
    return super.buildDayCell(context, data);
  }
}

class _LiveCell extends CustomPainter {
  _LiveCell(Listenable repaint, this.onPaint) : super(repaint: repaint);
  final ValueChanged<Size> onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint(size);

  @override
  bool shouldRepaint(_LiveCell oldDelegate) => false;
}

class _LegacyBuilder extends CalendarComponentBuilder {
  const _LegacyBuilder(this.delegate);
  final CalendarComponentBuilder delegate;

  @override
  EdgeInsetsGeometry get contentPadding => delegate.contentPadding;

  @override
  Color get weekBarBackgroundColor => delegate.weekBarBackgroundColor;

  @override
  Widget buildMonthHeader(
    BuildContext context,
    DateTime month,
    double height,
  ) => delegate.buildMonthHeader(context, month, height);

  @override
  List<String> orderedWeekLabels(int firstWeekday) =>
      delegate.orderedWeekLabels(firstWeekday);

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) =>
      delegate.buildWeekBarCell(context, data);

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    if (delegate.runtimeType != DefaultCalendarComponentBuilder) {
      // Keep the original per-date RenderCustomPaint path for comparison.
      return SizedBox.expand(child: delegate.buildDayCell(context, data));
    }
    final textColor = data.isDisabled || !data.isCurrentMonth
        ? const Color(0xFFE1E1E1)
        : data.isSelected
        ? Colors.white
        : data.isToday
        ? const Color(0xFFFF0000)
        : const Color(0xFF333333);
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: data.isSelected
            ? const BoxDecoration(
                color: Color(0xFF128C4B),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          '${data.date.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}
