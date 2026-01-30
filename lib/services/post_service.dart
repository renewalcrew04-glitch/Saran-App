import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';

class PostService {
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

  // --- ACTIONS ---

  Future<Map<String, dynamic>> createPost({
    required String type,
    String? text,
    List<String>? media,
    String? category,
    List<String>? hashtags,
    String visibility = 'public',
  }) async {
    final headers = await _getAuthHeaders();
    final response = await _dio.post(
      ApiConfig.posts,
      data: {
        'type': type,
        'text': text ?? '',
        'media': media ?? <String>[],
        'category': category,
        'hashtags': hashtags ?? <String>[],
        'visibility': visibility,
      },
      options: Options(headers: headers),
    );
    return response.data;
  }

  Future<void> quotePost({required String postId, required String text}) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      '${ApiConfig.posts}/$postId/quote',
      data: {'text': text},
      options: Options(headers: headers),
    );
  }

  Future<void> repost(String postId) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      '${ApiConfig.posts}/$postId/repost',
      options: Options(headers: headers),
    );
  }

  Future<bool> likePost(String postId) async {
    final headers = await _getAuthHeaders();
    final response = await _dio.post(
      '${ApiConfig.posts}/$postId/like',
      options: Options(headers: headers),
    );
    return response.data['success'] == true;
  }

  Future<bool> unlikePost(String postId) async {
    final headers = await _getAuthHeaders();
    final response = await _dio.delete(
      '${ApiConfig.posts}/$postId/like',
      options: Options(headers: headers),
    );
    return response.data['success'] == true;
  }

  Future<bool> toggleSave(String postId) async {
    final headers = await _getAuthHeaders();
    final res = await _dio.post(
      '${ApiConfig.baseUrl}/save/$postId',
      options: Options(headers: headers),
    );
    return res.data['saved'] == true;
  }

  Future<bool> toggleHideLikeCount(String postId) async {
    final headers = await _getAuthHeaders();
    final res = await _dio.patch(
      '${ApiConfig.posts}/$postId/hide-like',
      options: Options(headers: headers),
    );
    return res.data['hideLikeCount'] == true;
  }

  Future<void> editPost({required String postId, required String text}) async {
    final headers = await _getAuthHeaders();
    await _dio.patch(
      '${ApiConfig.posts}/$postId/edit',
      data: {'text': text},
      options: Options(headers: headers),
    );
  }

  // --- MISSING METHODS RESTORED ---

  Future<List<dynamic>> getSaveCollections() async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      '${ApiConfig.baseUrl}/save/collections',
      options: Options(headers: headers),
    );
    return res.data['collections'] ?? [];
  }

  Future<void> createSaveCollection(String name) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      '${ApiConfig.baseUrl}/save/collection/create',
      data: {'name': name},
      options: Options(headers: headers),
    );
  }

  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      '${ApiConfig.baseUrl}/hashtags/trending',
      options: Options(headers: headers),
    );
    return List<Map<String, dynamic>>.from(res.data['hashtags']);
  }

  Future<List<Post>> getPostsByHashtag(String tag, {int page = 1}) async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      '${ApiConfig.baseUrl}/hashtags/$tag',
      queryParameters: {'page': page},
      options: Options(headers: headers),
    );

    final list = res.data['posts'] as List;
    return list.map((e) => Post.fromJson(e)).toList();
  }
}