import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:pingpal/pages/welcome_page.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PingPalApp());
}

class PingPalApp extends StatelessWidget {
  const PingPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPal',
      debugShowCheckedModeBanner: false,

          theme: AppTheme.darkTheme,

      home: const WelcomePage(),
    );
  }
}
