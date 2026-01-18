import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.auth + '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
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
        ApiConfig.auth + '/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'name': name,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Registration failed');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        ApiConfig.auth + '/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get user');
      }
      throw Exception('Failed to get user');
    }
  }

  Future<String?> _getToken() async {
    // Get token from secure storage or shared preferences
    // Implementation depends on your storage solution
    return null;
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
