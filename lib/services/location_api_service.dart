import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationApiService {
  static const String baseUrl = 'http://34.28.189.176/api';

  static Future<void> sendLocation({
    required String pingtrailId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse('$baseUrl/location');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pingtrailId': pingtrailId,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send location');
    }
  }
}
