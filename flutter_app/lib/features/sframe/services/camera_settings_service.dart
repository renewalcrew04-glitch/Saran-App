import 'package:shared_preferences/shared_preferences.dart';

class CameraSettingsService {
  static const _keyDefaultFrontCamera = 'camera_default_front';
  static const _keyToolbarSide = 'camera_toolbar_side'; // 'left' | 'right'
  static const _keyAllowCameraRoll = 'camera_allow_roll';

  static Future<bool> getDefaultFrontCamera() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDefaultFrontCamera) ?? false;
  }

  static Future<void> setDefaultFrontCamera(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDefaultFrontCamera, value);
  }

  static Future<bool> getToolbarOnLeft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyToolbarSide) ?? true; // default left
  }

  static Future<void> setToolbarOnLeft(bool left) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyToolbarSide, left);
  }

  static Future<bool> getAllowCameraRoll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAllowCameraRoll) ?? false;
  }

  static Future<void> setAllowCameraRoll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAllowCameraRoll, value);
  }
}
