import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class ExploreService {
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

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<List<Post>> getExploreFeed({
    int page = 1,
    int limit = 30,
    String? type,
  }) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.feed}/explore',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null && type.isNotEmpty) 'type': type,
      },
      options: options,
    );

    if (res.data['success'] == true) {
      final list = (res.data['posts'] as List);
      return list.map((e) => Post.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<User>> searchUsers(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];
    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.search}/users',
      queryParameters: {'q': query.trim(), 'limit': limit},
      options: options,
    );
    if (res.data['success'] == true && res.data['users'] != null) {
      final list = res.data['users'] as List;
      return list.map((e) => User.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Post>> searchPosts(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.search}/posts',
      queryParameters: {'q': query.trim(), 'limit': limit},
      options: options,
    );
    if (res.data['success'] == true && res.data['posts'] != null) {
      final list = res.data['posts'] as List;
      return list.map((e) => Post.fromJson(e)).toList();
    }
    return [];
  }

  /// Fetches suggested users to follow (for Explore "Suggestions for you").
  Future<List<User>> getSuggestions({int limit = 10}) async {
    try {
      final options = await _authOptions();
      final res = await _dio.get(
        ApiConfig.getUrl('${ApiConfig.users}/suggestions'),
        queryParameters: {'limit': limit},
        options: options,
      );
      if (res.data['success'] == true && res.data['users'] != null) {
        final list = res.data['users'] as List;
        return list.map((e) => User.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return {'users': <User>[], 'posts': <Post>[]};
    }
    try {
      final options = await _authOptions();
      final res = await _dio.get(
        '${ApiConfig.search}/all',
        queryParameters: {'q': query.trim()},
        options: options,
      );
      if (res.data['success'] == true) {
        final users = (res.data['users'] as List? ?? [])
            .map((e) => User.fromJson(e))
            .toList();
        final posts = (res.data['posts'] as List? ?? [])
            .map((e) => Post.fromJson(e))
            .toList();
        return {'users': users, 'posts': posts};
      }
      return {'users': <User>[], 'posts': <Post>[]};
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 500) {
        throw Exception('Search is temporarily unavailable. Please try again.');
      }
      if (code == 404) {
        throw Exception('Search not available.');
      }
      throw Exception('Search failed. Check your connection.');
    }
  }
}
