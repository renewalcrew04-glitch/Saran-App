
/// Returns API base URL for mobile platforms (Android / iOS)
/// For local development we use the laptop IP so the phone can reach the server.
String getApiBaseUrl() {

  // LIVE BACKEND (production)
  return "http://13.233.133.213:5000/api/";

}