import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calendar/calendar_models.dart';
import '../../calendar/date_utils_ext.dart';

class FlipSimulationCalendarPage extends StatefulWidget {
  const FlipSimulationCalendarPage({super.key});

  @override
  State<FlipSimulationCalendarPage> createState() =>
      _FlipSimulationCalendarPageState();
}

class _FlipSimulationCalendarPageState extends State<FlipSimulationCalendarPage>
    with SingleTickerProviderStateMixin {
  static const int _minYear = 1971;
  static const int _maxYear = 2055;
  static const double _flipDistancePerPage = 180;
  static const double _calendarPadding = 16;
  static const double _settleMaxDurationMs = 300;

  late int _currentPage;
  late final AnimationController _settleController;
  DateTime _selectedDay = CalendarDateUtils.stripTime(DateTime.now());
  double _flipDistance = 0;
  double _lastDragY = 0;
  bool _isDragging = false;

  int get _pageCount => (_maxYear - _minYear + 1) * 12;
  double get _maxFlipDistance => (_pageCount - 1) * _flipDistancePerPage;
  double get _localFlipDistance =>
      _positiveModulo(_flipDistance, _flipDistancePerPage);
  double get _degreesFlipped =>
      (_localFlipDistance / _flipDistancePerPage) * 180;

  @override
  void initState() {
    super.initState();
    _selectedDay = _clampDay(_selectedDay);
    _currentPage = _monthIndexFor(_selectedDay);
    _flipDistance = _currentPage * _flipDistancePerPage;
    _settleController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        onVerticalDragCancel: () => _settleToPage(_nearestPage()),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildFlipView(constraints.biggest);
          },
        ),
      ),
    );
  }

  Widget _buildFlipView(Size size) {
    final currentPage = _currentPage.clamp(0, _pageCount - 1);
    final previousPage = currentPage > 0 ? currentPage - 1 : null;
    final nextPage = currentPage < _pageCount - 1 ? currentPage + 1 : null;
    final isAnimating = _isDragging || _settleController.isAnimating;

    if (!isAnimating || _degreesFlipped == 0) {
      return _buildBookPage(currentPage);
    }

    final degrees = _degreesFlipped;
    final topStaticPage = degrees > 90 ? previousPage : currentPage;
    final bottomStaticPage = degrees > 90 ? currentPage : nextPage;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (topStaticPage != null)
          _ClippedBookHalf(top: true, child: _buildBookPage(topStaticPage)),
        if (bottomStaticPage != null)
          _ClippedBookHalf(top: false, child: _buildBookPage(bottomStaticPage)),
        if (degrees > 90) _PreviousHalfShadow(alpha: (degrees - 90) / 90),
        if (degrees < 90) _NextHalfShadow(alpha: (90 - degrees) / 90),
        _buildTurningHalf(degrees),
        const Center(child: _BookBinding()),
      ],
    );
  }

  Widget _buildTurningHalf(double degrees) {
    final turnTopHalf = degrees > 90;
    final angle = turnTopHalf ? (180 - degrees) : -degrees;
    final alignment = turnTopHalf
        ? Alignment.bottomCenter
        : Alignment.topCenter;
    final depth = math.sin(angle.abs() * math.pi / 180);
    final scaleCompensation = 1 - (depth * 0.055);

    return _TurningBookHalf(
      top: turnTopHalf,
      alignment: alignment,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0007)
        ..scaleByDouble(1.0, scaleCompensation, 1.0, 1.0)
        ..rotateX(angle * math.pi / 180),
      child: _buildBookPage(_currentPage),
    );
  }

  Widget _buildBookPage(int page) {
    final month = _monthForIndex(page);
    return Stack(
      children: [
        Column(
          children: [
            const Expanded(child: _TopBookPanel()),
            const SizedBox(height: 4),
            Expanded(
              child: _BottomBookPanel(
                month: month,
                selectedDay: _selectedDay,
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay = CalendarDateUtils.stripTime(day);
                  });
                },
              ),
            ),
          ],
        ),
        const Align(alignment: Alignment.center, child: _BookBinding()),
      ],
    );
  }

  void _handleDragStart(DragStartDetails details) {
    _settleController.stop();
    _lastDragY = details.localPosition.dy;
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      return;
    }
    final dy = _lastDragY - details.localPosition.dy;
    _lastDragY = details.localPosition.dy;
    final viewportHeight = context.size?.height ?? 1;
    final delta = dy / (viewportHeight / _flipDistancePerPage);
    final nextDistance = (_flipDistance + delta).clamp(0.0, _maxFlipDistance);
    setState(() {
      _flipDistance = nextDistance;
      _currentPage = _nearestPage();
      _selectedDay = _sameDayInMonth(
        _selectedDay,
        _monthForIndex(_currentPage),
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) {
      return;
    }
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final targetPage = _targetPageForVelocity(velocity);
    _settleToPage(targetPage);
  }

  int _targetPageForVelocity(double velocity) {
    const minimumVelocity = 50.0;
    final page = _flipDistance / _flipDistancePerPage;
    if (velocity > minimumVelocity) {
      return page.floor().clamp(0, _pageCount - 1);
    }
    if (velocity < -minimumVelocity) {
      return page.ceil().clamp(0, _pageCount - 1);
    }
    return page.round().clamp(0, _pageCount - 1);
  }

  int _nearestPage() {
    return (_flipDistance / _flipDistancePerPage).round().clamp(
      0,
      _pageCount - 1,
    );
  }

  Future<void> _settleToPage(int page) async {
    final start = _flipDistance;
    final end = page * _flipDistancePerPage;
    final delta = (end - start).abs();
    if (delta == 0) {
      setState(() {
        _currentPage = page;
        _selectedDay = _sameDayInMonth(_selectedDay, _monthForIndex(page));
      });
      return;
    }

    final durationMs =
        _settleMaxDurationMs * math.sqrt(delta / _flipDistancePerPage);
    final animation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.decelerate),
    );

    void listener() {
      setState(() {
        _flipDistance = animation.value;
        _currentPage = _nearestPage();
      });
    }

    _settleController
      ..duration = Duration(milliseconds: durationMs.round())
      ..reset()
      ..addListener(listener);
    await _settleController.forward();
    _settleController.removeListener(listener);
    if (!mounted) {
      return;
    }
    setState(() {
      _flipDistance = end;
      _currentPage = page;
      _selectedDay = _sameDayInMonth(_selectedDay, _monthForIndex(page));
    });
  }

  DateTime _clampDay(DateTime day) {
    if (day.year < _minYear) {
      return DateTime(_minYear, 1, 1);
    }
    if (day.year > _maxYear) {
      return DateTime(_maxYear, 12, 31);
    }
    return day;
  }

  DateTime _sameDayInMonth(DateTime source, DateTime month) {
    final lastDay = CalendarDateUtils.daysInMonth(month);
    return DateTime(month.year, month.month, source.day.clamp(1, lastDay));
  }

  int _monthIndexFor(DateTime date) {
    final clampedYear = date.year.clamp(_minYear, _maxYear);
    return ((clampedYear - _minYear) * 12) + date.month - 1;
  }

  DateTime _monthForIndex(int index) {
    final year = _minYear + (index ~/ 12);
    final month = (index % 12) + 1;
    return DateTime(year, month);
  }

  double _positiveModulo(double value, double divisor) {
    final result = value % divisor;
    return result < 0 ? result + divisor : result;
  }
}

class _ClippedBookHalf extends StatelessWidget {
  const _ClippedBookHalf({required this.top, required this.child});

  final bool top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final alignment = top ? Alignment.topCenter : Alignment.bottomCenter;
        return Align(
          alignment: alignment,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight / 2,
            child: ClipRect(
              child: OverflowBox(
                alignment: alignment,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
                maxHeight: constraints.maxHeight,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TurningBookHalf extends StatelessWidget {
  const _TurningBookHalf({
    required this.top,
    required this.alignment,
    required this.transform,
    required this.child,
  });

  final bool top;
  final Alignment alignment;
  final Matrix4 transform;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clipAlignment = top
            ? Alignment.topCenter
            : Alignment.bottomCenter;
        return Align(
          alignment: clipAlignment,
          child: Transform(
            alignment: alignment,
            transform: transform,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight / 2,
              child: ClipRect(
                child: OverflowBox(
                  alignment: clipAlignment,
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreviousHalfShadow extends StatelessWidget {
  const _PreviousHalfShadow({required this.alpha});

  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 1,
        child: ColoredBox(
          color: Colors.black.withValues(
            alpha: (alpha.clamp(0, 1) * 180) / 255,
          ),
        ),
      ),
    );
  }
}

class _NextHalfShadow extends StatelessWidget {
  const _NextHalfShadow({required this.alpha});

  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 1,
        child: ColoredBox(
          color: Colors.black.withValues(
            alpha: (alpha.clamp(0, 1) * 180) / 255,
          ),
        ),
      ),
    );
  }
}

class _TopBookPanel extends StatelessWidget {
  const _TopBookPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 66, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/icons/ic_colorful_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CalendarView',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'An elegant, highly customized and high-performance Calendar Widget on Android.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF9F9F9F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'An elegant '),
                    TextSpan(
                      text: 'CalendarView',
                      style: TextStyle(
                        color: Color(0xFF8168E2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                          " on Android platform. Freely draw UI with canvas, fast、efficient and low memory. Support month view、 week view、year view、 custom week start、lunar calendar and so on. Hot plug UI customization! You can't think of the calendar can be so elegant!\nThe final version of the free and open source part is ",
                    ),
                    TextSpan(
                      text: '3.7.1',
                      style: TextStyle(
                        color: Color(0xFF8168E2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text:
                          ', the vertical and horizontal switching calendar liked iOS calendar are no longer open source.',
                    ),
                  ],
                ),
                overflow: TextOverflow.fade,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBookPanel extends StatelessWidget {
  const _BottomBookPanel({
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${month.year}年${month.month.toString().padLeft(2, '0')}月',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _FlipSimulationCalendarPageState._calendarPadding,
                0,
                _FlipSimulationCalendarPageState._calendarPadding,
                0,
              ),
              child: _FlipMonthGrid(
                month: month,
                selectedDay: selectedDay,
                onDaySelected: onDaySelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipMonthGrid extends StatelessWidget {
  const _FlipMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final visibleDays = CalendarDateUtils.visibleMonthDays(
      month,
      firstWeekday: DateTime.sunday,
      monthViewShowMode: MonthViewShowMode.onlyCurrentMonth,
    );
    final leadingBlanks = CalendarDateUtils.monthViewStartDiff(
      month,
      firstWeekday: DateTime.sunday,
    );
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      ...visibleDays.where((day) => CalendarDateUtils.isSameMonth(day, month)),
    ];
    final rowCount = (cells.length / 7).ceil();
    final paddedCells = [
      ...cells,
      for (var i = cells.length; i < rowCount * 7; i++) null,
    ];

    return Column(
      children: List.generate(rowCount, (row) {
        final rowDays = paddedCells.skip(row * 7).take(7);
        return Expanded(
          child: Row(
            children: rowDays.map((day) {
              return Expanded(
                child: day == null
                    ? const SizedBox.expand()
                    : _FlipDayCell(
                        day: day,
                        selectedDay: selectedDay,
                        onTap: () => onDaySelected(day),
                      ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

class _FlipDayCell extends StatelessWidget {
  const _FlipDayCell({
    required this.day,
    required this.selectedDay,
    required this.onTap,
  });

  final DateTime day;
  final DateTime selectedDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = CalendarDateUtils.isSameDay(day, selectedDay);
    final today = CalendarDateUtils.isSameDay(
      day,
      CalendarDateUtils.stripTime(DateTime.now()),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemSize =
              math.min(constraints.maxWidth, constraints.maxHeight) * 0.85;
          return Center(
            child: Container(
              width: itemSize,
              height: itemSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0x50CFCFCF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: today && !selected
                      ? Colors.red
                      : const Color(0xFF111111),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookBinding extends StatelessWidget {
  const _BookBinding();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [_BindingSlot(), SizedBox(width: 52), _BindingSlot()],
      ),
    );
  }
}

class _BindingSlot extends StatelessWidget {
  const _BindingSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 30,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF899CC7), Colors.white, Color(0xFF899CC7)],
        ),
      ),
    );
  }
}
