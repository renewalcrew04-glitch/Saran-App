import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../models/sframe_model.dart';

class SFrameApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // ✅ Create S-Frame
  Future<SFrame> createSFrame({
    required String mediaType,
    String? mediaUrl,
    String? textContent,
    String? mood,
    int durationHours = 24,
  }) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/sframes', // Maps to backend route
        data: {
          'mediaType': mediaType,
          'mediaUrl': mediaUrl,
          'textContent': textContent,
          'mood': mood,
          'durationHours': durationHours,
        },
        options: options,
      );

      return SFrame.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create S-Frame: $e');
    }
  }

  // Get All S-Frames (Feed)
  Future<List<SFrame>> getSFrames() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/sframes',
        options: options,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SFrame.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Return empty list on error to prevent UI crash
      return [];
    }
  }

  // Mark View
  Future<void> viewSFrame(String id) async {
    try {
      final options = await _getAuthOptions();
      await _dio.post(
        '/sframes/$id/view',
        options: options,
      );
    } catch (e) {
      // Silent fail
    }
  }
}