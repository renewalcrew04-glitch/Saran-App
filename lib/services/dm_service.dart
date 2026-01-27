import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class DmService {
  Future<Map<String, dynamic>> getOrCreateConversation({
    required String token,
    required String otherUid,
  }) async {
    final res = await ApiClient.dio.post(
      '${ApiConfig.messages}/dm',
      data: {"otherUid": otherUid},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return (res.data as Map).cast<String, dynamic>();
  }
}
