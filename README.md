# CalendarView Flutter API

中文 | [English](README_EN.md)

本文档只描述发布到 pub 的日历 SDK API。示例页面和具体业务样式仅保留在仓库 demo 中，不属于发布包内容。

## 支持作者

如果这个库对你有帮助，可以请作者喝杯咖啡。


| 支付宝 | 微信 |
| --- | --- |
| <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_alipay.jpg" width="180" /> | <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_wechat.png" width="180" /> |

## 界面截图

|  |  |  |  |
| --- | --- | --- | --- |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_01.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_02.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_03.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_04.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_05.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_06.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_07.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_08.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_09.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_10.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_11.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_12.png) |
| ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_13.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_14.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_15.png) | ![](https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/screenshot_16.png) |

## 导入

```dart
import 'package:calendarview_flutter/calendarview_flutter.dart';
```

## 最小使用

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

构造参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `focusedDay` | `DateTime?` | 当前聚焦日期，默认今天 |
| `minDate` | `DateTime?` | 可显示/可选择的最小日期 |
| `maxDate` | `DateTime?` | 可显示/可选择的最大日期 |
| `minSelectRange` | `int` | 范围选择最小天数，`-1` 表示不限制 |
| `maxSelectRange` | `int` | 范围选择最大天数，`-1` 表示不限制 |
| `maxMultiSelectSize` | `int` | 多选最大数量，`-1` 表示不限制 |
| `markers` | `Map<DateTime, List<CalendarMarker>>` | 日期标记数据 |
| `disabledDates` | `Set<DateTime>` | 固定禁用日期 |
| `disabledDatePredicate` | `CalendarDatePredicate?` | 动态禁用日期判断 |

状态读取：

| API | 说明 |
| --- | --- |
| `focusedDay` | 当前聚焦日期 |
| `displayMode` | 当前月/周模式 |
| `selectionMode` | 当前单选/范围/多选模式 |
| `firstWeekday` | 周起始日 |
| `selection` | 完整选择状态 |
| `rangeSelection` | 范围选择起止值 |
| `selectedRangeDates` | 已完成范围内所有日期 |
| `selectedMultiDates` | 多选日期列表，已排序 |
| `markers` | 当前标记数据 |
| `monthViewShowMode` | 月视图显示模式 |
| `onlyCurrentMonth` | 是否只显示当前月日期 |
| `interceptBlocked` | 是否启用内置演示禁用日期 |
| `minSelectRange` / `maxSelectRange` | 范围选择天数限制 |
| `maxMultiSelectSize` | 多选数量限制 |
| `minDate` / `maxDate` | 日期边界 |
| `calendarRange` | `CalendarBounds(min, max)` |
| `rangeDescription` | 日期边界描述文本 |

配置方法：

| API | 说明 |
| --- | --- |
| `setCalendarRange({minDate, maxDate, clampFocusedDay, adjustSelection})` | 设置日期边界 |
| `setRange(minYear, minMonth, minDay, maxYear, maxMonth, maxDay)` | 原 Android 风格的日期边界设置 |
| `setRangeSelectionLimits({minRange, maxRange})` | 设置范围选择天数限制 |
| `setMaxMultiSelectSize(maxSize)` | 设置多选数量上限 |
| `setDisplayMode(mode)` | 设置月/周模式 |
| `toggleDisplayMode()` | 切换月/周模式 |
| `setWeekStart(weekday)` | 设置周起始日，如 `DateTime.sunday` |
| `setOnlyCurrentMonth(value)` | 设置是否只显示当前月 |
| `setMonthViewShowMode(mode)` | 设置月视图显示模式 |
| `setInterceptBlocked(value)` | 开关内置演示禁用日期 |
| `setDisabledDatePredicate(predicate)` | 设置动态禁用规则 |
| `setSelectionMode(mode)` | 设置选择模式 |
| `setMarkers(markers)` | 替换日期标记 |

跳转与选择：

| API | 说明 |
| --- | --- |
| `jumpToDay(day)` | 跳到指定日期 |
| `jumpToMonth(month)` | 跳到指定月份 |
| `nextPage()` | 下一页 |
| `previousPage()` | 上一页 |
| `selectDay(day)` | 选择日期，返回是否成功 |
| `clearSelection()` | 清空当前模式下的选择 |
| `isDisabled(day)` | 日期是否不可选 |
| `isSelected(day)` | 日期是否选中 |
| `isRangeStart(day)` | 是否范围开始日期 |
| `isRangeEnd(day)` | 是否范围结束日期 |
| `isMultiSelectOutOfSize(day)` | 多选是否超出数量 |
| `rangeSelectionLimitViolation(day)` | 范围选择是否违反天数限制 |
| `canSelectRangeEnd(day)` | 是否可作为范围结束日期 |
| `canNavigateToPreviousPage()` | 是否能向前翻页 |
| `canNavigateToNextPage()` | 是否能向后翻页 |
| `resolvedPageAnchorForRelative(relative)` | 获取相对页锚点日期 |
| `canShowMonth(month)` | 月份是否在可显示范围内 |
| `canShowWeek(anchorDay)` | 周是否在可显示范围内 |

## 选择模式

单选：

```dart
controller
  ..setSelectionMode(CalendarSelectionMode.single)
  ..selectDay(DateTime(2026, 7, 14));
```

范围选择：

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

多选：

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

核心月/周日历视图。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `controller` | `CalendarController` | 日历状态控制器 |
| `onDaySelected` | `ValueChanged<DateTime>` | 日期点击回调 |
| `pageOrientation` | `CalendarPageOrientation` | 横向或纵向分页 |
| `componentBuilder` | `CalendarComponentBuilder?` | 自定义日历 UI |
| `onPageChanged` | `ValueChanged<DateTime>?` | 页面变化回调 |
| `onDisplayedHeightChanged` | `ValueChanged<double>?` | 显示高度变化回调 |
| `collapsePreviewProgress` | `double?` | 折叠预览进度 |
| `previewExpandFromWeek` | `bool` | 周视图拖拽展开预览 |
| `monthBodyHeightOverride` | `double?` | 月主体高度覆盖 |
| `calendarHeight` | `double` | 单行高度 |
| `weekBarHeight` | `double` | 星期栏高度 |
| `monthHeaderHeight` | `double` | 月份头高度 |
| `handleDaySelection` | `bool` | 由视图内部调用 `selectDay` |
| `onRangeSelected` | `CalendarRangeSelectedCallback?` | 范围选择成功回调 |
| `onSelectOutOfRange` | `CalendarRangeLimitViolationCallback?` | 范围选择限制回调 |
| `onMultiSelected` | `CalendarMultiSelectedCallback?` | 多选成功回调 |
| `onMultiSelectOutOfSize` | `CalendarMultiSelectOutOfSizeCallback?` | 多选超限回调 |

## CalendarInteractiveController

控制可展开、折叠、全屏的日历布局。

状态：

| API | 说明 |
| --- | --- |
| `pageOrientation` | 当前分页方向 |
| `displayMode` | 当前月/周模式 |
| `collapseProgress` | 折叠进度 |
| `isFullScreenExpanded` | 是否全屏展开 |
| `isCollapsed` / `isExpanded` | 是否折叠/展开 |

方法：

| API | 说明 |
| --- | --- |
| `setPageOrientation(orientation)` | 设置分页方向 |
| `togglePageOrientation()` | 切换分页方向 |
| `expand()` | 展开日历 |
| `collapse()` / `shrink()` | 收起日历 |
| `toggleFullScreen()` | 切换全屏 |

## CalendarInteractiveView

日历 + 内容列表联动视图。

| 参数 | 说明 |
| --- | --- |
| `controller` | 日历控制器 |
| `onDaySelected` | 日期点击回调 |
| `contentBuilder` | 内容区构建器，接收 `ScrollController` 和 `ScrollPhysics` |
| `onFocusedDayChanged` | 聚焦日期变化 |
| `interactionController` | 交互控制器 |
| `pageOrientation` | 分页方向覆盖 |
| `yearMode` | 年视图模式下禁用部分交互 |
| `calendarHeight` / `weekBarHeight` / `monthHeaderHeight` | 尺寸设置 |
| `componentBuilder` | 自定义日历 UI |
| `contentVerticalDragLocked` | 锁定内容区分发给日历的纵向拖拽 |

## CalendarMonthYearController

控制年视图浮层。

| API | 说明 |
| --- | --- |
| `isYearMode` | 是否在年视图 |
| `visibleYear` | 当前年视图年份 |
| `showYearMode()` | 显示年视图 |
| `hideYearMode()` | 隐藏年视图 |
| `setYearMode(value)` | 设置年视图状态 |
| `toggleYearMode()` | 切换年视图状态 |

## CalendarMonthYearView

在 `CalendarInteractiveView` 之上增加年视图。

| 参数 | 说明 |
| --- | --- |
| `controller` | 日历控制器 |
| `onDaySelected` | 日期点击回调 |
| `contentBuilder` | 内容区构建器 |
| `onFocusedDayChanged` | 聚焦日期变化 |
| `onYearModeChanged` | 年视图状态变化 |
| `onMonthSelected` | 年视图中选择月份 |
| `interactionController` | 交互控制器 |
| `monthYearController` | 年视图控制器 |
| `pageOrientation` | 分页方向 |
| `calendarHeight` / `weekBarHeight` / `monthHeaderHeight` | 尺寸设置 |
| `componentBuilder` | 自定义日历 UI |

## CalendarMonthListView

按月份连续滚动的列表视图。

| 参数 | 说明 |
| --- | --- |
| `controller` | 日历控制器 |
| `onDaySelected` | 日期点击回调 |
| `calendarHeight` | 单行高度 |
| `weekBarHeight` | 星期栏高度 |
| `componentBuilder` | 自定义日历 UI |
| `onFocusedMonthChanged` | 聚焦月份变化 |

## CalendarYearModeStyle

年视图样式配置。

| 字段 | 说明 |
| --- | --- |
| `backgroundColor` | 背景色 |
| `primaryColor` | 主文本色 |
| `dayColor` | 月份预览日期颜色 |
| `outsideMonthDayColor` | 月份外日期颜色 |
| `selectedColor` | 选中背景色 |
| `selectedTextColor` | 选中文本色 |
| `dividerColor` | 分割线颜色 |
| `inactiveBorderColor` | 非激活边框色 |
| `disabledMonthBackgroundColor` | 禁用月份背景色 |
| `disabledMonthBorderColor` | 禁用月份边框色 |
| `disabledMonthTextColor` | 禁用月份标题色 |
| `disabledMonthDayColor` | 禁用月份日期色 |
| `disabledMonthOutsideDayColor` | 禁用月份外日期色 |
| `headerHeight` | 年视图头部高度 |
| `monthCardRadius` | 月份卡片圆角 |
| `monthNames` | 月份名称 |

内置值：`CalendarYearModeStyle.dark`、`CalendarYearModeStyle.vertical`。

## CalendarYearModeLayout

为自定义页面增加年视图覆盖层。

| 参数 | 说明 |
| --- | --- |
| `controller` | `CalendarMonthYearController` |
| `selectedDate` | 当前选中日期 |
| `minDate` / `maxDate` | 可选月份范围 |
| `style` | 年视图样式 |
| `onMonthSelected` | 月份选择回调 |
| `child` | 页面内容 |

## CalendarComponentBuilder

日历样式扩展协议。库层只提供协议，不内置 demo 样式。

需要实现：

| API | 说明 |
| --- | --- |
| `orderedWeekLabels(firstWeekday)` | 按周起始返回星期文本 |
| `buildWeekBarCell(context, data)` | 构建星期栏单元 |
| `buildDayCell(context, data)` | 构建日期单元 |

可覆盖：

| API | 说明 |
| --- | --- |
| `contentPadding` | 日历主体左右内边距 |
| `weekBarBackgroundColor` | 星期栏背景色 |
| `buildMonthHeader(context, month, height)` | 月份头 |
| `buildWeekBar(context, data)` | 完整星期栏 |

示例：

```dart
class MyCalendarBuilder extends CalendarComponentBuilder {
  const MyCalendarBuilder();

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return calendarOrderedWeekLabels(
      const ['日', '一', '二', '三', '四', '五', '六'],
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

辅助 API：

| API | 说明 |
| --- | --- |
| `DefaultCalendarComponentBuilder` | 默认基础样式 |
| `calendarOrderedWeekLabels(labels, firstWeekday)` | 根据周起始重排星期文本 |
| `kCalendarHorizontalPadding` | 默认水平边距 |

## 数据模型与回调

| API | 说明 |
| --- | --- |
| `CalendarSelectionMode.single/range/multi` | 选择模式 |
| `CalendarDisplayMode.month/week` | 显示模式 |
| `CalendarPageOrientation.horizontal/vertical` | 分页方向 |
| `MonthViewShowMode.allMonth/onlyCurrentMonth/fitMonth` | 月视图显示模式 |
| `CalendarRangeLimitViolation.belowMinRange/aboveMaxRange` | 范围选择限制类型 |
| `CalendarBounds(min, max)` | 日期边界 |
| `CalendarMarker(label, color)` | 日期标记 |
| `LunarMetadata(lunarText, solarTerm)` | 农历/节气文本 |
| `DateRangeValue(start, end)` | 范围选择值 |
| `CalendarSelectionState(single, range, multi)` | 完整选择状态 |
| `CalendarDatePredicate` | 日期判断函数 |
| `CalendarRangeSelectedCallback` | 范围选择回调 |
| `CalendarRangeLimitViolationCallback` | 范围选择限制回调 |
| `CalendarMultiSelectedCallback` | 多选回调 |
| `CalendarMultiSelectOutOfSizeCallback` | 多选超限回调 |

## 年概览弹层

```dart
await showYearOverviewSheet(
  context,
  year: 2026,
  onMonthSelected: (month) {
    controller.jumpToMonth(month);
  },
);
```

## 致谢

感谢 [huanghaibin-dev/CalendarView](https://github.com/huanghaibin-dev/CalendarView) 作者提供 Android 版本源码参考。

## 再次感谢支持

如果这个库节省了你的开发时间，欢迎支持作者持续维护。

| 支付宝 | 微信 |
| --- | --- |
| <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_alipay.jpg" width="180" /> | <img src="https://raw.githubusercontent.com/raintang666/BFCalendar/main/screenshots/support_wechat.png" width="180" /> |
