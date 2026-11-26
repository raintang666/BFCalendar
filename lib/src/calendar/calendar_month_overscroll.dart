import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'calendar_retained_day_painter.dart';

/// Adds temporary height to the month rows inside their fixed viewport.
class CalendarMonthOverscroll extends StatefulWidget {
  const CalendarMonthOverscroll({
    super.key,
    required this.monthBodyHeight,
    required this.canStart,
    required this.builder,
  });

  final double monthBodyHeight;
  final bool Function(BuildContext context)? canStart;
  final Widget Function(double extraHeight) builder;

  @override
  State<CalendarMonthOverscroll> createState() =>
      _CalendarMonthOverscrollState();
}

class _CalendarMonthOverscrollState extends State<CalendarMonthOverscroll>
    with SingleTickerProviderStateMixin {
  // ColorOS uses a 0.35 s natural period and critical damping.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: math.pow(2 * math.pi / 0.35, 2).toDouble(),
  );
  late final _stretch = AnimationController.unbounded(vsync: this);
  int? _pointer;
  Offset _origin = Offset.zero;
  bool _dragging = false;
  double _headroom = 0;
  double _initialStretch = 0;
  double _dragLimit = 0;

  @override
  void didUpdateWidget(CalendarMonthOverscroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canStart != null && widget.canStart == null) {
      _pointer = null;
      _stretch.value = 0;
    }
  }

  void _onDown(PointerDownEvent event) {
    if (_pointer != null ||
        event.buttons != kPrimaryButton ||
        widget.canStart?.call(context) != true) {
      return;
    }
    final limit = context
        .getInheritedWidgetOfExactType<CalendarStretchMotion>()
        ?.maxMonthBodyHeight;
    _dragLimit = 2500 / MediaQuery.devicePixelRatioOf(context);
    _headroom = math.max(
      0,
      (limit ?? widget.monthBodyHeight) - widget.monthBodyHeight,
    );
    _pointer = event.pointer;
    _origin = event.position;
    _dragging = false;
  }

  void _onMove(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    final delta = event.position - _origin;
    if (!_dragging) {
      if (delta.distanceSquared <= kTouchSlop * kTouchSlop) return;
      if (delta.dy <= delta.dx.abs()) {
        _pointer = null;
        return;
      }
      _stretch.stop();
      _initialStretch = _stretch.value;
      _dragging = true;
    }
    // The native drag curve is expressed in physical screen pixels.
    // Cap it at its maximum so a longer pull never moves the rows backwards.
    final limit = _dragLimit;
    final pull = (delta.dy - math.max(_headroom, kTouchSlop)).clamp(
      -limit / 2,
      limit / 2,
    );
    final extra = 0.7 * pull * (1 - pull.abs() / limit);
    final next = (_initialStretch + extra).clamp(0.0, 0.175 * limit);
    if (next != _stretch.value) _stretch.value = next;
  }

  void _onEnd(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _pointer = null;
    if (!_dragging || _stretch.value == 0) return;
    _dragging = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _stretch.value = 0;
    } else {
      _stretch.animateWith(
        ScrollSpringSimulation(_spring, _stretch.value, 0, 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _onDown,
    onPointerMove: _onMove,
    onPointerUp: _onEnd,
    onPointerCancel: _onEnd,
    child: AnimatedBuilder(
      animation: _stretch,
      builder: (context, _) => widget.builder(_stretch.value),
    ),
  );

  @override
  void dispose() {
    _stretch.dispose();
    super.dispose();
  }
}
