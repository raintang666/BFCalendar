import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom component builder can replace week bar and day cell UI', (
    tester,
  ) async {
    final controller = CalendarController(
      focusedDay: DateTime(2026, 7, 9),
      minDate: DateTime(2026, 1, 1),
      maxDate: DateTime(2026, 12, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            controller: controller,
            pageOrientation: CalendarPageOrientation.horizontal,
            componentBuilder: const _FakeComponentBuilder(),
            onDaySelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WB-A'), findsOneWidget);
    expect(find.text('DAY-9'), findsWidgets);
  });
}

class _FakeComponentBuilder extends CalendarComponentBuilder {
  const _FakeComponentBuilder();

  @override
  List<String> orderedWeekLabels(int firstWeekday) {
    return const ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  }

  @override
  Widget buildWeekBarCell(BuildContext context, CalendarWeekBarCellData data) {
    return Text('WB-${data.label}');
  }

  @override
  Widget buildDayCell(BuildContext context, CalendarDayCellData data) {
    return Center(
      child: Text(
        'DAY-${data.date.day}',
        maxLines: 1,
        overflow: TextOverflow.fade,
      ),
    );
  }
}
