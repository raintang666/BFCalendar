import 'package:flutter/material.dart';

import 'theme.dart';
import 'features/calendar_demo/calendar_demo_page.dart';

class CalendarViewFlutterApp extends StatelessWidget {
  const CalendarViewFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalendarView Flutter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CalendarDemoPage(),
    );
  }
}
