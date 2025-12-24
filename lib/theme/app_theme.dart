import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color accentBlue = Color(0xFF1565C0);

  // Background colors
  static const Color darkBackground = Color(0xFF0A1929);
  static const Color cardBackground = Color(0xFF1A2332);
  static const Color inputBackground = Color(0xFF1E2936);

  // Text colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF8B99A8);
  static const Color textMuted = Color(0xFF5A6B7D);

  // Border colors
  static const Color borderColor = Color(0xFF1E3A5F);
  static const Color dividerColor = Color(0xFF2D3E50);


  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: "Poppins",
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      surfaceTintColor: darkBackground,
      foregroundColor: textWhite,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textWhite,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBackground,
      hintStyle: TextStyle(
        color: textGray.withOpacity(0.6),
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
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
    dividerColor: dividerColor,
  );
}
