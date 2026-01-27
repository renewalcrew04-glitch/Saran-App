import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ✅ FIXED: Pointing to the correct config location
import '../../../config/api_config.dart';
import '../../../core/utils/auth_headers.dart';

class SFrameApi {
  static String base = '${ApiConfig.baseUrl}/sframes';

  static Future<List<dynamic>> getActiveFrames() async {
    final res = await http.get(
      Uri.parse(base),
      headers: await authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<String> uploadMedia(File file) async {
    // ✅ FIXED: Using the correct ApiConfig path
    final uri = Uri.parse('${ApiConfig.baseUrl}/sframes/upload');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await authHeaders());
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    return data['url'];
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
    await http.post(
      Uri.parse(base),
      headers: await authHeaders(),
      body: jsonEncode(payload),
    );
  }
}