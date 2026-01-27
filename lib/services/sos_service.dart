import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class SosService {
  static Future<Map<String, dynamic>> sendSOS(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      throw Exception("Not authenticated");
    }

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/sos"),
      headers: {
        "Authorization": "Bearer ${auth.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception("Failed to send SOS");
    }

    return jsonDecode(res.body);
  }

  static Future<void> cancelSOS(
    BuildContext context,
    String sosId,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      throw Exception("Not authenticated");
    }

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/sos/$sosId/cancel"),
      headers: {
        "Authorization": "Bearer ${auth.token}",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to cancel SOS");
    }
  }
}
