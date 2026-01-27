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
        'Authorization': 'Bearer $token',
      },
    );
  }

  // -------------------------
  // Explore Posts (All)
  // -------------------------
  Future<List<Post>> getExploreAll({int page = 1, int limit = 30}) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.feed}/explore',
      queryParameters: {'page': page, 'limit': limit},
      options: options,
    );

    if (res.data['success'] == true) {
      final list = (res.data['posts'] as List);
      return list.map((e) => Post.fromJson(e)).toList();
    }
    return [];
  }

  // -------------------------
  // Explore Posts by Type
  // -------------------------
  Future<List<Post>> getExploreByType(
    String type, {
    int page = 1,
    int limit = 30,
  }) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.feed}/explore',
      queryParameters: {'page': page, 'limit': limit, 'type': type},
      options: options,
    );

    if (res.data['success'] == true) {
      final list = (res.data['posts'] as List);
      return list.map((e) => Post.fromJson(e)).toList();
    }
    return [];
  }

  // -------------------------
  // Search People
  // -------------------------
  Future<List<User>> searchPeople(String query) async {
    if (query.trim().isEmpty) return [];

    final options = await _authOptions();
    final res = await _dio.get(
      '${ApiConfig.search}/people',
      queryParameters: {'q': query.trim()},
      options: options,
    );

    if (res.data['success'] == true) {
      final list = (res.data['users'] as List);
      return list.map((e) => User.fromJson(e)).toList();
    }
    return [];
  }

Future<Map<String, dynamic>> followUser(String targetUid) async {
  final options = await _authOptions();
  final res = await _dio.post(
    '/follow/$targetUid',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> unfollowUser(String targetUid) async {
  final options = await _authOptions();
  final res = await _dio.delete(
    '/follow/$targetUid',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> blockUser(String targetUid) async {
  final options = await _authOptions();
  final res = await _dio.post(
    '/block/$targetUid',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> unblockUser(String targetUid) async {
  final options = await _authOptions();
  final res = await _dio.delete(
    '/block/$targetUid',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> savePost(String postId) async {
  final options = await _authOptions();
  final res = await _dio.post(
    '/save/$postId',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> unsavePost(String postId) async {
  final options = await _authOptions();
  final res = await _dio.delete(
    '/save/$postId',
    options: options,
  );
  return res.data;
}

Future<Map<String, dynamic>> reportPost({
  required String postId,
  required String reason,
}) async {
  final options = await _authOptions();
  final res = await _dio.post(
    '/report/post/$postId',
    data: {'reason': reason},
    options: options,
  );
  return res.data;
}

}
