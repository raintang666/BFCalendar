import 'package:flutter/foundation.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({
    DateTime? focusedDay,
    DateTime? minDate,
    DateTime? maxDate,
    int minSelectRange = -1,
    int maxSelectRange = -1,
    Map<DateTime, List<CalendarMarker>> markers = const {},
    Set<DateTime> disabledDates = const {},
  }) : _minDate = _normalizeNullableDate(minDate),
       _maxDate = _normalizeNullableDate(maxDate),
       _focusedDay = CalendarDateUtils.stripTime(focusedDay ?? DateTime.now()),
       _minSelectRange = _normalizeSelectRangeLimit(minSelectRange),
       _maxSelectRange = _normalizeSelectRangeLimit(maxSelectRange),
       _markers = {
         for (final entry in markers.entries)
           CalendarDateUtils.stripTime(entry.key): entry.value,
       },
       _disabledDates = disabledDates.map(CalendarDateUtils.stripTime).toSet() {
    if (_minDate != null && _maxDate != null && _minDate!.isAfter(_maxDate!)) {
      throw ArgumentError('minDate must be on or before maxDate');
    }
    if (!_isValidSelectRangeLimitPair(_minSelectRange, _maxSelectRange)) {
      throw ArgumentError('minSelectRange must be less than maxSelectRange');
    }
    _focusedDay = _snapDateToRangeStart(
      _focusedDay,
      minDate: _minDate,
      maxDate: _maxDate,
      fallback: _focusedDay,
    );
    _selection = CalendarSelectionState(single: _focusedDay);
  }

  DateTime _focusedDay;
  CalendarDisplayMode _displayMode = CalendarDisplayMode.month;
  CalendarSelectionMode _selectionMode = CalendarSelectionMode.single;
  int _firstWeekday = DateTime.sunday;
  CalendarSelectionState _selection = const CalendarSelectionState();
  Map<DateTime, List<CalendarMarker>> _markers;
  final Set<DateTime> _disabledDates;
  MonthViewShowMode _monthViewShowMode = MonthViewShowMode.onlyCurrentMonth;
  bool _interceptBlocked = true;
  int _minSelectRange;
  int _maxSelectRange;

  DateTime? _minDate;
  DateTime? _maxDate;

  DateTime get focusedDay => _focusedDay;
  CalendarDisplayMode get displayMode => _displayMode;
  CalendarSelectionMode get selectionMode => _selectionMode;
  int get firstWeekday => _firstWeekday;
  CalendarSelectionState get selection => _selection;
  DateRangeValue get rangeSelection => _selection.range;
  List<DateTime> get selectedRangeDates {
    final start = _selection.range.start;
    final end = _selection.range.end;
    if (start == null || end == null) {
      return const <DateTime>[];
    }
    return CalendarDateUtils.eachDay(start, end);
  }

  Map<DateTime, List<CalendarMarker>> get markers => _markers;
  MonthViewShowMode get monthViewShowMode => _monthViewShowMode;
  bool get onlyCurrentMonth =>
      _monthViewShowMode == MonthViewShowMode.onlyCurrentMonth;
  bool get interceptBlocked => _interceptBlocked;
  int get minSelectRange => _minSelectRange;
  int get maxSelectRange => _maxSelectRange;
  DateTime? get minDate => _minDate;
  DateTime? get maxDate => _maxDate;
  DateTime? get minRangeCalendar => _minDate;
  DateTime? get maxRangeCalendar => _maxDate;
  CalendarBounds get calendarRange =>
      CalendarBounds(min: _minDate, max: _maxDate);

  String get rangeDescription {
    final minText = _minDate == null
        ? 'unbounded'
        : CalendarDateUtils.formatIsoDate(_minDate!);
    final maxText = _maxDate == null
        ? 'unbounded'
        : CalendarDateUtils.formatIsoDate(_maxDate!);
    return 'Calendar Range: $minText —— $maxText';
  }

  bool setCalendarRange({
    DateTime? minDate,
    DateTime? maxDate,
    bool clampFocusedDay = true,
    bool adjustSelection = true,
  }) {
    final normalizedMin = _normalizeNullableDate(minDate);
    final normalizedMax = _normalizeNullableDate(maxDate);
    if (normalizedMin != null &&
        normalizedMax != null &&
        normalizedMin.isAfter(normalizedMax)) {
      return false;
    }
    final sameMin =
        (normalizedMin == null && _minDate == null) ||
        (normalizedMin != null &&
            _minDate != null &&
            CalendarDateUtils.isSameDay(normalizedMin, _minDate!));
    final sameMax =
        (normalizedMax == null && _maxDate == null) ||
        (normalizedMax != null &&
            _maxDate != null &&
            CalendarDateUtils.isSameDay(normalizedMax, _maxDate!));
    if (sameMin && sameMax) {
      return true;
    }
    _minDate = normalizedMin;
    _maxDate = normalizedMax;
    if (clampFocusedDay) {
      _focusedDay = _snapDateToRangeStart(
        _focusedDay,
        minDate: _minDate,
        maxDate: _maxDate,
        fallback: _rangeAnchorDate,
      );
    }
    if (adjustSelection) {
      _selection = _adjustSelectionToBounds(_selection);
    }
    notifyListeners();
    return true;
  }

  bool setRange(
    int minYear,
    int minYearMonth,
    int minYearDay,
    int maxYear,
    int maxYearMonth,
    int maxYearDay,
  ) {
    return setCalendarRange(
      minDate: DateTime(minYear, minYearMonth, minYearDay),
      maxDate: DateTime(maxYear, maxYearMonth, maxYearDay),
    );
  }

  bool setRangeSelectionLimits({int minRange = -1, int maxRange = -1}) {
    final normalizedMin = _normalizeSelectRangeLimit(minRange);
    final normalizedMax = _normalizeSelectRangeLimit(maxRange);
    if (!_isValidSelectRangeLimitPair(normalizedMin, normalizedMax)) {
      return false;
    }
    if (_minSelectRange == normalizedMin && _maxSelectRange == normalizedMax) {
      return true;
    }
    _minSelectRange = normalizedMin;
    _maxSelectRange = normalizedMax;
    if (_selectionMode == CalendarSelectionMode.range &&
        !_isCurrentRangeSelectionWithinLimits()) {
      _selection = _selection.copyWith(range: const DateRangeValue());
    }
    notifyListeners();
    return true;
  }

  void setDisplayMode(CalendarDisplayMode mode) {
    if (_displayMode == mode) {
      return;
    }
    _displayMode = mode;
    notifyListeners();
  }

  void toggleDisplayMode() {
    setDisplayMode(
      _displayMode == CalendarDisplayMode.month
          ? CalendarDisplayMode.week
          : CalendarDisplayMode.month,
    );
  }

  void setWeekStart(int weekday) {
    if (_firstWeekday == weekday) {
      return;
    }
    _firstWeekday = weekday;
    notifyListeners();
  }

  void setOnlyCurrentMonth(bool value) {
    setMonthViewShowMode(
      value ? MonthViewShowMode.onlyCurrentMonth : MonthViewShowMode.allMonth,
    );
  }

  void setMonthViewShowMode(MonthViewShowMode mode) {
    if (_monthViewShowMode == mode) {
      return;
    }
    _monthViewShowMode = mode;
    notifyListeners();
  }

  void setInterceptBlocked(bool value) {
    if (_interceptBlocked == value) {
      return;
    }
    _interceptBlocked = value;
    notifyListeners();
  }

  void setSelectionMode(CalendarSelectionMode mode) {
    if (_selectionMode == mode) {
      return;
    }
    _selectionMode = mode;
    _selection = switch (mode) {
      CalendarSelectionMode.single => CalendarSelectionState(
        single: _focusedDay,
      ),
      CalendarSelectionMode.range => const CalendarSelectionState(
        range: DateRangeValue(),
      ),
      CalendarSelectionMode.multi => const CalendarSelectionState(),
    };
    notifyListeners();
  }

  void jumpToDay(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    if (_isOutOfBounds(normalized)) {
      return;
    }
    _focusedDay = normalized;
    notifyListeners();
  }

  void jumpToMonth(DateTime month) {
    final normalized = CalendarDateUtils.stripTime(month);
    if (!canShowMonth(normalized)) {
      return;
    }
    _focusedDay = _clampDate(
      normalized,
      minDate: _minDate,
      maxDate: _maxDate,
      fallback: _focusedDay,
    );
    notifyListeners();
  }

  void nextPage() {
    final target = resolvedPageAnchorForRelative(1);
    if (target == null) {
      return;
    }
    if (_displayMode == CalendarDisplayMode.month) {
      jumpToMonth(target);
    } else {
      jumpToDay(target);
    }
  }

  void previousPage() {
    final target = resolvedPageAnchorForRelative(-1);
    if (target == null) {
      return;
    }
    if (_displayMode == CalendarDisplayMode.month) {
      jumpToMonth(target);
    } else {
      jumpToDay(target);
    }
  }

  void setMarkers(Map<DateTime, List<CalendarMarker>> markers) {
    _markers = {
      for (final entry in markers.entries)
        CalendarDateUtils.stripTime(entry.key): entry.value,
    };
    notifyListeners();
  }

  bool isDisabled(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    if (_isOutOfBounds(normalized)) {
      return true;
    }
    if (_interceptBlocked) {
      const blockedDays = {1, 3, 6, 11, 12, 15, 20, 26};
      if (blockedDays.contains(normalized.day)) {
        return true;
      }
    }
    return _disabledDates.any(
      (item) => CalendarDateUtils.isSameDay(item, normalized),
    );
  }

  bool isSelected(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    return switch (_selectionMode) {
      CalendarSelectionMode.single =>
        _selection.single != null &&
            CalendarDateUtils.isSameDay(_selection.single!, normalized),
      CalendarSelectionMode.range =>
        _selection.range.start != null &&
            (_selection.range.end == null
                ? CalendarDateUtils.isSameDay(
                    _selection.range.start!,
                    normalized,
                  )
                : !normalized.isBefore(_selection.range.start!) &&
                      !normalized.isAfter(_selection.range.end!)),
      CalendarSelectionMode.multi => _selection.multi.any(
        (item) => CalendarDateUtils.isSameDay(item, normalized),
      ),
    };
  }

  bool isRangeStart(DateTime day) {
    return _selection.range.start != null &&
        CalendarDateUtils.isSameDay(_selection.range.start!, day);
  }

  bool isRangeEnd(DateTime day) {
    return _selection.range.end != null &&
        CalendarDateUtils.isSameDay(_selection.range.end!, day);
  }

  bool selectDay(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    if (isDisabled(normalized)) {
      return false;
    }

    switch (_selectionMode) {
      case CalendarSelectionMode.single:
        _focusedDay = normalized;
        _selection = _selection.copyWith(single: normalized);
        break;
      case CalendarSelectionMode.range:
        final current = _selection.range;
        if (current.start == null || current.isComplete) {
          _focusedDay = normalized;
          _selection = _selection.copyWith(
            range: DateRangeValue(start: normalized),
          );
        } else {
          final violation = rangeSelectionLimitViolation(normalized);
          if (violation != null) {
            return false;
          }
          _focusedDay = normalized;
          if (normalized.isBefore(current.start!)) {
            _selection = _selection.copyWith(
              range: DateRangeValue(start: normalized, end: current.start),
            );
          } else {
            _selection = _selection.copyWith(
              range: DateRangeValue(start: current.start, end: normalized),
            );
          }
        }
        break;
      case CalendarSelectionMode.multi:
        _focusedDay = normalized;
        final next = Set<DateTime>.from(_selection.multi);
        final existing = next.lookup(normalized);
        if (existing != null) {
          next.remove(existing);
        } else {
          next.add(normalized);
        }
        _selection = _selection.copyWith(multi: next);
        break;
    }

    notifyListeners();
    return true;
  }

  CalendarRangeLimitViolation? rangeSelectionLimitViolation(
    DateTime day, {
    int? minRange,
    int? maxRange,
  }) {
    final start = _selection.range.start;
    if (_selectionMode != CalendarSelectionMode.range ||
        start == null ||
        _selection.range.end != null) {
      return null;
    }
    final normalized = CalendarDateUtils.stripTime(day);
    final effectiveMin = _normalizeSelectRangeLimit(
      minRange ?? _minSelectRange,
    );
    final effectiveMax = _normalizeSelectRangeLimit(
      maxRange ?? _maxSelectRange,
    );
    final distance = normalized.difference(start).inDays.abs() + 1;
    if (effectiveMin > 0 && distance < effectiveMin) {
      return CalendarRangeLimitViolation.belowMinRange;
    }
    if (effectiveMax > 0 && distance > effectiveMax) {
      return CalendarRangeLimitViolation.aboveMaxRange;
    }
    return null;
  }

  bool canSelectRangeEnd(DateTime day, {int? minRange, int? maxRange}) {
    return rangeSelectionLimitViolation(
          day,
          minRange: minRange,
          maxRange: maxRange,
        ) ==
        null;
  }

  void clearSelection() {
    _selection = switch (_selectionMode) {
      CalendarSelectionMode.single => const CalendarSelectionState(),
      CalendarSelectionMode.range => const CalendarSelectionState(
        range: DateRangeValue(),
      ),
      CalendarSelectionMode.multi => const CalendarSelectionState(),
    };
    notifyListeners();
  }

  bool canNavigateToPreviousPage({
    DateTime? referenceDay,
    CalendarDisplayMode? displayMode,
  }) {
    return resolvedPageAnchorForRelative(
          -1,
          referenceDay: referenceDay,
          displayMode: displayMode,
        ) !=
        null;
  }

  bool canNavigateToNextPage({
    DateTime? referenceDay,
    CalendarDisplayMode? displayMode,
  }) {
    return resolvedPageAnchorForRelative(
          1,
          referenceDay: referenceDay,
          displayMode: displayMode,
        ) !=
        null;
  }

  DateTime? resolvedPageAnchorForRelative(
    int relative, {
    DateTime? referenceDay,
    CalendarDisplayMode? displayMode,
  }) {
    final mode = displayMode ?? _displayMode;
    final anchor = CalendarDateUtils.stripTime(referenceDay ?? _focusedDay);
    if (mode == CalendarDisplayMode.month) {
      final targetMonthAnchor = CalendarDateUtils.addMonths(anchor, relative);
      if (!canShowMonth(targetMonthAnchor)) {
        return null;
      }
      return _clampDate(
        targetMonthAnchor,
        minDate: _minDate,
        maxDate: _maxDate,
        fallback: anchor,
      );
    }
    final targetWeekAnchor = anchor.add(Duration(days: 7 * relative));
    if (!canShowWeek(targetWeekAnchor)) {
      return null;
    }
    return _clampDate(
      targetWeekAnchor,
      minDate: _minDate,
      maxDate: _maxDate,
      fallback: anchor,
    );
  }

  bool canShowMonth(DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month, 1);
    final monthStart = normalizedMonth;
    final monthEnd = CalendarDateUtils.lastDayOfMonth(normalizedMonth);
    if (_minDate != null && monthEnd.isBefore(_minDate!)) {
      return false;
    }
    if (_maxDate != null && monthStart.isAfter(_maxDate!)) {
      return false;
    }
    return true;
  }

  bool canShowWeek(DateTime anchorDay) {
    final weekDays = CalendarDateUtils.visibleWeekDays(
      anchorDay,
      firstWeekday: _firstWeekday,
    );
    final weekStart = weekDays.first;
    final weekEnd = weekDays.last;
    if (_minDate != null && weekEnd.isBefore(_minDate!)) {
      return false;
    }
    if (_maxDate != null && weekStart.isAfter(_maxDate!)) {
      return false;
    }
    return true;
  }

  bool _isOutOfBounds(DateTime date) {
    if (_minDate != null &&
        date.isBefore(CalendarDateUtils.stripTime(_minDate!))) {
      return true;
    }
    if (_maxDate != null &&
        date.isAfter(CalendarDateUtils.stripTime(_maxDate!))) {
      return true;
    }
    return false;
  }

  DateTime get _rangeAnchorDate => _minDate ?? _maxDate ?? _focusedDay;

  CalendarSelectionState _adjustSelectionToBounds(
    CalendarSelectionState selection,
  ) {
    return switch (_selectionMode) {
      CalendarSelectionMode.single => _adjustSingleSelectionToBounds(selection),
      CalendarSelectionMode.range => _adjustRangeSelectionToBounds(selection),
      CalendarSelectionMode.multi => _adjustMultiSelectionToBounds(selection),
    };
  }

  CalendarSelectionState _adjustSingleSelectionToBounds(
    CalendarSelectionState selection,
  ) {
    final single = selection.single;
    if (single == null || !_isOutOfBounds(single)) {
      return selection;
    }
    return selection.copyWith(single: _rangeAnchorDate);
  }

  CalendarSelectionState _adjustRangeSelectionToBounds(
    CalendarSelectionState selection,
  ) {
    final start = selection.range.start;
    final end = selection.range.end;
    if ((start != null && _isOutOfBounds(start)) ||
        (end != null && _isOutOfBounds(end))) {
      return selection.copyWith(range: const DateRangeValue());
    }
    return selection;
  }

  bool _isCurrentRangeSelectionWithinLimits() {
    final start = _selection.range.start;
    final end = _selection.range.end;
    if (start == null || end == null) {
      return true;
    }
    final distance = end.difference(start).inDays.abs() + 1;
    if (_minSelectRange > 0 && distance < _minSelectRange) {
      return false;
    }
    if (_maxSelectRange > 0 && distance > _maxSelectRange) {
      return false;
    }
    return true;
  }

  CalendarSelectionState _adjustMultiSelectionToBounds(
    CalendarSelectionState selection,
  ) {
    final next = selection.multi.where((date) => !_isOutOfBounds(date)).toSet();
    if (next.length == selection.multi.length) {
      return selection;
    }
    return selection.copyWith(multi: next);
  }

  static DateTime? _normalizeNullableDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return CalendarDateUtils.stripTime(date);
  }

  static int _normalizeSelectRangeLimit(int value) {
    return value > 0 ? value : -1;
  }

  static bool _isValidSelectRangeLimitPair(int minRange, int maxRange) {
    return minRange <= 0 || maxRange <= 0 || minRange <= maxRange;
  }

  static DateTime _clampDate(
    DateTime date, {
    required DateTime? minDate,
    required DateTime? maxDate,
    required DateTime fallback,
  }) {
    final normalized = CalendarDateUtils.stripTime(date);
    if (minDate != null && normalized.isBefore(minDate)) {
      return minDate;
    }
    if (maxDate != null && normalized.isAfter(maxDate)) {
      return maxDate;
    }
    return normalized;
  }

  static DateTime _snapDateToRangeStart(
    DateTime date, {
    required DateTime? minDate,
    required DateTime? maxDate,
    required DateTime fallback,
  }) {
    final normalized = CalendarDateUtils.stripTime(date);
    if ((minDate != null && normalized.isBefore(minDate)) ||
        (maxDate != null && normalized.isAfter(maxDate))) {
      return minDate ?? maxDate ?? fallback;
    }
    return normalized;
  }
}
