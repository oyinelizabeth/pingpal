import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
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
}
