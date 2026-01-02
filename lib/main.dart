import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pingpal/pages/splash_screen.dart';
import 'package:pingpal/pages/welcome_page.dart';
import 'package:pingpal/services/notification_service.dart';

import 'theme/app_theme.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background notification');
  print(message.notification?.title);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.init();

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
      home: const SplashPage(),
    );
  }
}
