import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProfileService {
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

  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final headers = await _getAuthHeaders();

    final response = await _dio.get(
      '${ApiConfig.users}/$userId/followers',
      options: Options(headers: headers),
    );

    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['followers'] ?? []);
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final headers = await _getAuthHeaders();

    final response = await _dio.get(
      '${ApiConfig.users}/$userId/following',
      options: Options(headers: headers),
    );

    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['following'] ?? []);
    }

    return [];
  }

  /// Follow a user by their uid (or id).
  Future<bool> followUser(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.post(
        '${ApiConfig.users}/$userId/follow',
        options: Options(headers: headers),
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Unfollow a user by their uid (or id).
  Future<bool> unfollowUser(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.delete(
        '${ApiConfig.users}/$userId/follow',
        options: Options(headers: headers),
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
