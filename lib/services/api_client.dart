import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: ApiConfig.jsonHeaders(),
    ),
  );

  /// Attach token before calling any API
  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove token on logout
  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }

  /// GET helper
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await dio.get(path);
    return _handle(res);
  }

  /// POST helper
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await dio.post(path, data: body ?? {});
    return _handle(res);
  }

  /// PUT helper
  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await dio.put(path, data: body ?? {});
    return _handle(res);
  }

  /// DELETE helper
  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await dio.delete(path);
    return _handle(res);
  }

  static Map<String, dynamic> _handle(Response res) {
    final data = res.data;

    if (data is Map<String, dynamic>) return data;

    // Sometimes backend returns plain string
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    return {'data': data};
  }
}
