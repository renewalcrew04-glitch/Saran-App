import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _dio.options.headers.remove('Authorization');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 🔹 GET CURRENT USER
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();

    final response = await _dio.get(
      '${ApiConfig.auth}/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// 🔹 LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '${ApiConfig.auth}/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// 🔹 REGISTER
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String name,
    String gender,
    String dob,
    String selfieImage,
  ) async {
    final response = await _dio.post(
      '${ApiConfig.auth}/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
        'gender': gender,
        'dob': dob,
        'selfieImage': selfieImage,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}