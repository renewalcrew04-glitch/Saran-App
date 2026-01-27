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

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please login again.");
      }

      final response = await _dio.get(
        '${ApiConfig.auth}/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get user');
      }
      throw Exception('Failed to get user');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.auth}/login',
        data: {'email': email, 'password': password},
      );

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.auth}/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'name': name,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException) {
        String errorMessage = 'Registration failed';

        if (e.response != null) {
          errorMessage = e.response?.data['message'] ??
              e.response?.data['error'] ??
              'Registration failed';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage =
              'Connection timeout. Please check if backend server is running.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Cannot connect to server. Please check backend at ${ApiConfig.baseUrl}';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Server response timeout. Please try again.';
        }

        throw Exception(errorMessage);
      }

      throw Exception('Registration failed: ${e.toString()}');
    }
  }
}
