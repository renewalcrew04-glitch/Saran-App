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

  /// Check if username is available
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    final raw = username.trim().toLowerCase();
    if (raw.isEmpty) {
      return {'available': false, 'valid': false, 'message': 'Username is required'};
    }
    try {
      final response = await _dio.get(
        '${ApiConfig.auth}/username/check',
        queryParameters: {'username': raw},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final msg = data is Map ? data['message'] : null;
      String fallback = 'Could not check username.';
      if (status == 404) {
        fallback = 'Server doesn’t support username check. Restart the backend or try again.';
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        fallback = 'No connection. Check network and try again.';
      }
      return {
        'available': false,
        'valid': false,
        'message': msg?.toString() ?? fallback,
      };
    }
  }

  /// Get suggested usernames when base is taken
  Future<List<String>> getUsernameSuggestions(String username) async {
    final raw = username.trim().toLowerCase();
    if (raw.isEmpty) return [];
    try {
      final response = await _dio.get(
        '${ApiConfig.auth}/username/suggestions',
        queryParameters: {'username': raw},
      );
      final data = response.data;
      if (data is! Map) return [];
      // Backend can return { suggestions: [...] } or { data: { suggestions: [...] } }
      List<dynamic>? list = data['suggestions'] is List ? data['suggestions'] as List<dynamic> : null;
      if (list == null && data['data'] is Map) {
        final inner = data['data'] as Map;
        list = inner['suggestions'] is List ? inner['suggestions'] as List<dynamic> : null;
      }
      if (list == null) return [];
      return list.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    } on DioException catch (_) {
      return [];
    }
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