import 'dart:convert';
import 'package:http/http.dart' as http;

class MindJournalService {
  static const String baseUrl = "http://10.0.2.2:5000/api";

  static Future<void> saveJournal({
    required String userId,
    required String presentFeel,
    required String stopComparison,
    required String selfCare,
  }) async {
    final url = Uri.parse("$baseUrl/mind-journal");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "presentFeel": presentFeel,
        "stopComparison": stopComparison,
        "selfCare": selfCare,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to save journal");
    }
  }

  static Future<List<Map<String, dynamic>>> getMyJournals(String userId) async {
    final url = Uri.parse("$baseUrl/mind-journal/$userId");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch journals");
    }

    final data = jsonDecode(res.body);

    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }
}
