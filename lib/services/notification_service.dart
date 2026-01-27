import 'package:dio/dio.dart';
import '../../../config/api_config.dart';

class NotificationService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return res.data['notifications'];
  }

  Future<void> markRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.put('/notifications/read-all');
  }
}
