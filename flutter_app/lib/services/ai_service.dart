import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class AIService {

  static Future<String?> sendMessage(BuildContext context, String message) async {

    try {

      message = message.trim();

      if (message.isEmpty) return null;

      final token = context.read<AuthProvider>().token;

      final url = Uri.parse("${ApiConfig.baseUrl}ai/chat");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "message": message
        }),
      ).timeout(const Duration(seconds: 6)); // ✅ ADDED TIMEOUT

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"];
      }

      return "Hmm something went wrong";

    } catch (e) {

      return "Connection issue. Try again.";

    }

  }

}