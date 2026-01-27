import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CommentService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Options> _options() async {
    final t = await _token();
    return Options(headers: {'Authorization': 'Bearer $t'});
  }

  Future<List<dynamic>> getComments(String postId) async {
    final res = await _dio.get(
      '${ApiConfig.baseUrl}/comments/$postId',
      options: await _options(),
    );
    return res.data['comments'];
  }

  Future<void> addComment(String postId, String text) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/comments/$postId',
      data: {'text': text},
      options: await _options(),
    );
  }

  Future<void> replyToComment(String commentId, String text) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/comments/reply/$commentId',
      data: {'text': text},
      options: await _options(),
    );
  }

  Future<void> likeComment(String commentId) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/comments/$commentId/like',
      options: await _options(),
    );
  }
}
