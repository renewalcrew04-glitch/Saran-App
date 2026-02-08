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

    final uri = Uri.parse(ApiConfig.getUrl(ApiConfig.sos));
    final res = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      final msg = _messageFromBody(res.body) ?? "Failed to send SOS";
      // When backend says "already active", it includes sosId so UI can show Cancel
      if (res.statusCode == 400) {
        try {
          final map = jsonDecode(res.body) as Map<String, dynamic>?;
          final id = map?["sosId"]?.toString();
          if (id != null && id.isNotEmpty && (msg.toLowerCase().contains("already active"))) {
            throw Exception("ALREADY_ACTIVE:$id");
          }
        } catch (e) {
          if (e is Exception && e.toString().contains("ALREADY_ACTIVE:")) rethrow;
        }
      }
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    if (data == null) throw Exception("Invalid response");
    // Ensure sosId is a string for the provider
    final sosId = data["sosId"]?.toString();
    if (sosId == null || sosId.isEmpty) throw Exception("No SOS ID in response");
    return {...data, "sosId": sosId};
  }

  static Future<void> cancelSOS(String? token, String sosId) async {
    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated");
    }

    final uri = Uri.parse("${ApiConfig.getUrl(ApiConfig.sos)}/$sosId/cancel");
    final res = await http.put(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      final msg = _messageFromBody(res.body) ?? "Failed to cancel SOS";
      throw Exception(msg);
    }
  }

  static String? _messageFromBody(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      final msg = map?["message"]?.toString();
      return msg?.isNotEmpty == true ? msg : null;
    } catch (_) {
      return null;
    }
  }
}
