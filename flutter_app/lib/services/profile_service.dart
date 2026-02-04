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

  /// Get user profile by uid (includes isFollowing for current user).
  /// Returns null on error. Returns { 'blocked': true } when backend returns 403 (blocked).
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.get(
        '${ApiConfig.users}/$uid',
        options: Options(headers: headers),
      );
      if (response.data['success'] == true && response.data['user'] != null) {
        return Map<String, dynamic>.from(response.data['user'] as Map);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return {'blocked': true};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns { 'followers': [...], 'restricted': bool }. restricted is true when list is hidden for private account.
  Future<Map<String, dynamic>> getFollowers(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.get(
        '${ApiConfig.users}/$userId/followers',
        options: Options(headers: headers),
      );
      if (response.data['success'] == true) {
        return {
          'followers': List<Map<String, dynamic>>.from(response.data['followers'] ?? []),
          'restricted': response.data['restricted'] == true,
        };
      }
    } catch (_) {}
    return {'followers': <Map<String, dynamic>>[], 'restricted': false};
  }

  /// Returns { 'following': [...], 'restricted': bool }. restricted is true when list is hidden for private account.
  Future<Map<String, dynamic>> getFollowing(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.get(
        '${ApiConfig.users}/$userId/following',
        options: Options(headers: headers),
      );
      if (response.data['success'] == true) {
        return {
          'following': List<Map<String, dynamic>>.from(response.data['following'] ?? []),
          'restricted': response.data['restricted'] == true,
        };
      }
    } catch (_) {}
    return {'following': <Map<String, dynamic>>[], 'restricted': false};
  }

  /// Follow a user by their uid (or id). Returns null on success, error message on failure.
  Future<String?> followUser(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.post(
        '${ApiConfig.users}/$userId/follow',
        options: Options(headers: headers),
      );
      if (response.data['success'] == true) return null;
      return (response.data['message'] ?? 'Follow failed').toString();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'])
          : null;
      return msg?.toString() ?? e.message ?? 'Failed to follow';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Unfollow a user by their uid (or id). Returns null on success, error message on failure.
  Future<String?> unfollowUser(String userId) async {
    final headers = await _getAuthHeaders();
    try {
      final response = await _dio.delete(
        '${ApiConfig.users}/$userId/follow',
        options: Options(headers: headers),
      );
      if (response.data['success'] == true) return null;
      return (response.data['message'] ?? 'Unfollow failed').toString();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'])
          : null;
      return msg?.toString() ?? e.message ?? 'Failed to unfollow';
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
