import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';

class UploadService {
  final AuthService _authService = AuthService();

  /// ✅ Main uploader (used by Chat)
  Future<String> uploadSingle({
    required String token,
    required File file,
  }) async {
    final uri = Uri.parse(ApiConfig.getUrl('${ApiConfig.upload}/single'));

    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    final data = jsonDecode(res.body);

    if (res.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Upload failed');
    }

    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception("Upload URL missing");
    }

    return url;
  }

  /// ✅ Compatibility method (used by Profile screens)
  /// Existing code calls: uploadMedia(picked.path)
  Future<String> uploadMedia(String path) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    return uploadSingle(
      token: token,
      file: File(path),
    );
  }
}
