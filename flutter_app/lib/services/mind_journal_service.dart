import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/utils/auth_headers.dart';

class MindJournalService {
  static Future<void> saveJournal({
    required String userId,
    required String presentFeel,
    required String stopComparison,
    required String selfCare,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl('mind-journal'));
    final res = await http.post(
      url,
      headers: await authHeaders(),
      body: jsonEncode({
        "userId": userId,
        "presentFeel": presentFeel,
        "stopComparison": stopComparison,
        "selfCare": selfCare,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to save journal");
    }
  }

  static Future<List<Map<String, dynamic>>> getMyJournals(String userId) async {
    final path = 'mind-journal/${Uri.encodeComponent(userId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.get(url, headers: await authHeaders());
    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to fetch journals");
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<void> updateJournal({
    required String journalId,
    required String presentFeel,
    required String stopComparison,
    required String selfCare,
  }) async {
    final path = 'mind-journal/${Uri.encodeComponent(journalId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.put(
      url,
      headers: await authHeaders(),
      body: jsonEncode({
        "presentFeel": presentFeel,
        "stopComparison": stopComparison,
        "selfCare": selfCare,
      }),
    );
    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to update journal");
    }
  }

  static Future<void> deleteJournal(String journalId) async {
    final path = 'mind-journal/${Uri.encodeComponent(journalId)}';
    final url = Uri.parse(ApiConfig.getUrl(path));
    final res = await http.delete(url, headers: await authHeaders());
    if (res.statusCode != 200 && res.statusCode != 204) {
      final msg = _messageFromBody(res.body);
      throw Exception(msg ?? "Failed to delete journal");
    }
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
