import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/utils/auth_headers.dart';

class SCycleService {
  /// Mark period started for today
  static Future<void> markPeriodStarted({
    required String userId,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl('wellness/s-cycle/period-started'));
    final res = await http.post(
      url,
      headers: await authHeaders(),
      body: jsonEncode({"userId": userId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to mark period started");
    }
  }

  /// Save daily mood + symptoms log
  static Future<void> saveDailyLog({
    required String userId,
    required String mood,
    required List<String> symptoms,
    bool periodStarted = false,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl('wellness/s-cycle/log'));
    final res = await http.post(
      url,
      headers: await authHeaders(),
      body: jsonEncode({
        "userId": userId,
        "mood": mood,
        "symptoms": symptoms,
        "periodStarted": periodStarted,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to save log");
    }
  }

  /// Update a log by id
  static Future<void> updateLog({
    required String logId,
    required String mood,
    required List<String> symptoms,
    String note = "",
  }) async {
    final path = 'wellness/s-cycle/log/${Uri.encodeComponent(logId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.put(
      url,
      headers: await authHeaders(),
      body: jsonEncode({
        "mood": mood,
        "symptoms": symptoms,
        "note": note,
      }),
    );
    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to update log");
    }
  }

  /// Delete a log by id
  static Future<void> deleteLog(String logId) async {
    final path = 'wellness/s-cycle/log/${Uri.encodeComponent(logId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.delete(url, headers: await authHeaders());
    if (res.statusCode != 200 && res.statusCode != 204) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to delete log");
    }
  }

  /// Fetch logs history
  static Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final path = 'wellness/s-cycle/history/${Uri.encodeComponent(userId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.get(url, headers: await authHeaders());
    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to fetch history");
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Get cycle summary (days until period etc)
  static Future<Map<String, dynamic>> getSummary(String userId) async {
    final path = 'wellness/s-cycle/summary/${Uri.encodeComponent(userId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.get(url, headers: await authHeaders());
    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to fetch summary");
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  static String? _messageFromBody(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      return m?['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
