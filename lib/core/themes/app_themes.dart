import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF4CAF50);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteScaffold = Color(0xFFF8F6F6);
  static const Color black = Color(0xFF191919);
  static const Color blackScaffold = Color(0xFF171212);
  static const Color yellow = Color(0xFFFFF700);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    fontFamily: "Montserrat",
    scaffoldBackgroundColor: whiteScaffold,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: white,
      onSurface: black,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: black,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: black),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF404040)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      labelMedium: TextStyle(fontSize: 12, color: Color(0xFF555555)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    fontFamily: "Montserrat",
    scaffoldBackgroundColor: blackScaffold,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: black,
      onSurface: white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),

      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: white,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: white),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFDDDDDD)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      labelMedium: TextStyle(fontSize: 12, color: Color(0xFFC2C2C2)),
    ),
  );
}
