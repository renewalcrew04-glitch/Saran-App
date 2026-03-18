import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class NotificationService {
  Future<List<dynamic>> getNotifications() async {
    final res = await ApiClient.get('/notifications');
    debugPrint('[NotificationService] raw response keys: ${res.keys.toList()}');
    debugPrint('[NotificationService] raw response: $res');
    // Try common key names backends use
    for (final key in ['notifications', 'data', 'results', 'items']) {
      final val = res[key];
      if (val is List) return val;
    }
    // If the response itself is wrapped as a list under 'data' Map
    return [];
  }

  Future<void> markRead(String id) async {
    await ApiClient.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.put('/notifications/read-all');
  }
}
