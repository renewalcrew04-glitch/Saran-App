import 'package:flutter/material.dart';
import '../services/settings_api.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  final SettingsApi _api = SettingsApi();

  Map<String, dynamic> settings = {};
  bool loading = true;

  void setToken(String token) {
    _api.setToken(token);
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    settings = await _api.getNotificationSettings();

    loading = false;
    notifyListeners();
  }

  Future<void> toggle(String key, bool value) async {
    settings[key] = value;
    notifyListeners();

    await _api.updateNotificationSettings({key: value});
  }
}
