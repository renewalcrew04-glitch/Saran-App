import 'package:flutter/material.dart';
import '../services/settings_api.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  final SettingsApi _api = SettingsApi();

  Map<String, dynamic> settings = {};
  bool loading = true;

  void setToken(String token) {
    _api.setToken(token);
  }

  /// Call when token is missing so UI stops showing loading.
  void clearLoading() {
    loading = false;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      settings = await _api.getNotificationSettings();
    } catch (_) {
      settings = {};
    }
    loading = false;
    notifyListeners();
  }

  Future<void> toggle(String key, bool value) async {
    settings[key] = value;
    notifyListeners();

    await _api.updateNotificationSettings({key: value});
  }
}
