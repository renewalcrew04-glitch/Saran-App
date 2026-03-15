import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProfileUpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json', ...ApiConfig.jsonHeaders()},
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    return {
      'Authorization': 'Bearer $token',
      ...ApiConfig.jsonHeaders(),
    };
  }

  /// Update current user's avatar. Use [currentUserUid] if your backend only has PUT /users/:uid.
  /// Returns the API response (with [user] if backend returns it) so the UI can update immediately.
  Future<Map<String, dynamic>?> updateAvatar(String avatarUrl, {String? currentUserUid}) async {
    final headers = await _getAuthHeaders();
    final path = currentUserUid != null && currentUserUid.isNotEmpty
        ? '${ApiConfig.users}/$currentUserUid'
        : '${ApiConfig.users}/me';
    final url = ApiConfig.getUrl(path);
    final response = await _dio.put<Map<String, dynamic>>(
      url,
      data: {'avatar': avatarUrl},
      options: Options(headers: headers),
    );
    return response.data;
  }

  /// Update current user's cover. Use [currentUserUid] if your backend only has PUT /users/:uid.
  /// Returns the API response (with [user] if backend returns it) so the UI can update immediately.
  Future<Map<String, dynamic>?> updateCover(String coverUrl, {String? currentUserUid}) async {
    final headers = await _getAuthHeaders();
    final path = currentUserUid != null && currentUserUid.isNotEmpty
        ? '${ApiConfig.users}/$currentUserUid'
        : '${ApiConfig.users}/me';
    final url = ApiConfig.getUrl(path);
    final response = await _dio.put<Map<String, dynamic>>(
      url,
      data: {'coverImage': coverUrl},
      options: Options(headers: headers),
    );
    return response.data;
  }

  /// Update current user's name, bio, and location. Use [currentUserUid] if your backend uses PUT /users/:uid.
  Future<Map<String, dynamic>?> updateProfile({
    required String name,
    required String bio,
    required String location,
    String? currentUserUid,
  }) async {
    final headers = await _getAuthHeaders();
    final path = currentUserUid != null && currentUserUid.isNotEmpty
        ? '${ApiConfig.users}/$currentUserUid'
        : '${ApiConfig.users}/me';
    final url = ApiConfig.getUrl(path);
    final response = await _dio.put<Map<String, dynamic>>(
      url,
      data: {
        'name': name,
        'bio': bio,
        'locationText': location,
      },
      options: Options(headers: headers),
    );
    return response.data;
  }

  /// One-off: set current user gender (PATCH /api/users/me/gender). Use to fix accounts missing gender.
  Future<Map<String, dynamic>?> setMeGender(String gender) async {
    final headers = await _getAuthHeaders();
    final url = ApiConfig.getUrl('${ApiConfig.users}/me/gender');
    final response = await _dio.patch<Map<String, dynamic>>(
      url,
      data: {'gender': gender},
      options: Options(headers: headers),
    );
    return response.data;
  }

  /// Update signup-time user info: name, gender, date of birth, selfie. Use [currentUserUid] if backend uses PUT /users/:uid.
  Future<Map<String, dynamic>?> updateUserInfo({
    String? name,
    String? gender,
    DateTime? dob,
    String? selfieImage,
    String? currentUserUid,
  }) async {
    final headers = await _getAuthHeaders();
    final path = currentUserUid != null && currentUserUid.isNotEmpty
        ? '${ApiConfig.users}/$currentUserUid'
        : '${ApiConfig.users}/me';
    final url = ApiConfig.getUrl(path);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender.isEmpty ? null : gender;
    if (dob != null) data['dob'] = dob.toIso8601String();
    if (selfieImage != null) data['selfieImage'] = selfieImage;
    final response = await _dio.put<Map<String, dynamic>>(
      url,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }
}
