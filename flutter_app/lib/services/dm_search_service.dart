import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class DmSearchService {
  /// Search users by name or username for starting a DM.
  /// GET /api/messages/search-users?q=...
  Future<Map<String, dynamic>> searchUsers({
    required String token,
    required String query,
  }) async {
    final url = ApiConfig.getUrl('${ApiConfig.messages}/search-users');
    final res = await ApiClient.dio.get(
      url,
      queryParameters: {"q": query},
      options: Options(
        headers: {"Authorization": "Bearer $token", ...ApiConfig.jsonHeaders()},
      ),
    );

    if (res.data is! Map) {
      return {"success": false, "users": []};
    }
    return (res.data as Map).cast<String, dynamic>();
  }
}
