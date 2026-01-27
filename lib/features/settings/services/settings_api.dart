import 'package:dio/dio.dart';
import '../../../config/api_config.dart';

class SettingsApi {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // =========================
  // PRIVACY
  // =========================
  Future<void> updatePrivacy({required String uid, required bool isPrivate}) async {
  await _dio.put('/users/$uid', data: {"isPrivate": isPrivate});
}

  // =========================
  // DM + COMMENTS (FIXED)
  // =========================
  Future<void> updateMessagingSettings({
    String? dmSettings,
    String? commentSettings,
  }) async {
    final data = <String, dynamic>{};

    if (dmSettings != null) data["dmSettings"] = dmSettings;
    if (commentSettings != null) data["commentSettings"] = commentSettings;

    if (data.isEmpty) return;

    await _dio.put('/settings/messaging', data: data);
  }

  // =========================
  // CLOSE FRIENDS
  // =========================
  Future<List<dynamic>> getCloseFriends() async {
    final res = await _dio.get('/close-friends');
    return (res.data["closeFriends"] ?? []) as List<dynamic>;
  }

  Future<void> addCloseFriend(String uid) async {
    await _dio.post('/close-friends/$uid');
  }

  Future<void> removeCloseFriend(String uid) async {
    await _dio.delete('/close-friends/$uid');
  }

  Future<List<dynamic>> searchUsers(String query) async {
  final res = await _dio.get('/search/users', queryParameters: {"q": query});
  return (res.data["users"] ?? []) as List<dynamic>;
  }

  Future<List<dynamic>> getBlockedUsers() async {
  final res = await _dio.get('/block');
  return (res.data["blocked"] ?? []) as List<dynamic>;
  }

  // =========================
  // MUTED
  // =========================
  Future<List<dynamic>> getMuted() async {
    final res = await _dio.get('/mute');
    return (res.data["muted"] ?? []) as List<dynamic>;
  }

  Future<void> muteUser(String uid) async {
    await _dio.post('/mute/$uid');
  }

  Future<void> unmuteUser(String uid) async {
    await _dio.delete('/mute/$uid');
  }
  
  // =========================
// NOTIFICATION SETTINGS
// =========================
Future<Map<String, dynamic>> getNotificationSettings() async {
  final res = await _dio.get('/settings/notifications');
  return res.data['notificationSettings'];
}

Future<void> updateNotificationSettings(
    Map<String, dynamic> data) async {
  await _dio.put('/settings/notifications', data: data);
}

  // =========================
  // DELETE ACCOUNT (FIXED)
  // =========================
  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }

  // Block
Future<void> blockUser(String uid) async {
  await _dio.post('/block/$uid');
}

Future<void> unblockUser(String uid) async {
  await _dio.delete('/block/$uid');
}

// Report
Future<void> reportUser({required String uid, required String reason}) async {
  await _dio.post('/report/user/$uid', data: {"reason": reason});
}

}
