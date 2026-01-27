import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class DmSearchService {
  Future<Map<String, dynamic>> searchUsers({
    required String token,
    required String query,
  }) async {
    final res = await ApiClient.dio.get(
      '${ApiConfig.messages}/search-users',
      queryParameters: {"q": query},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return (res.data as Map).cast<String, dynamic>();
  }
}
