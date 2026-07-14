# CalendarView Flutter API

[中文](README.md) | English

This document only covers the calendar SDK APIs published to pub. Demo pages and concrete business styles stay in the repository demo and are not included in the published package.

## Support

If this package helps you, you can support the author with a coffee.

| Alipay | WeChat Pay |
| --- | --- |
| <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_alipay.jpg" width="180" /> | <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_wechat.png" width="180" /> |

## Screenshots

|  |  |  |  |
| --- | --- | --- | --- |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_01.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_02.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_03.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_04.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_05.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_06.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_07.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_08.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_09.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_10.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_11.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_12.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_13.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_14.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_15.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_16.png) |

## Import

```dart
import 'package:calendarview_flutter/calendarview_flutter.dart';
```

## Minimal Usage

```dart
final controller = CalendarController(focusedDay: DateTime.now());

CalendarView(
  controller: controller,
  pageOrientation: CalendarPageOrientation.horizontal,
  onDaySelected: (day) {
    controller.selectDay(day);
  },
)
```

## CalendarController

Constructor parameters:

| Parameter | Type | Description |
| --- | --- | --- |
| `focusedDay` | `DateTime?` | Focused date. Defaults to today |
| `minDate` | `DateTime?` | Minimum visible/selectable date |
| `maxDate` | `DateTime?` | Maximum visible/selectable date |
| `minSelectRange` | `int` | Minimum range-selection length. `-1` means unlimited |
| `maxSelectRange` | `int` | Maximum range-selection length. `-1` means unlimited |
| `maxMultiSelectSize` | `int` | Maximum multi-select count. `-1` means unlimited |
| `markers` | `Map<DateTime, List<CalendarMarker>>` | Date marker data |
| `disabledDates` | `Set<DateTime>` | Fixed disabled dates |
| `disabledDatePredicate` | `CalendarDatePredicate?` | Dynamic disabled-date predicate |

Readable state:

| API | Description |
| --- | --- |
| `focusedDay` | Current focused date |
| `displayMode` | Current month/week mode |
| `selectionMode` | Current single/range/multi selection mode |
| `firstWeekday` | First day of the week |
| `selection` | Full selection state |
| `rangeSelection` | Range selection start/end |
| `selectedRangeDates` | All dates in a completed range |
| `selectedMultiDates` | Sorted multi-selected dates |
| `markers` | Current marker data |
| `monthViewShowMode` | Month view display mode |
| `onlyCurrentMonth` | Whether only current-month dates are shown |
| `interceptBlocked` | Whether built-in demo blocked dates are enabled |
| `minSelectRange` / `maxSelectRange` | Range-selection length limits |
| `maxMultiSelectSize` | Multi-select count limit |
| `minDate` / `maxDate` | Date bounds |
| `calendarRange` | `CalendarBounds(min, max)` |
| `rangeDescription` | Text description of the date bounds |

Configuration methods:

| API | Description |
| --- | --- |
| `setCalendarRange({minDate, maxDate, clampFocusedDay, adjustSelection})` | Set date bounds |
| `setRange(minYear, minMonth, minDay, maxYear, maxMonth, maxDay)` | Android-style date-bound API |
| `setRangeSelectionLimits({minRange, maxRange})` | Set range-selection length limits |
| `setMaxMultiSelectSize(maxSize)` | Set maximum multi-select count |
| `setDisplayMode(mode)` | Set month/week mode |
| `toggleDisplayMode()` | Toggle month/week mode |
| `setWeekStart(weekday)` | Set the first weekday, such as `DateTime.sunday` |
| `setOnlyCurrentMonth(value)` | Set whether only current-month dates are shown |
| `setMonthViewShowMode(mode)` | Set month view display mode |
| `setInterceptBlocked(value)` | Toggle built-in demo blocked dates |
| `setDisabledDatePredicate(predicate)` | Set dynamic disabled-date rules |
| `setSelectionMode(mode)` | Set selection mode |
| `setMarkers(markers)` | Replace date markers |

Navigation and selection:

| API | Description |
| --- | --- |
| `jumpToDay(day)` | Jump to a date |
| `jumpToMonth(month)` | Jump to a month |
| `nextPage()` | Go to the next page |
| `previousPage()` | Go to the previous page |
| `selectDay(day)` | Select a date and return whether it succeeded |
| `clearSelection()` | Clear the current selection mode |
| `isDisabled(day)` | Whether a date is disabled |
| `isSelected(day)` | Whether a date is selected |
| `isRangeStart(day)` | Whether a date is the range start |
| `isRangeEnd(day)` | Whether a date is the range end |
| `isMultiSelectOutOfSize(day)` | Whether multi-select would exceed the limit |
| `rangeSelectionLimitViolation(day)` | Whether a range end violates length limits |
| `canSelectRangeEnd(day)` | Whether a date can be selected as the range end |
| `canNavigateToPreviousPage()` | Whether the previous page is available |
| `canNavigateToNextPage()` | Whether the next page is available |
| `resolvedPageAnchorForRelative(relative)` | Resolve the anchor date for a relative page |
| `canShowMonth(month)` | Whether a month is within the visible range |
| `canShowWeek(anchorDay)` | Whether a week is within the visible range |

## Selection Modes

Single selection:

```dart
controller
  ..setSelectionMode(CalendarSelectionMode.single)
  ..selectDay(DateTime(2026, 7, 14));
```

Range selection:

```dart
controller
  ..setSelectionMode(CalendarSelectionMode.range)
  ..setRangeSelectionLimits(minRange: 2, maxRange: 14);

CalendarView(
  controller: controller,
  pageOrientation: CalendarPageOrientation.horizontal,
  onDaySelected: (day) => controller.selectDay(day),
  onRangeSelected: (range) {
    final start = range.start;
    final end = range.end;
  },
  onSelectOutOfRange: (day, violation) {},
)
```

Multi selection:

```dart
controller
  ..setSelectionMode(CalendarSelectionMode.multi)
  ..setMaxMultiSelectSize(5);

CalendarView(
  controller: controller,
  pageOrientation: CalendarPageOrientation.horizontal,
  onDaySelected: (day) => controller.selectDay(day),
  onMultiSelected: (day, selectedSize, maxSize) {},
  onMultiSelectOutOfSize: (day, maxSize) {},
)
```

## CalendarView

Core month/week calendar view.

| Parameter | Type | Description |
| --- | --- | --- |
| `controller` | `CalendarController` | Calendar state controller |
| `onDaySelected` | `ValueChanged<DateTime>` | Date tap callback |
| `pageOrientation` | `CalendarPageOrientation` | Horizontal or vertical paging |
| `componentBuilder` | `CalendarComponentBuilder?` | Custom calendar UI |
| `onPageChanged` | `ValueChanged<DateTime>?` | Page change callback |
| `onDisplayedHeightChanged` | `ValueChanged<double>?` | Displayed-height change callback |
| `collapsePreviewProgress` | `double?` | Collapse preview progress |
| `previewExpandFromWeek` | `bool` | Preview expansion while dragging from week mode |
| `monthBodyHeightOverride` | `double?` | Month body height override |
| `calendarHeight` | `double` | Row height |
| `weekBarHeight` | `double` | Week bar height |
| `monthHeaderHeight` | `double` | Month header height |
| `handleDaySelection` | `bool` | Whether the view calls `selectDay` internally |
| `onRangeSelected` | `CalendarRangeSelectedCallback?` | Successful range-selection callback |
| `onSelectOutOfRange` | `CalendarRangeLimitViolationCallback?` | Range-limit callback |
| `onMultiSelected` | `CalendarMultiSelectedCallback?` | Successful multi-selection callback |
| `onMultiSelectOutOfSize` | `CalendarMultiSelectOutOfSizeCallback?` | Multi-select overflow callback |

## CalendarInteractiveController

Controls an expandable, collapsible, fullscreen calendar layout.

State:

| API | Description |
| --- | --- |
| `pageOrientation` | Current paging direction |
| `displayMode` | Current month/week mode |
| `collapseProgress` | Collapse progress |
| `isFullScreenExpanded` | Whether fullscreen is expanded |
| `isCollapsed` / `isExpanded` | Whether the calendar is collapsed/expanded |

Methods:

| API | Description |
| --- | --- |
| `setPageOrientation(orientation)` | Set paging direction |
| `togglePageOrientation()` | Toggle paging direction |
| `expand()` | Expand the calendar |
| `collapse()` / `shrink()` | Collapse the calendar |
| `toggleFullScreen()` | Toggle fullscreen |

## CalendarInteractiveView

Calendar plus linked content-list view.

| Parameter | Description |
| --- | --- |
| `controller` | Calendar controller |
| `onDaySelected` | Date tap callback |
| `contentBuilder` | Content builder. Receives `ScrollController` and `ScrollPhysics` |
| `onFocusedDayChanged` | Focused-date change callback |
| `interactionController` | Interaction controller |
| `pageOrientation` | Paging direction override |
| `yearMode` | Disables part of interactions while in year mode |
| `calendarHeight` / `weekBarHeight` / `monthHeaderHeight` | Size settings |
| `componentBuilder` | Custom calendar UI |
| `contentVerticalDragLocked` | Lock vertical drags from being dispatched to the calendar |

## CalendarMonthYearController

Controls the year-view overlay.

| API | Description |
| --- | --- |
| `isYearMode` | Whether year mode is active |
| `visibleYear` | Current visible year |
| `showYearMode()` | Show year mode |
| `hideYearMode()` | Hide year mode |
| `setYearMode(value)` | Set year-mode state |
| `toggleYearMode()` | Toggle year-mode state |

## CalendarMonthYearView

Adds year-view support on top of `CalendarInteractiveView`.

| Parameter | Description |
| --- | --- |
| `controller` | Calendar controller |
| `onDaySelected` | Date tap callback |
| `contentBuilder` | Content builder |
| `onFocusedDayChanged` | Focused-date change callback |
| `onYearModeChanged` | Year-mode state callback |
| `onMonthSelected` | Month selection callback in year view |
| `interactionController` | Interaction controller |
| `monthYearController` | Year-view controller |
| `pageOrientation` | Paging direction |
| `calendarHeight` / `weekBarHeight` / `monthHeaderHeight` | Size settings |
| `componentBuilder` | Custom calendar UI |

## CalendarMonthListView

Continuously scrollable month list view.

| Parameter | Description |
| --- | --- |
| `controller` | Calendar controller |
| `onDaySelected` | Date tap callback |
| `calendarHeight` | Row height |
| `weekBarHeight` | Week bar height |
| `componentBuilder` | Custom calendar UI |
| `onFocusedMonthChanged` | Focused-month change callback |

## CalendarYearModeStyle

Year-view style configuration.

| Field | Description |
| --- | --- |
| `backgroundColor` | Background color |
| `primaryColor` | Primary text color |
| `dayColor` | Month preview day color |
| `outsideMonthDayColor` | Outside-month day color |
| `selectedColor` | Selected background color |
| `selectedTextColor` | Selected text color |
| `dividerColor` | Divider color |
| `inactiveBorderColor` | Inactive border color |
| `disabledMonthBackgroundColor` | Disabled month background color |
| `disabledMonthBorderColor` | Disabled month border color |
| `disabledMonthTextColor` | Disabled month title color |
| `disabledMonthDayColor` | Disabled month day color |
| `disabledMonthOutsideDayColor` | Disabled outside-month day color |
| `headerHeight` | Year-view header height |
| `monthCardRadius` | Month card corner radius |
| `monthNames` | Month names |

Built-in values: `CalendarYearModeStyle.dark`, `CalendarYearModeStyle.vertical`.

## CalendarYearModeLayout

Adds a year-view overlay to a custom page.

| Parameter | Description |
| --- | --- |
| `controller` | `CalendarMonthYearController` |
| `selectedDate` | Current selected date |
| `minDate` / `maxDate` | Selectable month range |
| `style` | Year-view style |
| `onMonthSelected` | Month selection callback |
| `child` | Page content |

## CalendarComponentBuilder

Calendar style extension protocol. The library only provides the protocol and does not include demo styles.

Required implementations:

| API | Description |
| --- | --- |
| `orderedWeekLabels(firstWeekday)` | Return week labels ordered by first weekday |
| `buildWeekBarCell(context, data)` | Build a week-bar cell |
| `buildDayCell(context, data)` | Build a day cell |

Optional overrides:

| API | Description |
| --- | --- |
| `contentPadding` | Horizontal padding for calendar content |
| `weekBarBackgroundColor` | Week bar background color |
| `buildMonthHeader(context, month, height)` | Month header |
| `buildWeekBar(context, data)` | Full week bar |

Example:

```dart
class MyCalendarBuilder extends CalendarComponentBuilder {
  const MyCalendarBuilder();

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(
      const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      firstWeekday,
    );
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text(data.label);
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return Center(child: Text('${data.date.day}'));
  }
}
```

Helper APIs:

| API | Description |
| --- | --- |
| `DefaultCalendarComponentBuilder` | Default basic style |
| `calendarOrderedWeekLabels(labels, firstWeekday)` | Reorder week labels by first weekday |
| `kCalendarHorizontalPadding` | Default horizontal padding |

## Data Models And Callbacks

| API | Description |
| --- | --- |
| `CalendarSelectionMode.single/range/multi` | Selection mode |
| `CalendarDisplayMode.month/week` | Display mode |
| `CalendarPageOrientation.horizontal/vertical` | Paging direction |
| `MonthViewShowMode.allMonth/onlyCurrentMonth/fitMonth` | Month view display mode |
| `CalendarRangeLimitViolation.belowMinRange/aboveMaxRange` | Range-selection violation type |
| `CalendarBounds(min, max)` | Date bounds |
| `CalendarMarker(label, color)` | Date marker |
| `LunarMetadata(lunarText, solarTerm)` | Lunar/solar-term text |
| `DateRangeValue(start, end)` | Range selection value |
| `CalendarSelectionState(single, range, multi)` | Full selection state |
| `CalendarDatePredicate` | Date predicate |
| `CalendarRangeSelectedCallback` | Range selection callback |
| `CalendarRangeLimitViolationCallback` | Range limit callback |
| `CalendarMultiSelectedCallback` | Multi-selection callback |
| `CalendarMultiSelectOutOfSizeCallback` | Multi-select overflow callback |

## Year Overview Sheet

```dart
await showYearOverviewSheet(
  context,
  year: 2026,
  onMonthSelected: (month) {
    controller.jumpToMonth(month);
  },
);
```

## Thanks For Supporting

If this package saved you development time, your support helps keep it maintained.

| Alipay | WeChat Pay |
| --- | --- |
| <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_alipay.jpg" width="180" /> | <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_wechat.png" width="180" /> |
