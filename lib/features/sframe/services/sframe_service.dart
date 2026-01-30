import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../core/utils/auth_headers.dart';
import '../models/sframe_model.dart';

class SFrameService {
  // ✅ Renamed to 'getSFrames' to match your StoriesRow widget
  static Future<List<SFrame>> getSFrames() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sframes'),
      headers: await authHeaders(),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => SFrame.fromJson(e)).toList();
    }
    return [];
  }

  // ✅ ADDED THIS MISSING METHOD
  static Future<void> createSFrame({
    required String mediaType,
    String? mediaUrl,
    String? textContent,
    String? mood,
    int durationHours = 24,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sframes'),
      headers: await authHeaders(),
      body: jsonEncode({
        "mediaType": mediaType,
        "mediaUrl": mediaUrl,
        "textContent": textContent,
        "mood": mood,
        "durationHours": durationHours,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create S-Frame: ${res.body}');
    }
  }

  static Future<void> markViewed(String frameId) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId/view'),
      headers: await authHeaders(),
    );
  }

  /// Returns list of userIds who viewed the frame
  static Future<List<String>> getSeenUserIds(String frameId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId'),
      headers: await authHeaders(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['views'] is List) {
        // Handle both populated objects and raw IDs
        return (data['views'] as List).map((v) {
          if (v is Map) return v['_id'].toString();
          return v.toString();
        }).toList();
      }
    }
    return [];
  }

  static Future<void> sendReply(String frameId, String text) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId/reply'),
      headers: await authHeaders(),
      body: jsonEncode({ "text": text }),
    );
  }

  static Future<List<Map<String, dynamic>>> getSeenUsers(String frameId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId'),
      headers: await authHeaders(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['views'] ?? []);
    }
    return [];
  }
}