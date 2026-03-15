import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class AIService {

  /// [language] e.g. "en_US" or display name "English" – backend uses it so AI replies in that language.
  static Future<String?> sendMessage(
    BuildContext context,
    String message, {
    String? language,
  }) async {
    try {
      message = message.trim();
      if (message.isEmpty) return null;

      final token = context.read<AuthProvider>().token;
      final url = Uri.parse("${ApiConfig.baseUrl}ai/chat");

      final body = <String, dynamic>{"message": message};
      if (language != null && language.trim().isNotEmpty) {
        body["language"] = language.trim();
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"];
        if (reply != null && reply.toString().isNotEmpty) {
          return reply.toString();
        }
        return "Something went wrong.";
      }

      String serverMessage = "Something went wrong.";
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data["message"] != null) {
          serverMessage = data["message"].toString();
        }
      } catch (_) {}
      return serverMessage;

    } catch (e) {
      return "Connection issue. Check network and try again.";
    }

  }

}