import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CommentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ),
  );

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Options> _options() async {
    final t = await _token();
    return Options(headers: {'Authorization': 'Bearer $t'});
  }

  /// Backend: GET /api/posts/:id/comments
  Future<List<dynamic>> getComments(String postId) async {
    try {
      final res = await _dio.get(
        '/posts/$postId/comments',
        options: await _options(),
      );
      final list = res.data['comments'] as List?;
      if (list == null) return [];
      // Backend returns uid (populated user); widget expects 'user'. Normalize top-level and replies.
      return list.map<dynamic>((c) {
        final map = Map<String, dynamic>.from(c as Map);
        if (map['uid'] != null && map['user'] == null) map['user'] = map['uid'];
        final replies = map['replies'] as List?;
        if (replies != null && replies.isNotEmpty) {
          map['replies'] = replies.map<dynamic>((r) {
            final rm = Map<String, dynamic>.from(r as Map);
            if (rm['uid'] != null && rm['user'] == null) rm['user'] = rm['uid'];
            return rm;
          }).toList();
        }
        return map;
      }).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load comments');
    }
  }

  /// Backend: POST /api/posts/:id/comments. Returns the created comment for optimistic UI.
  Future<Map<String, dynamic>?> addComment(String postId, String text) async {
    try {
      final res = await _dio.post(
        '/posts/$postId/comments',
        data: {'text': text},
        options: await _options(),
      );
      final data = res.data;
      if (data is! Map || data['comment'] == null) return null;
      final c = Map<String, dynamic>.from(data['comment'] as Map);
      // Normalize for CommentTile: _id, user from uid
      c['_id'] = c['_id'] ?? c['id'];
      if (c['uid'] != null && c['user'] == null) c['user'] = c['uid'];
      return c;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add comment');
    }
  }

  /// Backend: POST /api/posts/:id/comments with parentCommentId
  Future<void> replyToComment(String postId, String commentId, String text) async {
    try {
      await _dio.post(
        '/posts/$postId/comments',
        data: {'text': text, 'parentCommentId': commentId},
        options: await _options(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to reply');
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      await _dio.post(
        '/comments/$commentId/like',
        options: await _options(),
      );
    } on DioException catch (_) {
      // Backend may not have comment like route yet; ignore
    }
  }
}
