import 'package:calendarview_flutter/src/app.dart';
import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar demo renders main canvas style home', (tester) async {
    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    expect(find.text('月'), findsOneWidget);
    expect(find.text('年'), findsOneWidget);
    expect(find.text('iOS日历'), findsOneWidget);
    expect(find.text('iOS系统垂直日历'), findsOneWidget);
  });

  testWidgets('range entry navigates to range page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('范围选择'));
    await tester.pumpAndSettle();

    expect(find.text('提交'), findsOneWidget);
    expect(find.text('开始日期'), findsOneWidget);
    expect(find.text('结束日期'), findsOneWidget);
    expect(find.text('min range = -1'), findsOneWidget);
    expect(find.text('max range = -1'), findsOneWidget);
    expect(find.byType(CalendarView), findsOneWidget);
  });

  testWidgets('multi select entry navigates to multi page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('多选风格'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.text('Article 01'), findsOneWidget);
  });

  testWidgets('colorful entry navigates to colorful page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('多彩风格'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.text('Colorful 01'), findsOneWidget);
  });

  testWidgets('view pager entry navigates to tabbed pager page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ViewPager风格'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.text('热门'), findsOneWidget);
    expect(find.text('头条'), findsOneWidget);
    expect(find.text('时尚'), findsOneWidget);
    expect(find.text('热门 01'), findsOneWidget);
  });

  testWidgets('demo toggles reusable month year view cleanly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalendarViewFlutterApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsWidgets);
    expect(find.textContaining(RegExp(r'^\d{4}$')), findsWidgets);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(find.text('iOS日历'), findsOneWidget);
  });
}
