import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationApiService {
  static const String baseUrl = 'http://34.28.189.176/api/location';

  static Future<void> sendLocation({
    required String userId,
    required double lat,
    required double lng,
    required String networkType,
  }) async {
    final url = Uri.parse('$baseUrl/update');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'latitude': lat,
        'longitude': lng,
        'networkType': networkType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send location');
    }
  }

  static Future<List<dynamic>> getTrailLocations(String trailId) async {
    final url = Uri.parse('$baseUrl/trail/$trailId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trail locations');
    }
  }
}
