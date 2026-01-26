import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Android emulator localhost
        return 'http://10.0.2.2:3000/api';
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:3000/api';
      } else {
        return 'http://localhost:3000/api';
      }
    } else {
      // Production
      return 'http://13.233.133.213:3000/api';
    }
  }

  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String posts = '/posts';
  static const String feed = '/feed';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String events = '/events';
  static const String sframes = '/sframes';
  static const String search = '/search';
  static const String sos = '/sos';
  static const String wellness = '/wellness';
  static const String upload = '/upload';
  static const String space = '/space';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static void init() {
    // no-op (kept for compatibility)
  }

  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static Map<String, String> jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
