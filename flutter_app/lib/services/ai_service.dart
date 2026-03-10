import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class AIService {

  static Future<String?> sendMessage(BuildContext context, String message) async {

    try {

      final token = context.read<AuthProvider>().token;

      final url = Uri.parse("${ApiConfig.baseUrl}ai/chat");

      // DEBUG LOGS
      print("API BASE URL: ${ApiConfig.baseUrl}");
      print("REQUEST URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "message": message,
        }),
      );

      print("AI STATUS: ${response.statusCode}");
      print("AI BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"];
      }

      return "AI error";

    } catch (e) {

      print("AI Exception: $e");
      return "Connection error";

    }

  }

}