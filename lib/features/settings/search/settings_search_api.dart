import 'package:dio/dio.dart';
import '../../../config/api_config.dart';

class SettingsSearchApi {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // backend: GET /search/users?q=
  Future<List<dynamic>> searchUsers(String query) async {
    final res = await _dio.get('/search/users', queryParameters: {"q": query});
    return (res.data["users"] ?? []) as List<dynamic>;
  }
}
