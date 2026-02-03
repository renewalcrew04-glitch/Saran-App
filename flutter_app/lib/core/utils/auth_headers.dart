import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> authHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final headers = <String, String>{
    "Content-Type": "application/json",
  };
  if (token != null && token.isNotEmpty) {
    headers["Authorization"] = "Bearer $token";
  }
  return headers;
}
