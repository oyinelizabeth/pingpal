import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> send({
    required String receiverId,
    required String senderId,
    required String type,
    required String title,
    required String body,
    String? pingtrailId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'pingtrailId': pingtrailId ?? '',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel',
    'Default Notifications',
    description: 'General notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await saveToken();

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));

      print('🔄 FCM TOKEN REFRESHED: $newToken');
    });

    // Foreground notifications
    FirebaseMessaging.onMessage.listen(_onMessage);

    // Notification click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📲 Notification clicked: ${message.data}');
    });
  }

  static Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  static void _onMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _notifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_notification_channel',
          'Default Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> saveToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      print('📱 FCM TOKEN: $token');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

}
