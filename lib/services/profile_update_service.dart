import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProfileUpdateService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ Updated: Update Profile
  Future<void> updateUserProfile(Map<String, dynamic> data, {required String explicitUid}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/$explicitUid');
    final headers = await _getHeaders();

    print("📤 Updating Profile for UID: $explicitUid");
    print("📦 Data: $data");

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print("📥 Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode != 200) {
      final errorMsg = jsonDecode(response.body)['message'] ?? 'Update failed';
      throw Exception(errorMsg);
    }
  }

  // ✅ Updated: Update Avatar
  Future<void> updateAvatar(String avatarUrl, String uid) async {
    await updateUserProfile({'avatar': avatarUrl}, explicitUid: uid);
  }

  // ✅ Updated: Update Cover
  Future<void> updateCover(String coverUrl, String uid) async {
    await updateUserProfile({'coverImage': coverUrl}, explicitUid: uid);
  }
}