import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationApiService {
  // Base URL for the location microservice hosted on Google Cloud
  static const String baseUrl = 'http://34.28.189.176/api/location';

  // Sends the user’s current location to the backend for caching and distribution
  static Future<void> sendLocation({
    required String pingtrailId,
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
        'pingtrailId': pingtrailId,
        'userId': userId,
        'latitude': lat,
        'longitude': lng,
        'networkType': networkType,
      }),

    );

    // Throws an error if the backend update fails
    if (response.statusCode != 200) {
      throw Exception('Failed to send location');
    }
  }

  // Retrieves cached live locations for all participants in a Pingtrail
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
