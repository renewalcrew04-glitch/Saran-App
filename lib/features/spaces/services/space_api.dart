import 'package:dio/dio.dart';
import '../../../config/api_config.dart';

class SpaceApi {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: ApiConfig.baseUrl),
  );

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // 🔔 Get reminder status for a specific event
  Future<bool> getReminderStatus(String eventId) async {
    final res = await _dio.get('/event-reminders/$eventId');
    return res.data['enabled'] ?? true;
  }

  // 🔕 Update reminder status
  Future<void> updateReminderStatus(
    String eventId,
    bool enabled,
  ) async {
    await _dio.put(
      '/event-reminders/$eventId',
      data: { "enabled": enabled },
    );
  }
}
