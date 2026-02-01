import 'api_config_constants.dart';

/// Base URL for API. Always uses live backend (no localhost).
String getApiBaseUrl() {
  return kProductionApiUrl;
}
