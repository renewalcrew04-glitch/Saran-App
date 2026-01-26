import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kDebugMode) {
      // Android emulator
      return 'http://10.0.2.2:3000/api';
    }
    return 'https://your-production-api.com/api';
  }
}
