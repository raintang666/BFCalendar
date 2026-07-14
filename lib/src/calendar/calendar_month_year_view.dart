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

@immutable
class CalendarYearModeStyle {
  const CalendarYearModeStyle({
    required this.backgroundColor,
    required this.primaryColor,
    required this.dayColor,
    required this.outsideMonthDayColor,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.dividerColor,
    required this.inactiveBorderColor,
    this.disabledMonthBackgroundColor = const Color(0xFFF8F9FB),
    this.disabledMonthBorderColor = const Color(0xFFEDEFF3),
    this.disabledMonthTextColor = const Color(0xFFC7CAD1),
    this.disabledMonthDayColor = const Color(0xFFD4D7DE),
    this.disabledMonthOutsideDayColor = const Color(0xFFE6E8EE),
    this.headerHeight = 86,
    this.monthCardRadius = 8,
    this.monthNames = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'June',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ],
  });

  final Color backgroundColor;
  final Color primaryColor;
  final Color dayColor;
  final Color outsideMonthDayColor;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color dividerColor;
  final Color inactiveBorderColor;
  final Color disabledMonthBackgroundColor;
  final Color disabledMonthBorderColor;
  final Color disabledMonthTextColor;
  final Color disabledMonthDayColor;
  final Color disabledMonthOutsideDayColor;
  final double headerHeight;
  final double monthCardRadius;
  final List<String> monthNames;

  static const dark = CalendarYearModeStyle(
    backgroundColor: Colors.black,
    primaryColor: Colors.white,
    dayColor: Colors.white,
    outsideMonthDayColor: Color(0xFF666666),
    selectedColor: Colors.white,
    selectedTextColor: Colors.black,
    dividerColor: Color(0xFF666666),
    inactiveBorderColor: Color(0xFF333333),
    disabledMonthBackgroundColor: Color(0xFF070707),
    disabledMonthBorderColor: Color(0xFF242424),
    disabledMonthTextColor: Color(0xFF4A4A4A),
    disabledMonthDayColor: Color(0xFF3F3F3F),
    disabledMonthOutsideDayColor: Color(0xFF2A2A2A),
  );

  static const vertical = CalendarYearModeStyle(
    backgroundColor: Colors.white,
    primaryColor: Color(0xFFB66974),
    dayColor: Color(0xFFA7A8AC),
    outsideMonthDayColor: Color(0xFFF0F0F0),
    selectedColor: Color(0xFFB66974),
    selectedTextColor: Colors.white,
    dividerColor: Color(0xAAE5E7E7),
    inactiveBorderColor: Color(0xFFE5E7E7),
    disabledMonthBackgroundColor: Color(0xFFF8F9FB),
    disabledMonthBorderColor: Color(0xFFEDEFF3),
    disabledMonthTextColor: Color(0xFFC7CAD1),
    disabledMonthDayColor: Color(0xFFD4D7DE),
    disabledMonthOutsideDayColor: Color(0xFFE6E8EE),
  );
}

class CalendarYearModeLayout extends StatefulWidget {
  const CalendarYearModeLayout({
    super.key,
    required this.controller,
    required this.selectedDate,
    required this.onMonthSelected,
    required this.child,
    this.minDate,
    this.maxDate,
    this.style = CalendarYearModeStyle.vertical,
  });

  final CalendarMonthYearController controller;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthSelected;
  final Widget child;
  final DateTime? minDate;
  final DateTime? maxDate;
  final CalendarYearModeStyle style;

  @override
  State<CalendarYearModeLayout> createState() => _CalendarYearModeLayoutState();
}

class _CalendarYearModeLayoutState extends State<CalendarYearModeLayout>
    with SingleTickerProviderStateMixin {
  bool _yearMode = false;
  bool _overlayVisible = false;
  late int _visibleYear;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.selectedDate.year;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _attachController();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant CalendarYearModeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      _attachController();
      _syncController();
    }
    if (!_yearMode && oldWidget.selectedDate != widget.selectedDate) {
      _visibleYear = widget.selectedDate.year;
      _syncController();
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    _fadeController.dispose();
    super.dispose();
  }

  void _attachController() {
    widget.controller._attach(
      _CalendarMonthYearActions(
        showYearMode: _showYearMode,
        hideYearMode: _hideYearMode,
      ),
    );
  }

  void _showYearMode() {
    if (_yearMode && _overlayVisible) {
      return;
    }
    setState(() {
      _yearMode = true;
      _overlayVisible = true;
      _visibleYear = widget.selectedDate.year;
    });
    _fadeController.forward(from: 0);
    _syncController();
  }

  Future<void> _hideYearMode() async {
    if (!_overlayVisible) {
      return;
    }
    await _fadeController.reverse(from: _fadeController.value);
    if (!mounted) {
      return;
    }
    setState(() {
      _yearMode = false;
      _overlayVisible = false;
      _visibleYear = widget.selectedDate.year;
    });
    _syncController();
  }

  void _handleMonthSelected(DateTime month) {
    widget.onMonthSelected(month);
    _hideYearMode();
  }

  void _handleVisibleYearChanged(int year) {
    _visibleYear = year;
    _syncController();
  }

  void _syncController() {
    widget.controller._syncState(
      isYearMode: _yearMode,
      visibleYear: _visibleYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_overlayVisible)
          IgnorePointer(
            ignoring: !_yearMode,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              child: _StyledYearOverlay(
                initialYear: _visibleYear,
                selectedDate: widget.selectedDate,
                minDate: widget.minDate,
                maxDate: widget.maxDate,
                style: widget.style,
                onClose: _hideYearMode,
                onVisibleYearChanged: _handleVisibleYearChanged,
                onMonthSelected: _handleMonthSelected,
              ),
            ),
          ),
      ],
    );
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
                minDate: widget.controller.minDate,
                maxDate: widget.controller.maxDate,
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
    required this.minDate,
    required this.maxDate,
    required this.onVisibleYearChanged,
    required this.onMonthTap,
  });

  final int initialYear;
  final DateTime selectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final ValueChanged<int> onVisibleYearChanged;
  final ValueChanged<DateTime> onMonthTap;

  @override
  State<_YearOverlay> createState() => _YearOverlayState();
}

class _YearOverlayState extends State<_YearOverlay> {
  late final PageController _pageController;
  late int _visibleYear;

  int get _minYear => widget.minDate?.year ?? 1;
  int get _maxYear => widget.maxDate?.year ?? 9999;
  int get _yearCount => _maxYear - _minYear + 1;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.initialYear.clamp(_minYear, _maxYear);
    _pageController = PageController(initialPage: _pageForYear(_visibleYear));
  }

  @override
  void didUpdateWidget(covariant _YearOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialYear != widget.initialYear ||
        oldWidget.minDate != widget.minDate ||
        oldWidget.maxDate != widget.maxDate) {
      _visibleYear = widget.initialYear.clamp(_minYear, _maxYear);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(_pageForYear(_visibleYear));
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
    final currentPage =
        _pageController.page?.round() ?? _pageForYear(_visibleYear);
    final targetPage = (currentPage + delta).clamp(0, _yearCount - 1);
    if (targetPage == currentPage) {
      return;
    }
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  int _yearForPage(int page) {
    return _minYear + page;
  }

  int _pageForYear(int year) {
    return (year - _minYear).clamp(0, _yearCount - 1);
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
                  enabled: _visibleYear > _minYear,
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
                  enabled: _visibleYear < _maxYear,
                  onTap: () => _animateToYearPage(1),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _yearCount,
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
                  minDate: widget.minDate,
                  maxDate: widget.maxDate,
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
    required this.minDate,
    required this.maxDate,
    required this.onMonthTap,
  });

  final int year;
  final DateTime selectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
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
            final enabled = _isMonthSelectable(monthDate);
            return _YearMonthCard(
              year: year,
              month: month,
              selected: selected,
              enabled: enabled,
              selectedDate: selectedDate,
              onTap: enabled ? () => onMonthTap(monthDate) : null,
            );
          },
        );
      },
    );
  }

  bool _isMonthSelectable(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = CalendarDateUtils.lastDayOfMonth(month);
    final min = minDate == null ? null : CalendarDateUtils.stripTime(minDate!);
    final max = maxDate == null ? null : CalendarDateUtils.stripTime(maxDate!);
    if (min != null && monthEnd.isBefore(min)) {
      return false;
    }
    if (max != null && monthStart.isAfter(max)) {
      return false;
    }
    return true;
  }
}

class _YearMonthCard extends StatelessWidget {
  const _YearMonthCard({
    required this.year,
    required this.month,
    required this.selected,
    required this.enabled,
    required this.selectedDate,
    required this.onTap,
  });

  final int year;
  final int month;
  final bool selected;
  final bool enabled;
  final DateTime selectedDate;
  final VoidCallback? onTap;

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
          color: enabled ? Colors.white : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: const Color(0xFF128C4B), width: 1.2)
              : enabled
              ? null
              : Border.all(color: const Color(0xFFEDEFF3), width: 0.5),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month月',
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF888888)
                    : const Color(0xFFC7CAD1),
                fontSize: 12,
              ),
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
                          ? enabled
                                ? const Color(0xFF888888)
                                : const Color(0xFFD4D7DE)
                          : enabled
                          ? const Color(0xFFD9D9D9)
                          : const Color(0xFFE6E8EE);
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
  const _YearHeaderButton({
    required this.text,
    required this.onTap,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? const Color(0xFF888888) : const Color(0xFFC7CAD1),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StyledYearOverlay extends StatefulWidget {
  const _StyledYearOverlay({
    required this.initialYear,
    required this.selectedDate,
    required this.minDate,
    required this.maxDate,
    required this.style,
    required this.onClose,
    required this.onVisibleYearChanged,
    required this.onMonthSelected,
  });

  final int initialYear;
  final DateTime selectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final CalendarYearModeStyle style;
  final VoidCallback onClose;
  final ValueChanged<int> onVisibleYearChanged;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  State<_StyledYearOverlay> createState() => _StyledYearOverlayState();
}

class _StyledYearOverlayState extends State<_StyledYearOverlay> {
  late final PageController _pageController;
  late int _visibleYear;

  int get _minYear => widget.minDate?.year ?? 1;
  int get _maxYear => widget.maxDate?.year ?? 9999;
  int get _yearCount => _maxYear - _minYear + 1;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.initialYear.clamp(_minYear, _maxYear);
    _pageController = PageController(initialPage: _pageForYear(_visibleYear));
  }

  @override
  void didUpdateWidget(covariant _StyledYearOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialYear != widget.initialYear ||
        oldWidget.minDate != widget.minDate ||
        oldWidget.maxDate != widget.maxDate) {
      _visibleYear = widget.initialYear.clamp(_minYear, _maxYear);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(_pageForYear(_visibleYear));
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _yearForPage(int page) {
    return _minYear + page;
  }

  int _pageForYear(int year) {
    return (year - _minYear).clamp(0, _yearCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.style.backgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: widget.style.headerHeight,
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    '$_visibleYear年',
                    style: TextStyle(
                      color: widget.style.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: widget.style.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          Container(height: 0.5, color: widget.style.dividerColor),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _yearCount,
              onPageChanged: (page) {
                final year = _yearForPage(page);
                setState(() {
                  _visibleYear = year;
                });
                widget.onVisibleYearChanged(year);
              },
              itemBuilder: (context, page) {
                final year = _yearForPage(page);
                return _StyledYearGridPage(
                  year: year,
                  selectedDate: widget.selectedDate,
                  minDate: widget.minDate,
                  maxDate: widget.maxDate,
                  style: widget.style,
                  onMonthSelected: widget.onMonthSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledYearGridPage extends StatelessWidget {
  const _StyledYearGridPage({
    required this.year,
    required this.selectedDate,
    required this.minDate,
    required this.maxDate,
    required this.style,
    required this.onMonthSelected,
  });

  final int year;
  final DateTime selectedDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final CalendarYearModeStyle style;
  final ValueChanged<DateTime> onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = DateTime(year, index + 1);
        final enabled = _isMonthSelectable(month);
        return _StyledYearMonthCard(
          month: month,
          selectedDate: selectedDate,
          enabled: enabled,
          style: style,
          onTap: enabled ? () => onMonthSelected(month) : null,
        );
      },
    );
  }

  bool _isMonthSelectable(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = CalendarDateUtils.lastDayOfMonth(month);
    final min = minDate == null ? null : CalendarDateUtils.stripTime(minDate!);
    final max = maxDate == null ? null : CalendarDateUtils.stripTime(maxDate!);
    if (min != null && monthEnd.isBefore(min)) {
      return false;
    }
    if (max != null && monthStart.isAfter(max)) {
      return false;
    }
    return true;
  }
}

class _StyledYearMonthCard extends StatelessWidget {
  const _StyledYearMonthCard({
    required this.month,
    required this.selectedDate,
    required this.enabled,
    required this.style,
    required this.onTap,
  });

  final DateTime month;
  final DateTime selectedDate;
  final bool enabled;
  final CalendarYearModeStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final days = CalendarDateUtils.visibleMonthDays(
      month,
      monthViewShowMode: MonthViewShowMode.allMonth,
    );
    final isSelectedMonth =
        selectedDate.year == month.year && selectedDate.month == month.month;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled
              ? Colors.transparent
              : style.disabledMonthBackgroundColor,
          border: Border.all(
            color: isSelectedMonth
                ? style.primaryColor
                : enabled
                ? style.inactiveBorderColor
                : style.disabledMonthBorderColor,
            width: isSelectedMonth ? 1.2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(style.monthCardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style.monthNames[month.month - 1],
                style: TextStyle(
                  color: enabled
                      ? style.primaryColor
                      : style.disabledMonthTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isInMonth = CalendarDateUtils.isSameMonth(day, month);
                    final isSelected =
                        CalendarDateUtils.isSameDay(day, selectedDate) &&
                        isInMonth;
                    return DecoratedBox(
                      decoration: isSelected
                          ? BoxDecoration(
                              color: style.selectedColor,
                              shape: BoxShape.circle,
                            )
                          : const BoxDecoration(),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isSelected
                                ? style.selectedTextColor
                                : isInMonth
                                ? enabled
                                      ? style.dayColor
                                      : style.disabledMonthDayColor
                                : enabled
                                ? style.outsideMonthDayColor
                                : style.disabledMonthOutsideDayColor,
                            fontSize: 7,
                            height: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
