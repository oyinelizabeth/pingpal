import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPink = Color(0xFFFF4FA2);
  static const Color softPink = Color(0xFFFFD1E8);
  static const Color textBlack = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6E6E6E);

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
  );
}
