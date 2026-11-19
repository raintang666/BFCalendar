import 'package:calendarview_flutter/calendarview_flutter.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const _CalendarExample());

class _CalendarExample extends StatefulWidget {
  const _CalendarExample();

  @override
  State<_CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<_CalendarExample> {
  final _controller = CalendarController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF1565C0),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: SingleChildScrollView(
            child: CalendarView(
              controller: _controller,
              pageOrientation: CalendarPageOrientation.horizontal,
              onDaySelected: _controller.selectDay,
            ),
          ),
        ),
      ),
    );
  }
}
