import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPink = Color(0xFFFF4FA2);
  static const Color accentPurple = Color(0xFFB24FC3);
  static const Color softPink = Color(0xFFFFD1E8);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6E6E6E);
  static const Color lightBackground = Color(0xFFF8F9FA);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryPink,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: "Poppins",
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      foregroundColor: textBlack,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textBlack,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(
        color: textGray.withOpacity(0.6),
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
  );
}
