import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';

class FeedService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  /// Home Feed
  /// Supports:
  /// - For You (default)
  /// - Following (backend already returns following feed)
  /// - Category filter (Wellness, Career, etc.)
  Future<List<Post>> getHomeFeed({
    int page = 1,
    int limit = 20,
    String? category,
    bool followingOnly = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (category != null && category.isNotEmpty) {
        query['category'] = category;
      }

      if (followingOnly == true) {
        query['followingOnly'] = true;
      }

      final response = await _dio.get(
        ApiConfig.feed + '/home',
        queryParameters: query,
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        final postsJson = response.data['posts'] as List;
        return postsJson.map((json) => Post.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load home feed: ${e.toString()}');
    }
  }

  /// Explore Feed
  Future<List<Post>> getExploreFeed({
    int page = 1,
    int limit = 20,
    String? category,
    String? type,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (category != null && category.isNotEmpty) {
        query['category'] = category;
      }

      if (type != null && type.isNotEmpty) {
        query['type'] = type;
      }

      final response = await _dio.get(
        ApiConfig.feed + '/explore',
        queryParameters: query,
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        final postsJson = response.data['posts'] as List;
        return postsJson.map((json) => Post.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load explore feed: ${e.toString()}');
    }
  }

  /// User Feed
  Future<List<Post>> getUserFeed(
    String uid, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dio.get(
        '${ApiConfig.feed}/user/$uid',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        final postsJson = response.data['posts'] as List;
        return postsJson.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load user feed: ${e.toString()}');
    }
  }
}
