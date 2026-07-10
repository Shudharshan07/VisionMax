import 'package:flutter/material.dart';

// Custom ColorScheme extension to add warning and success colors
extension CustomColorScheme on ColorScheme {
  Color get warning =>
      const Color.fromRGBO(241, 196, 15, 1); // Yellow for pending
  Color get success =>
      const Color.fromRGBO(46, 204, 113, 1); // Green for approved
}

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: const Color.fromRGBO(
      30,
      113,
      220,
      1,
    ), // HSL: 18 100% 61% (accent orange)
    onPrimary: const Color.fromRGBO(255, 255, 255, 1), // White for contrast
    secondary: const Color.fromRGBO(13, 13, 13, 1), // HSL: 0 0 5% (dark gray)
    onSecondary: const Color.fromRGBO(
      242,
      242,
      242,
      1,
    ), // HSL: 0 0 95% (light text)
    tertiary: const Color.fromRGBO(
      26,
      26,
      26,
      1,
    ), // HSL: 0 0 10% (medium dark gray)
    onTertiary: const Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    surface: const Color.fromRGBO(13, 13, 13, 1), // HSL: 0 0 0% (black)
    onSurface: const Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    inversePrimary: const Color.fromRGBO(
      179,
      179,
      179,
      1,
    ), // HSL: 0 0 70% (medium gray)
    error: const Color.fromRGBO(231, 76, 60, 1), // Red for rejected status
    onError: const Color.fromRGBO(255, 255, 255, 1),
  ),
  scaffoldBackgroundColor: const Color.fromRGBO(
    20,
    20,
    20,
    1,
  ), // HSL: 0 0 0% (background)
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      color: Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      color: Color.fromRGBO(179, 179, 179, 1), // HSL: 0 0 70%
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      color: Color.fromRGBO(179, 179, 179, 1), // HSL: 0 0 70%
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      color: Color.fromRGBO(179, 179, 179, 1), // HSL: 0 0 70%
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color.fromRGBO(13, 13, 13, 1), // HSL: 0 0 5%
    foregroundColor: const Color.fromRGBO(242, 242, 242, 1), // HSL: 0 0 95%
  ),
  cardTheme: CardThemeData(
    color: const Color.fromRGBO(26, 26, 26, 1), // HSL: 0 0 10%
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color.fromRGBO(0, 80, 203, 1), // Accent orange
    foregroundColor: Color.fromRGBO(255, 255, 255, 1),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromRGBO(30, 113, 220, 1), // Accent blue
      foregroundColor: const Color.fromRGBO(255, 255, 255, 1),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color.fromRGBO(26, 26, 26, 1), // tertiary color
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
  ),
);
