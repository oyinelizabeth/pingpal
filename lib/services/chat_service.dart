import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage_service.dart';

class ChatService {
  static const String baseUrl = 'http://34.28.189.176/api/chat';

  static Future<void> sendMessage({
    required String trailId,
    required String userId,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'trailId': trailId,
        'userId': userId,
        'message': message,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchActiveMessages(String trailId) async {
    final url = Uri.parse('$baseUrl/$trailId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((m) => m as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch active messages');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchArchivedMessages(String trailId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('ping_trails')
        .doc(trailId)
        .collection('chat_archive')
        .orderBy('timestamp', descending: false)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> archiveMessagesToFirestore(String trailId, List<Map<String, dynamic>> messages) async {
    final batch = FirebaseFirestore.instance.batch();
    final archiveCollection = FirebaseFirestore.instance
        .collection('ping_trails')
        .doc(trailId)
        .collection('chat_archive');

    for (var msg in messages) {
      final docRef = archiveCollection.doc(msg['id']);
      batch.set(docRef, msg, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
