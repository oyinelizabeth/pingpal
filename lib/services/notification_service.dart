import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Stores notification data in Firestore for in-app notification history
  static Future<void> send({
    required String receiverId,
    required String senderId,
    required String type,
    required String title,
    required String body,
    String? pingtrailId,
    String? invitationId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'pingtrailId': pingtrailId ?? '',
      'invitationId': invitationId ?? '',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Android notification channel configuration for high-priority alerts
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_notification_channel',
    'Default Notifications',
    description: 'General notifications',
    importance: Importance.high,
  );

  // Initialises FCM, local notifications, and token handling
  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await saveToken();

    // Updates Firestore when the FCM token is refreshed
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));

      print('🔄 FCM TOKEN REFRESHED: $newToken');
    });

    // Handles foreground push notifications
    FirebaseMessaging.onMessage.listen(_onMessage);

    // Handles notification tap events
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📲 Notification clicked: ${message.data}');
    });
  }

  // Requests user permission for push notifications
  static Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  // Sets up local notification support on Android
  static Future<void> _initLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  // Displays a local notification when an FCM message is received in foreground
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

  // Saves the current device FCM token to Firestore for push delivery
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
