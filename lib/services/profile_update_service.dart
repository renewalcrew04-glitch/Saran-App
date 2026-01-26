import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProfileUpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _getToken();
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> updateAvatar(String avatarUrl) async {
    final headers = await _getAuthHeaders();
    await _dio.put(
      '${ApiConfig.users}/me',
      data: {'avatar': avatarUrl},
      options: Options(headers: headers),
    );
  }

  Future<void> updateCover(String coverUrl) async {
    final headers = await _getAuthHeaders();
    await _dio.put(
      '${ApiConfig.users}/me',
      data: {'coverImage': coverUrl},
      options: Options(headers: headers),
    );
  }
}
