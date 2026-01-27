import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../core/utils/auth_headers.dart';
import '../models/sframe_model.dart';

class SFrameService {
  static Future<List<SFrame>> loadFrames() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sframes'),
      headers: await authHeaders(),
    );

    final List data = jsonDecode(res.body);
    return data.map((e) => SFrame.fromJson(e)).toList();
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

    final data = jsonDecode(res.body);
    return List<String>.from(data['views'] ?? []);
  }

  static Future<void> sendReply(String frameId, String text) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId/reply'),
      headers: await authHeaders(),
      body: jsonEncode({ "text": text }),
    );
  }
  static Future<List<Map<String, dynamic>>> getSeenUsers(
    String frameId) async {
  final res = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/sframes/$frameId'),
    headers: await authHeaders(),
  );

  final data = jsonDecode(res.body);
  return List<Map<String, dynamic>>.from(data['views'] ?? []);
}
}
