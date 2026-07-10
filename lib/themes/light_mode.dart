import 'package:flutter/material.dart';
import 'package:visionmax/utils/color_extensions.dart';

// Custom ColorScheme extension to add warning and success colors
extension CustomColorScheme on ColorScheme {
  Color get warning =>
      const Color.fromRGBO(241, 196, 15, 1); // Yellow for pending
  Color get success =>
      const Color.fromRGBO(46, 204, 113, 1); // Green for approved
}

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: const Color.fromRGBO(
      0,
      80,
      203,
      1,
    ), // Orange accent (same as dark mode)
    onPrimary: const Color.fromRGBO(0, 0, 0, 1), // White text on orange
    secondary: const Color.fromRGBO(
      242,
      242,
      242,
      1,
    ), // Very light gray for surfaces
    onSecondary: const Color.fromRGBO(13, 13, 13, 1), // Dark text
    tertiary: const Color.fromRGBO(255, 255, 255, 1), // Pure white for cards
    onTertiary: const Color.fromRGBO(13, 13, 13, 1), // Dark text on cards
    surface: const Color.fromRGBO(230, 230, 230, 1), // White surface
    onSurface: const Color.fromRGBO(13, 13, 13, 1), // Dark text on surface
    inversePrimary: const Color.fromRGBO(
      77,
      77,
      77,
      1,
    ), // Medium gray for secondary elements
    error: const Color.fromRGBO(220, 53, 69, 1), // Red for errors
    onError: const Color.fromRGBO(255, 255, 255, 1),
  ),
  scaffoldBackgroundColor: const Color.fromRGBO(
    242,
    242,
    242,
    1,
  ), // Slightly darker gray background for better card contrast
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(33, 37, 41, 1),
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(33, 37, 41, 1),
    ),
    bodyLarge: TextStyle(fontSize: 18, color: Color.fromRGBO(33, 37, 41, 1)),
    bodyMedium: TextStyle(fontSize: 16, color: Color.fromRGBO(33, 37, 41, 1)),
    labelLarge: TextStyle(
      fontSize: 16,
      color: Color.fromRGBO(108, 117, 125, 1),
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      color: Color.fromRGBO(108, 117, 125, 1),
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      color: Color.fromRGBO(108, 117, 125, 1),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
    foregroundColor: const Color.fromRGBO(13, 13, 13, 1),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: const Color.fromRGBO(255, 255, 255, 1),
    elevation: 2,
    shadowColor: Colors.black.withOpacityValue(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color.fromRGBO(0, 80, 203, 1), // Orange accent
    foregroundColor: Color.fromRGBO(255, 255, 255, 1),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromRGBO(0, 80, 203, 1), // Orange accent
      foregroundColor: const Color.fromRGBO(255, 255, 255, 1),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color.fromRGBO(33, 37, 41, 1),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
  ),
);
