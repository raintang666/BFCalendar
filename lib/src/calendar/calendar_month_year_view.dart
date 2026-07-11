import 'package:flutter/material.dart';

import 'calendar_components.dart';
import 'calendar_controller.dart';
import 'calendar_interactive_view.dart';
import 'calendar_models.dart';
import 'date_utils_ext.dart';

class CalendarMonthYearController extends ChangeNotifier {
  _CalendarMonthYearActions? _actions;
  bool _isYearMode = false;
  int _visibleYear = DateTime.now().year;

  bool get isYearMode => _isYearMode;
  int get visibleYear => _visibleYear;

  void showYearMode() {
    _actions?.showYearMode();
  }

  void hideYearMode() {
    _actions?.hideYearMode();
  }

  void setYearMode(bool value) {
    if (value) {
      showYearMode();
      return;
    }
    hideYearMode();
  }

  void toggleYearMode() {
    setYearMode(!_isYearMode);
  }

  void _attach(_CalendarMonthYearActions actions) {
    _actions = actions;
  }

  void _detach() {
    _actions = null;
  }

  void _syncState({required bool isYearMode, required int visibleYear}) {
    var changed = false;
    if (_isYearMode != isYearMode) {
      _isYearMode = isYearMode;
      changed = true;
    }
    if (_visibleYear != visibleYear) {
      _visibleYear = visibleYear;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}

class _CalendarMonthYearActions {
  const _CalendarMonthYearActions({
    required this.showYearMode,
    required this.hideYearMode,
  });

  final VoidCallback showYearMode;
  final VoidCallback hideYearMode;
}

class CalendarMonthYearView extends StatefulWidget {
  const CalendarMonthYearView({
    super.key,
    required this.controller,
    required this.onDaySelected,
    required this.contentBuilder,
    this.onFocusedDayChanged,
    this.onYearModeChanged,
    this.onMonthSelected,
    this.interactionController,
    this.monthYearController,
    this.pageOrientation,
    this.calendarHeight = 62,
    this.weekBarHeight = 46,
    this.monthHeaderHeight = 60,
    this.componentBuilder,
    this.componentStyle = CalendarComponentStyle.custom,
  });

  final CalendarController controller;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onFocusedDayChanged;
  final ValueChanged<bool>? onYearModeChanged;
  final ValueChanged<DateTime>? onMonthSelected;
  final CalendarInteractiveContentBuilder contentBuilder;
  final CalendarInteractiveController? interactionController;
  final CalendarMonthYearController? monthYearController;
  final CalendarPageOrientation? pageOrientation;
  final double calendarHeight;
  final double weekBarHeight;
  final double monthHeaderHeight;
  final CalendarComponentBuilder? componentBuilder;
  final CalendarComponentStyle componentStyle;

  @override
  State<CalendarMonthYearView> createState() => _CalendarMonthYearViewState();
}

class _CalendarMonthYearViewState extends State<CalendarMonthYearView>
    with SingleTickerProviderStateMixin {
  bool _yearMode = false;
  bool _yearOverlayVisible = false;
  late int _yearPanelYear;
  late final AnimationController _yearOverlayFadeController;

  @override
  void initState() {
    super.initState();
    _yearPanelYear = widget.controller.focusedDay.year;
    _yearOverlayFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    widget.monthYearController?._attach(
      _CalendarMonthYearActions(
        showYearMode: _showYearMode,
        hideYearMode: _hideYearMode,
      ),
    );
    _syncMonthYearController();
  }

  @override
  void didUpdateWidget(covariant CalendarMonthYearView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _yearPanelYear = widget.controller.focusedDay.year;
    }
    if (oldWidget.monthYearController != widget.monthYearController) {
      oldWidget.monthYearController?._detach();
      widget.monthYearController?._attach(
        _CalendarMonthYearActions(
          showYearMode: _showYearMode,
          hideYearMode: _hideYearMode,
        ),
      );
      _syncMonthYearController();
    }
  }

  @override
  void dispose() {
    widget.monthYearController?._detach();
    _yearOverlayFadeController.dispose();
    super.dispose();
  }

  void _showYearMode() {
    if (_yearMode && _yearOverlayVisible) {
      return;
    }
    setState(() {
      _yearMode = true;
      _yearOverlayVisible = true;
      _yearPanelYear = widget.controller.focusedDay.year;
    });
    _yearOverlayFadeController.forward(
      from: _yearOverlayFadeController.status == AnimationStatus.reverse
          ? _yearOverlayFadeController.value
          : 0,
    );
    widget.onYearModeChanged?.call(true);
    _syncMonthYearController();
  }

  Future<void> _hideYearMode() async {
    if (!_yearOverlayVisible) {
      return;
    }
    await _yearOverlayFadeController.reverse(
      from: _yearOverlayFadeController.value,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _yearMode = false;
      _yearOverlayVisible = false;
      _yearPanelYear = widget.controller.focusedDay.year;
    });
    widget.onYearModeChanged?.call(false);
    _syncMonthYearController();
  }

  void _handleMonthTap(DateTime monthDate) {
    widget.controller.jumpToMonth(monthDate);
    _yearPanelYear = widget.controller.focusedDay.year;
    widget.onMonthSelected?.call(monthDate);
    _hideYearMode();
  }

  void _handleFocusedDayChanged(DateTime day) {
    _yearPanelYear = day.year;
    widget.onFocusedDayChanged?.call(day);
    _syncMonthYearController();
  }

  void _syncMonthYearController() {
    widget.monthYearController?._syncState(
      isYearMode: _yearMode,
      visibleYear: (_yearMode || _yearOverlayVisible)
          ? _yearPanelYear
          : widget.controller.focusedDay.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CalendarInteractiveView(
          controller: widget.controller,
          onDaySelected: widget.onDaySelected,
          onFocusedDayChanged: _handleFocusedDayChanged,
          contentBuilder: widget.contentBuilder,
          interactionController: widget.interactionController,
          pageOrientation: widget.pageOrientation,
          yearMode: _yearMode,
          calendarHeight: widget.calendarHeight,
          weekBarHeight: widget.weekBarHeight,
          monthHeaderHeight: widget.monthHeaderHeight,
          componentBuilder: widget.componentBuilder,
          componentStyle: widget.componentStyle,
        ),
        if (_yearOverlayVisible)
          IgnorePointer(
            ignoring: !_yearMode,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _yearOverlayFadeController,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              child: _YearOverlay(
                initialYear: _yearPanelYear,
                selectedDate: widget.controller.focusedDay,
                onVisibleYearChanged: (year) {
                  _yearPanelYear = year;
                  _syncMonthYearController();
                },
                onMonthTap: _handleMonthTap,
              ),
            ),
          ),
      ],
    );
  }
}

class _YearOverlay extends StatefulWidget {
  const _YearOverlay({
    required this.initialYear,
    required this.selectedDate,
    required this.onVisibleYearChanged,
    required this.onMonthTap,
  });

  final int initialYear;
  final DateTime selectedDate;
  final ValueChanged<int> onVisibleYearChanged;
  final ValueChanged<DateTime> onMonthTap;

  @override
  State<_YearOverlay> createState() => _YearOverlayState();
}

class _YearOverlayState extends State<_YearOverlay> {
  static const int _initialPage = 10000;

  late final PageController _pageController;
  late int _visibleYear;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.initialYear;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(covariant _YearOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialYear != widget.initialYear) {
      _visibleYear = widget.initialYear;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(_initialPage);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToYearPage(int delta) {
    if (!_pageController.hasClients) {
      return;
    }
    final currentPage = _pageController.page?.round() ?? _initialPage;
    _pageController.animateToPage(
      currentPage + delta,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  int _yearForPage(int page) {
    return widget.initialYear + (page - _initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F6FE),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 22),
                _YearHeaderButton(
                  text: '${_visibleYear - 1}',
                  onTap: () => _animateToYearPage(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_visibleYear',
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _YearHeaderButton(
                  text: '${_visibleYear + 1}',
                  onTap: () => _animateToYearPage(1),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                final nextYear = _yearForPage(page);
                setState(() {
                  _visibleYear = nextYear;
                });
                widget.onVisibleYearChanged(nextYear);
              },
              itemBuilder: (context, page) {
                final year = _yearForPage(page);
                return _YearGridPage(
                  year: year,
                  selectedDate: widget.selectedDate,
                  onMonthTap: widget.onMonthTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearGridPage extends StatelessWidget {
  const _YearGridPage({
    required this.year,
    required this.selectedDate,
    required this.onMonthTap,
  });

  final int year;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(10, 10, 10, 12);
        const crossAxisCount = 3;
        const mainAxisCount = 4;
        const mainAxisSpacing = 12.0;
        const crossAxisSpacing = 12.0;
        final itemWidth =
            (constraints.maxWidth -
                padding.horizontal -
                (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final itemHeight =
            (constraints.maxHeight -
                padding.vertical -
                (mainAxisSpacing * (mainAxisCount - 1))) /
            mainAxisCount;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final selected =
                selectedDate.year == year && selectedDate.month == month;
            final monthDate = DateTime(year, month, 1);
            return _YearMonthCard(
              year: year,
              month: month,
              selected: selected,
              selectedDate: selectedDate,
              onTap: () => onMonthTap(monthDate),
            );
          },
        );
      },
    );
  }
}

class _YearMonthCard extends StatelessWidget {
  const _YearMonthCard({
    required this.year,
    required this.month,
    required this.selected,
    required this.selectedDate,
    required this.onTap,
  });

  final int year;
  final int month;
  final bool selected;
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final monthDate = DateTime(year, month, 1);
    final previewDays = CalendarDateUtils.visibleMonthDays(
      monthDate,
      monthViewShowMode: MonthViewShowMode.allMonth,
    );
    final today = CalendarDateUtils.stripTime(DateTime.now());
    final selectedDay = CalendarDateUtils.stripTime(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: const Color(0xFF128C4B), width: 1.2)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month月',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 1.0;
                  final cellWidth = (constraints.maxWidth - (spacing * 6)) / 7;
                  final cellHeight =
                      (constraints.maxHeight - (spacing * 5)) / 6;
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: cellWidth / cellHeight,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: previewDays.length,
                    itemBuilder: (context, index) {
                      final day = previewDays[index];
                      final inMonth = CalendarDateUtils.isSameMonth(
                        day,
                        monthDate,
                      );
                      final isToday = CalendarDateUtils.isSameDay(day, today);
                      final isSelectedDay = CalendarDateUtils.isSameDay(
                        day,
                        selectedDay,
                      );
                      final shouldHighlightToday = isToday && inMonth;
                      final shouldHighlightSelected = isSelectedDay && inMonth;
                      final dayTextColor = shouldHighlightSelected
                          ? const Color(0xFF128C4B)
                          : shouldHighlightToday
                          ? const Color(0xFFFF0000)
                          : inMonth
                          ? const Color(0xFF888888)
                          : const Color(0xFFD9D9D9);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        alignment: Alignment.center,
                        decoration: shouldHighlightSelected
                            ? const BoxDecoration(
                                color: Color(0x80CFCFCF),
                                shape: BoxShape.circle,
                              )
                            : shouldHighlightToday
                            ? const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: dayTextColor,
                            fontSize: 8,
                            fontWeight:
                                shouldHighlightSelected || shouldHighlightToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearHeaderButton extends StatelessWidget {
  const _YearHeaderButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
      ),
    );
  }
}
