import 'package:flutter/material.dart';

enum CalendarSelectionMode { single, range, multi }

enum CalendarDisplayMode { month, week }

enum CalendarPageOrientation { horizontal, vertical }

@immutable
class CalendarMarker {
  const CalendarMarker({required this.label, required this.color});

  final String label;
  final Color color;
}

@immutable
class LunarMetadata {
  const LunarMetadata({required this.lunarText, this.solarTerm});

  final String lunarText;
  final String? solarTerm;
}

@immutable
class DateRangeValue {
  const DateRangeValue({this.start, this.end});

  final DateTime? start;
  final DateTime? end;

  bool get isComplete => start != null && end != null;

  DateRangeValue copyWith({
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
  }) {
    return DateRangeValue(
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
    );
  }
}

@immutable
class CalendarSelectionState {
  const CalendarSelectionState({
    this.single,
    this.range = const DateRangeValue(),
    this.multi = const <DateTime>{},
  });

  final DateTime? single;
  final DateRangeValue range;
  final Set<DateTime> multi;

  CalendarSelectionState copyWith({
    DateTime? single,
    bool clearSingle = false,
    DateRangeValue? range,
    Set<DateTime>? multi,
  }) {
    return CalendarSelectionState(
      single: clearSingle ? null : (single ?? this.single),
      range: range ?? this.range,
      multi: multi ?? this.multi,
    );
  }
}
