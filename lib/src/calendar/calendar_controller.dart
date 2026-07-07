import 'package:flutter/foundation.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({
    DateTime? focusedDay,
    this.minDate,
    this.maxDate,
    Map<DateTime, List<CalendarMarker>> markers = const {},
    Set<DateTime> disabledDates = const {},
  }) : _focusedDay = CalendarDateUtils.stripTime(focusedDay ?? DateTime.now()),
       _markers = {
         for (final entry in markers.entries)
           CalendarDateUtils.stripTime(entry.key): entry.value,
       },
       _disabledDates = disabledDates.map(CalendarDateUtils.stripTime).toSet();

  DateTime _focusedDay;
  CalendarDisplayMode _displayMode = CalendarDisplayMode.month;
  CalendarSelectionMode _selectionMode = CalendarSelectionMode.single;
  int _firstWeekday = DateTime.sunday;
  CalendarSelectionState _selection = CalendarSelectionState(
    single: CalendarDateUtils.stripTime(DateTime.now()),
  );
  Map<DateTime, List<CalendarMarker>> _markers;
  final Set<DateTime> _disabledDates;
  bool _onlyCurrentMonth = true;
  bool _interceptBlocked = true;

  final DateTime? minDate;
  final DateTime? maxDate;

  DateTime get focusedDay => _focusedDay;
  CalendarDisplayMode get displayMode => _displayMode;
  CalendarSelectionMode get selectionMode => _selectionMode;
  int get firstWeekday => _firstWeekday;
  CalendarSelectionState get selection => _selection;
  DateRangeValue get rangeSelection => _selection.range;
  Map<DateTime, List<CalendarMarker>> get markers => _markers;
  bool get onlyCurrentMonth => _onlyCurrentMonth;
  bool get interceptBlocked => _interceptBlocked;

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
    if (_onlyCurrentMonth == value) {
      return;
    }
    _onlyCurrentMonth = value;
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
    final normalized = DateTime(month.year, month.month, 1);
    if (_isOutOfBounds(normalized)) {
      return;
    }
    _focusedDay = normalized;
    notifyListeners();
  }

  void nextPage() {
    if (_displayMode == CalendarDisplayMode.month) {
      jumpToMonth(CalendarDateUtils.addMonths(_focusedDay, 1));
    } else {
      jumpToDay(_focusedDay.add(const Duration(days: 7)));
    }
  }

  void previousPage() {
    if (_displayMode == CalendarDisplayMode.month) {
      jumpToMonth(CalendarDateUtils.addMonths(_focusedDay, -1));
    } else {
      jumpToDay(_focusedDay.subtract(const Duration(days: 7)));
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

  void selectDay(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    if (isDisabled(normalized)) {
      return;
    }
    _focusedDay = normalized;

    switch (_selectionMode) {
      case CalendarSelectionMode.single:
        _selection = _selection.copyWith(single: normalized);
        break;
      case CalendarSelectionMode.range:
        final current = _selection.range;
        if (current.start == null || current.isComplete) {
          _selection = _selection.copyWith(
            range: DateRangeValue(start: normalized),
          );
        } else if (normalized.isBefore(current.start!)) {
          _selection = _selection.copyWith(
            range: DateRangeValue(start: normalized, end: current.start),
          );
        } else {
          _selection = _selection.copyWith(
            range: DateRangeValue(start: current.start, end: normalized),
          );
        }
        break;
      case CalendarSelectionMode.multi:
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

  bool _isOutOfBounds(DateTime date) {
    if (minDate != null &&
        date.isBefore(CalendarDateUtils.stripTime(minDate!))) {
      return true;
    }
    if (maxDate != null &&
        date.isAfter(CalendarDateUtils.stripTime(maxDate!))) {
      return true;
    }
    return false;
  }
}
