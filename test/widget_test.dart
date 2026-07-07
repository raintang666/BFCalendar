import 'package:calendarview_flutter/src/app.dart';
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
  });
}
