import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
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

  // =========================
  // AUTH
  // =========================
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

  // =========================
  // LIKE / UNLIKE
  // =========================
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

  // =========================
  // CREATE POST
  // =========================
  Future<Map<String, dynamic>> createPost({
    required String type,
    String? text,
    List<String>? media,
    String? category,
    List<String>? hashtags,
    String visibility = 'public',
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConfig.getUrl(ApiConfig.posts));
    final body = jsonEncode({
      'type': type,
      'text': text ?? '',
      'media': media ?? <String>[],
      'category': category,
      'hashtags': hashtags ?? <String>[],
      'visibility': visibility,
    });
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    final data = response.body.isNotEmpty
        ? (jsonDecode(response.body) as Map<String, dynamic>)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    final message = data['message']?.toString() ?? 'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  // =========================
  // REPOST
  // =========================
  Future<void> repost(String postId) async {
    try {
      final headers = await _getAuthHeaders();
      await _dio.post(
        '${ApiConfig.posts}/$postId/repost',
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'])
          : null;
      throw Exception(message?.toString() ?? 'Failed to repost');
    }
  }

  /// Undo repost. Throws on failure.
  Future<void> undoRepost(String postId) async {
    try {
      final headers = await _getAuthHeaders();
      await _dio.delete(
        '${ApiConfig.posts}/$postId/repost',
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'])
          : null;
      throw Exception(message?.toString() ?? 'Failed to undo repost');
    }
  }

  // =========================
  // QUOTE REPOST
  // =========================
  Future<void> quotePost({
    required String postId,
    required String text,
  }) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      '${ApiConfig.posts}/$postId/quote',
      data: {'text': text},
      options: Options(headers: headers),
    );
  }

  // =========================
  // SAVE COLLECTIONS
  // =========================
  Future<bool> toggleSave(String postId) async {
    final headers = await _getAuthHeaders();
    final res = await _dio.post(
      ApiConfig.getUrl('save/$postId'),
      options: Options(headers: headers),
    );
    return res.data['saved'] == true;
  }

  Future<List<dynamic>> getSaveCollections() async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      ApiConfig.getUrl('save/collections'),
      options: Options(headers: headers),
    );
    return res.data['collections'] ?? [];
  }

  Future<void> createSaveCollection(String name) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      ApiConfig.getUrl('save/collection/create'),
      data: {'name': name},
      options: Options(headers: headers),
    );
  }

  // =========================
// MUTED CONTENT
// =========================
Future<Map<String, List<String>>> getMutedContent() async {
  final headers = await _getAuthHeaders();
  final res = await _dio.get(
    ApiConfig.getUrl('content-mute'),
    options: Options(headers: headers),
  );

  return {
    'words': List<String>.from(res.data['mutedWords'] ?? []),
    'hashtags': List<String>.from(res.data['mutedHashtags'] ?? []),
  };
}

Future<void> updateMutedContent({
  required List<String> words,
  required List<String> hashtags,
}) async {
  final headers = await _getAuthHeaders();
  await _dio.put(
    ApiConfig.getUrl('content-mute'),
    data: {
      'mutedWords': words,
      'mutedHashtags': hashtags,
    },
    options: Options(headers: headers),
  );
}

  // =========================
  // EDIT POST
  // =========================
  
// Edit post (text only)
Future<void> editPost({
  required String postId,
  required String text,
}) async {
  final headers = await _getAuthHeaders();
  await _dio.patch(
    '${ApiConfig.posts}/$postId/edit',
    data: {'text': text},
    options: Options(headers: headers),
  );
}

  // =========================
  // HIDE LIKE COUNT
  // =========================
// Toggle hide like count
Future<bool> toggleHideLikeCount(String postId) async {
  final headers = await _getAuthHeaders();
  final res = await _dio.patch(
    '${ApiConfig.posts}/$postId/hide-like',
    options: Options(headers: headers),
  );
  return res.data['hideLikeCount'] == true;
}

  // =========================
  // HASHTAGS
  // =========================
  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      ApiConfig.getUrl('hashtags/trending'),
      options: Options(headers: headers),
    );
    return List<Map<String, dynamic>>.from(res.data['hashtags']);
  }

  Future<List<Post>> getPostsByHashtag(String tag, {int page = 1}) async {
    final headers = await _getAuthHeaders();
    final res = await _dio.get(
      ApiConfig.getUrl('hashtags/$tag'),
      queryParameters: {'page': page},
      options: Options(headers: headers),
    );

    final list = res.data['posts'] as List;
    return list.map((e) => Post.fromJson(e)).toList();
  }
}
