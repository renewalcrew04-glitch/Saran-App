import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../core/utils/auth_headers.dart';
import '../models/sframe_model.dart';

class SFrameService {
  static String get _base => ApiConfig.getUrl(ApiConfig.sframes);

  static Future<List<SFrame>> loadFrames() async {
    final res = await http.get(
      Uri.parse(_base),
      headers: await authHeaders(),
    );

    final body = res.body;
    if (body.isEmpty) return [];
    final data = jsonDecode(body);
    if (data is! List) return [];
    return data.map((e) => SFrame.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> markViewed(String frameId) async {
    await http.post(
      Uri.parse('$_base/$frameId/view'),
      headers: await authHeaders(),
    );
  }

  static Future<List<String>> getSeenUserIds(String frameId) async {
    final res = await http.get(
      Uri.parse('$_base/$frameId'),
      headers: await authHeaders(),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    return List<String>.from(data?['views'] ?? []);
  }

  static Future<void> sendReply(String frameId, String text) async {
    await http.post(
      Uri.parse('$_base/$frameId/reply'),
      headers: await authHeaders(),
      body: jsonEncode({'text': text}),
    );
  }

  static Future<List<Map<String, dynamic>>> getSeenUsers(String frameId) async {
    final res = await http.get(
      Uri.parse('$_base/$frameId'),
      headers: await authHeaders(),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final views = data?['views'];
    if (views is! List) return [];
    return views.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> deleteFrame(String frameId) async {
    final id = frameId.trim();
    if (id.isEmpty) throw Exception('Invalid story id');
    final path = _base.endsWith('/') ? '${_base}$id' : '$_base/$id';
    final res = await http.delete(
      Uri.parse(path),
      headers: await authHeaders(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      String msg = res.body;
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        msg = data?['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
