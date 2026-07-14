import 'package:flutter/foundation.dart';

import 'calendar_models.dart';
import 'date_utils_ext.dart';

/// 日历状态控制器。
class CalendarController extends ChangeNotifier {
  /// 创建日历控制器。
  CalendarController({
    DateTime? focusedDay,
    DateTime? minDate,
    DateTime? maxDate,
    int minSelectRange = -1,
    int maxSelectRange = -1,
    int maxMultiSelectSize = -1,
    Map<DateTime, List<CalendarMarker>> markers = const {},
    Set<DateTime> disabledDates = const {},
    CalendarDatePredicate? disabledDatePredicate,
  }) : _minDate = _normalizeNullableDate(minDate),
       _maxDate = _normalizeNullableDate(maxDate),
       _focusedDay = CalendarDateUtils.stripTime(focusedDay ?? DateTime.now()),
       _minSelectRange = _normalizeSelectRangeLimit(minSelectRange),
       _maxSelectRange = _normalizeSelectRangeLimit(maxSelectRange),
       _maxMultiSelectSize = _normalizeSelectRangeLimit(maxMultiSelectSize),
       _markers = {
         for (final entry in markers.entries)
           CalendarDateUtils.stripTime(entry.key): entry.value,
       },
       _disabledDates = disabledDates.map(CalendarDateUtils.stripTime).toSet(),
       _disabledDatePredicate = disabledDatePredicate {
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
  CalendarDatePredicate? _disabledDatePredicate;
  MonthViewShowMode _monthViewShowMode = MonthViewShowMode.onlyCurrentMonth;
  bool _interceptBlocked = true;
  int _minSelectRange;
  int _maxSelectRange;
  int _maxMultiSelectSize;

  DateTime? _minDate;
  DateTime? _maxDate;

  /// 当前聚焦日期。
  DateTime get focusedDay => _focusedDay;

  /// 当前显示模式。
  CalendarDisplayMode get displayMode => _displayMode;

  /// 当前选择模式。
  CalendarSelectionMode get selectionMode => _selectionMode;

  /// 周起始日。
  int get firstWeekday => _firstWeekday;

  /// 当前完整选择状态。
  CalendarSelectionState get selection => _selection;

  /// 范围选择值。
  DateRangeValue get rangeSelection => _selection.range;

  /// 多选日期列表，按日期升序返回。
  List<DateTime> get selectedMultiDates {
    final dates = _selection.multi.toList()..sort();
    return List.unmodifiable(dates);
  }

  /// 已完成范围选择内的所有日期。
  List<DateTime> get selectedRangeDates {
    final start = _selection.range.start;
    final end = _selection.range.end;
    if (start == null || end == null) {
      return const <DateTime>[];
    }
    return CalendarDateUtils.eachDay(start, end);
  }

  /// 日期标记数据。
  Map<DateTime, List<CalendarMarker>> get markers => _markers;

  /// 月视图显示模式。
  MonthViewShowMode get monthViewShowMode => _monthViewShowMode;

  /// 是否只显示当前月日期。
  bool get onlyCurrentMonth =>
      _monthViewShowMode == MonthViewShowMode.onlyCurrentMonth;

  /// 是否启用内置演示禁用日期。
  bool get interceptBlocked => _interceptBlocked;

  /// 范围选择最小天数。
  int get minSelectRange => _minSelectRange;

  /// 范围选择最大天数。
  int get maxSelectRange => _maxSelectRange;

  /// 多选最大数量。
  int get maxMultiSelectSize => _maxMultiSelectSize;

  /// 可显示、可选择的最小日期。
  DateTime? get minDate => _minDate;

  /// 可显示、可选择的最大日期。
  DateTime? get maxDate => _maxDate;

  /// 兼容原 Android 命名的最小日期。
  DateTime? get minRangeCalendar => _minDate;

  /// 兼容原 Android 命名的最大日期。
  DateTime? get maxRangeCalendar => _maxDate;

  /// 当前日期边界。
  CalendarBounds get calendarRange =>
      CalendarBounds(min: _minDate, max: _maxDate);

  /// 当前日期边界的文本描述。
  String get rangeDescription {
    final minText = _minDate == null
        ? 'unbounded'
        : CalendarDateUtils.formatIsoDate(_minDate!);
    final maxText = _maxDate == null
        ? 'unbounded'
        : CalendarDateUtils.formatIsoDate(_maxDate!);
    return 'Calendar Range: $minText —— $maxText';
  }

  /// 设置日历日期边界。
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

  /// 使用原 Android 风格参数设置日历日期边界。
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

  /// 设置范围选择天数限制。
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

  /// 设置多选最大数量。
  void setMaxMultiSelectSize(int maxSize) {
    final normalizedMaxSize = _normalizeSelectRangeLimit(maxSize);
    if (_maxMultiSelectSize == normalizedMaxSize) {
      return;
    }
    _maxMultiSelectSize = normalizedMaxSize;
    if (_selectionMode == CalendarSelectionMode.multi &&
        _maxMultiSelectSize > 0 &&
        _selection.multi.length > _maxMultiSelectSize) {
      final dates = selectedMultiDates.take(_maxMultiSelectSize).toSet();
      _selection = _selection.copyWith(multi: dates);
    }
    notifyListeners();
  }

  /// 设置月/周显示模式。
  void setDisplayMode(CalendarDisplayMode mode) {
    if (_displayMode == mode) {
      return;
    }
    _displayMode = mode;
    notifyListeners();
  }

  /// 切换月/周显示模式。
  void toggleDisplayMode() {
    setDisplayMode(
      _displayMode == CalendarDisplayMode.month
          ? CalendarDisplayMode.week
          : CalendarDisplayMode.month,
    );
  }

  /// 设置周起始日。
  void setWeekStart(int weekday) {
    if (_firstWeekday == weekday) {
      return;
    }
    _firstWeekday = weekday;
    notifyListeners();
  }

  /// 设置是否只显示当前月日期。
  void setOnlyCurrentMonth(bool value) {
    setMonthViewShowMode(
      value ? MonthViewShowMode.onlyCurrentMonth : MonthViewShowMode.allMonth,
    );
  }

  /// 设置月视图日期显示模式。
  void setMonthViewShowMode(MonthViewShowMode mode) {
    if (_monthViewShowMode == mode) {
      return;
    }
    _monthViewShowMode = mode;
    notifyListeners();
  }

  /// 设置是否启用内置演示禁用日期。
  void setInterceptBlocked(bool value) {
    if (_interceptBlocked == value) {
      return;
    }
    _interceptBlocked = value;
    notifyListeners();
  }

  /// 设置动态禁用日期判断。
  void setDisabledDatePredicate(CalendarDatePredicate? predicate) {
    if (_disabledDatePredicate == predicate) {
      return;
    }
    _disabledDatePredicate = predicate;
    notifyListeners();
  }

  /// 设置选择模式。
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

  /// 跳转到指定日期。
  void jumpToDay(DateTime day) {
    final normalized = CalendarDateUtils.stripTime(day);
    if (_isOutOfBounds(normalized)) {
      return;
    }
    _focusedDay = normalized;
    notifyListeners();
  }

  /// 跳转到指定月份。
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

  /// 跳转到下一页。
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

  /// 跳转到上一页。
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

  /// 替换日期标记数据。
  void setMarkers(Map<DateTime, List<CalendarMarker>> markers) {
    _markers = {
      for (final entry in markers.entries)
        CalendarDateUtils.stripTime(entry.key): entry.value,
    };
    notifyListeners();
  }

  /// 判断日期是否不可选。
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
    final disabledDatePredicate = _disabledDatePredicate;
    if (disabledDatePredicate != null && disabledDatePredicate(normalized)) {
      return true;
    }
    return _disabledDates.any(
      (item) => CalendarDateUtils.isSameDay(item, normalized),
    );
  }

  /// 判断日期是否处于选中状态。
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

  /// 判断日期是否是范围选择开始日期。
  bool isRangeStart(DateTime day) {
    return _selection.range.start != null &&
        CalendarDateUtils.isSameDay(_selection.range.start!, day);
  }

  /// 判断日期是否是范围选择结束日期。
  bool isRangeEnd(DateTime day) {
    return _selection.range.end != null &&
        CalendarDateUtils.isSameDay(_selection.range.end!, day);
  }

  /// 选择指定日期。
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
        if (isMultiSelectOutOfSize(normalized)) {
          return false;
        }
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

  /// 判断多选指定日期是否会超出数量上限。
  bool isMultiSelectOutOfSize(DateTime day) {
    if (_selectionMode != CalendarSelectionMode.multi ||
        _maxMultiSelectSize <= 0) {
      return false;
    }
    final normalized = CalendarDateUtils.stripTime(day);
    final existing = _selection.multi.any(
      (item) => CalendarDateUtils.isSameDay(item, normalized),
    );
    return !existing && _selection.multi.length >= _maxMultiSelectSize;
  }

  /// 判断范围选择结束日期是否违反天数限制。
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

  /// 判断指定日期能否作为范围选择结束日期。
  bool canSelectRangeEnd(DateTime day, {int? minRange, int? maxRange}) {
    return rangeSelectionLimitViolation(
          day,
          minRange: minRange,
          maxRange: maxRange,
        ) ==
        null;
  }

  /// 清空当前选择模式下的选择状态。
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

  /// 判断是否可以跳转到上一页。
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

  /// 判断是否可以跳转到下一页。
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

  /// 根据相对页数计算目标页锚点日期。
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

  /// 判断指定月份是否在可显示范围内。
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

  /// 判断包含指定日期的周是否在可显示范围内。
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
