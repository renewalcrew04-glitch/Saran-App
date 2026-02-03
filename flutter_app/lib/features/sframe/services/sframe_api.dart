import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ✅ FIXED: Pointing to the correct config location
import '../../../config/api_config.dart';
import '../../../core/utils/auth_headers.dart';

class SFrameApi {
  static String get base => ApiConfig.getUrl(ApiConfig.sframes);

  static Future<List<dynamic>> getActiveFrames() async {
    final res = await http.get(
      Uri.parse(base),
      headers: await authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<String?> uploadMedia(File file) async {
    final uri = Uri.parse(ApiConfig.getUrl('${ApiConfig.sframes}/upload'));

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await authHeaders());
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
    final data = jsonDecode(body) as Map<String, dynamic>?;
    if (data == null) return null;
    final url = data['url'] ?? data['fileUrl'] ?? data['path'];
    return url is String ? url : null;
  }

  static Future<void> viewFrame(String frameId) async {
    await http.post(
      Uri.parse('$base/$frameId/view'),
      headers: await authHeaders(),
    );
  }

  static Future<void> replyToFrame(String frameId, String text) async {
    await http.post(
      Uri.parse('$base/$frameId/reply'),
      headers: await authHeaders(),
      body: jsonEncode({ "text": text }),
    );
  }

  static Future<void> createFrame(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(base),
      headers: await authHeaders(),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = (jsonDecode(res.body) as Map<String, dynamic>?)?['message'] ?? res.body;
      throw Exception('Failed to create story: $msg');
    }
  }
}