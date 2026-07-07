# CalendarView Flutter

这是基于原 Android `CalendarView` 项目新建的 Flutter 版本工程，目录独立，不会修改原仓库。

## 工程位置

新工程位于：

`/Users/mac/AndroidStudioWorkSpace/CalendarView_flutter`

原 Android 工程仍保留在：

`/Users/mac/AndroidStudioWorkSpace/CalendarView_open`

## 已迁移能力

- 月视图与周视图切换
- 单选日期
- 范围选择
- 多选日期
- 日期标记点
- 禁用日期
- 年视图总览并跳转月份

## 当前未迁移

- 农历和节气计算
- Android Demo 中大量定制化 Activity 外观
- 原项目的 Canvas 级别皮肤插件体系
- 网络、列表联动、悬浮窗等非核心日历演示

## 结构说明

- `lib/src/calendar/`
  Flutter 日历核心模型、控制器、日期工具和视图组件。
- `lib/src/features/calendar_demo/`
  演示页面，展示 Flutter 版迁移后的主交互。

## 运行

```bash
cd /Users/mac/AndroidStudioWorkSpace/CalendarView_flutter
flutter pub get
flutter run
```

## 迁移策略

这次不是把 Android 里的所有 Activity 逐页照搬，而是先把最核心、最可复用的日历能力提炼成 Flutter 组件。这样后续如果你要继续补“简约风格”“范围选择页”“多选页”“魅族风格页”等，只需要基于当前控制器和视图继续扩展，不需要推倒重来。
