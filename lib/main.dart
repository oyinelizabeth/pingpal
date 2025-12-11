import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PingPalApp());
}

class PingPalApp extends StatelessWidget {
  const PingPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPal',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const LoginPage(),
    );
  }
}
