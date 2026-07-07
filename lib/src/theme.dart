import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const bgColor = Color(0xFFF7F6FE);
  const textColor = Color(0xFF333333);

  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bgColor,
    colorScheme: const ColorScheme.light(
      primary: Colors.white,
      secondary: Color(0xFF009988),
      surface: Colors.white,
    ),
  );

  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
      bodyMedium: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
      bodySmall: const TextStyle(fontSize: 10, color: Color(0xFFCFCFCF)),
    ),
  );
}
