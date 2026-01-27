import 'dart:convert';
import 'package:http/http.dart' as http;

class SCycleService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  /// Mark period started for today
  static Future<void> markPeriodStarted({
    required String userId,
  }) async {
    final url = Uri.parse("$baseUrl/wellness/s-cycle/period-start");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to mark period started");
    }
  }

  /// Save daily mood + symptoms log
  static Future<void> saveDailyLog({
    required String userId,
    required String mood,
    required List<String> symptoms,
    bool periodStarted = false,
  }) async {
    final url = Uri.parse("$baseUrl/wellness/s-cycle/log");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "mood": mood,
        "symptoms": symptoms,
        "periodStarted": periodStarted,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to save log");
    }
  }

  /// Fetch logs history
  static Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final url = Uri.parse("$baseUrl/wellness/s-cycle/history/$userId");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch history");
    }

    final data = jsonDecode(res.body);

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }

  /// Get cycle summary (days until period etc)
  static Future<Map<String, dynamic>> getSummary(String userId) async {
    final url = Uri.parse("$baseUrl/wellness/s-cycle/summary/$userId");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch summary");
    }

    final data = jsonDecode(res.body);

    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }
}
