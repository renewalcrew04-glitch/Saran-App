import 'api_config_io.dart' if (dart.library.html) 'api_config_web.dart' as api_env;

class ApiConfig {
  static String get baseUrl => api_env.getApiBaseUrl();

  // Endpoints
  static const String auth = 'auth';
  static const String users = 'users';
  static const String posts = 'posts';
  static const String feed = 'feed';
  static const String notifications = 'notifications';
  static const String messages = 'messages';
  static const String events = 'events';
  static const String sframes = 'sframes';
  static const String search = 'search';
  static const String sos = 'sos';
  static const String wellness = 'wellness';
  static const String upload = 'upload';
  static const String space = 'space';
  
  // ✅ Added these back so Wellness features work
  static const String mindJournal = 'mind-journal'; 
  static const String scycle = 'wellness/s-cycle';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static void init() {
    // no-op (kept for compatibility)
  }

  static String getUrl(String endpoint) {
    final b = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final e = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$b$e';
  }

  /// Base URL for static files (uploads) - no /api suffix.
  static String get mediaBaseUrl {
    final b = baseUrl;
    final i = b.indexOf('/api');
    if (i > 0) return b.substring(0, i);
    return b;
  }

  /// Returns a URL safe for CachedNetworkImage/Image.network, or null if not a network URL.
  /// Rejects local file paths (e.g. /data/user/0/... on Android) so they are not passed to network image widgets.
  static String? networkImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // Local file paths (Android /data/, /storage/; iOS-style paths) must not be treated as relative URLs
    if (path.startsWith('/data/') || path.startsWith('/storage/') || path.startsWith('/sdcard/')) return null;
    if (path.contains('/cache/') && (path.contains('com.') || path.contains('Application/'))) return null;
    if (path.startsWith('/')) return mediaBaseUrl + path; // e.g. /uploads/xxx.jpg
    // Relative path from server e.g. "uploads/xxx.jpg"
    if (path.contains('uploads') || path.startsWith('uploads')) {
      final base = mediaBaseUrl.endsWith('/') ? mediaBaseUrl : '$mediaBaseUrl/';
      return base + (path.startsWith('/') ? path.substring(1) : path);
    }
    // Bare filename from backend (e.g. "1770583615597-944127833.jpg") -> assume uploads/
    if (!path.contains('/') && path.contains('.')) {
      final base = mediaBaseUrl.endsWith('/') ? mediaBaseUrl : '$mediaBaseUrl/';
      return '${base}uploads/$path';
    }
    return null;
  }

  static Map<String, String> jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}