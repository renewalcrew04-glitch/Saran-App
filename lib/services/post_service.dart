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

  // =========================
  // REPOST
  // =========================
  Future<void> repost(String postId) async {
    final headers = await _getAuthHeaders();
    await _dio.post(
      '${ApiConfig.posts}/$postId/repost',
      options: Options(headers: headers),
    );
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
      '${ApiConfig.baseUrl}/save/$postId',
      options: Options(headers: headers),
    );
    return res.data['saved'] == true;
  }

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

  // =========================
// MUTED CONTENT
// =========================
Future<Map<String, List<String>>> getMutedContent() async {
  final headers = await _getAuthHeaders();
  final res = await _dio.get(
    '${ApiConfig.baseUrl}/content-mute',
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
    '${ApiConfig.baseUrl}/content-mute',
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
