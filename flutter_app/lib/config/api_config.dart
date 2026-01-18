class ApiConfig {
  // Update this with your backend API URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Alternative: Use environment variables or build configs
  // static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');
  
  // API Endpoints
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
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Initialize API config
  static void init() {
    // Add any initialization logic here
  }
  
  // Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
