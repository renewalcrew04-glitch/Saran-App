import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class SosService {
  static Future<Map<String, dynamic>> sendSOS(
    String? token,
    Map<String, dynamic> payload,
  ) async {
    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated");
    }

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/sos"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception("Failed to send SOS");
    }

    return jsonDecode(res.body);
  }

  static Future<void> cancelSOS(String? token, String sosId) async {
    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated");
    }

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/sos/$sosId/cancel"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to cancel SOS");
    }
  }
}
