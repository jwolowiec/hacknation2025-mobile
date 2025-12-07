import 'package:flutter/material.dart';

class Spacing {
  final EdgeInsets screenPadding = const EdgeInsets.all(16);

  const Spacing();
}

class AppColors {
  final MaterialColor primary = const MaterialColor(0xff174281, <int, Color>{
    50: Color(0xffe3e8f0),
    100: Color(0xffb9c6d9),
    200: Color(0xff8ba1c0),
    300: Color(0xff5d7ba7),
    400: Color(0xff3a5e94),
    500: Color(0xff174281),
    600: Color(0xff143c79),
    700: Color(0xff11336e),
    800: Color(0xff0d2b64),
    900: Color(0xff071d51),
  });

  final Color textPrimary = const Color(0xff161e2e);
  final Color textSecondary = const Color(0xff374151);

  final Color appBackground = const Color(0xfff4f5f7);

  AppColors();
}

class AppTheme {
  static double mainBorderRadiusValue = 10;

  static Spacing spacing = const Spacing();
  static AppColors colors = AppColors();
  static TextTheme typography = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    displayMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    displaySmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xff161e2e),
      height: 1.35,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Color(0xff374151),
      height: 1.35,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xff374151),
      height: 1.35,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xff374151),
      height: 1.35,
    ),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 18,
      color: Color(0xff374151),
      height: 1.35,
    ),
  );

  const AppTheme();
}
