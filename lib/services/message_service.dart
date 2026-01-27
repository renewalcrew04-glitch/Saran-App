import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class MessageService {
  // -----------------------------
  // GET ALL CONVERSATIONS
  // GET /messages
  // -----------------------------
  Future<Map<String, dynamic>> getConversations({
    required String token,
  }) async {
    final res = await ApiClient.dio.get(
      ApiConfig.messages,
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return (res.data as Map).cast<String, dynamic>();
  }

  // -----------------------------
  // GET ONE CONVERSATION
  // GET /messages/:conversationId
  // -----------------------------
  Future<Map<String, dynamic>> getConversation({
    required String token,
    required String conversationId,
  }) async {
    final res = await ApiClient.dio.get(
      '${ApiConfig.messages}/$conversationId',
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return (res.data as Map).cast<String, dynamic>();
  }

  // -----------------------------
  // SEND MESSAGE
  // POST /messages/:conversationId/messages
  // body: { receiverUid, type, text?, imageUrl?, voiceUrl? }
  // -----------------------------
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String conversationId,
    required String receiverUid,
    required String type,
    String? text,
    String? imageUrl,
    String? voiceUrl,
  }) async {
    final res = await ApiClient.dio.post(
      '${ApiConfig.messages}/$conversationId/messages',
      data: {
        "receiverUid": receiverUid,
        "type": type,
        "text": text,
        "imageUrl": imageUrl,
        "voiceUrl": voiceUrl,
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return (res.data as Map).cast<String, dynamic>();
  }

  // -----------------------------
  // MARK AS READ
  // PUT /messages/:conversationId/read
  // -----------------------------
  Future<void> markAsRead({
    required String token,
    required String conversationId,
  }) async {
    await ApiClient.dio.put(
      '${ApiConfig.messages}/$conversationId/read',
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // -----------------------------
  // DELETE CONVERSATION
  // DELETE /messages/:conversationId
  // -----------------------------
  Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    await ApiClient.dio.delete(
      '${ApiConfig.messages}/$conversationId',
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // -----------------------------
  // UPDATE FLAGS (pin/mute/archive)
  // PUT /messages/:conversationId
  // body: { pinned?, muted?, archived? }
  // -----------------------------
  Future<void> updateFlags({
    required String token,
    required String conversationId,
    bool? pinned,
    bool? muted,
    bool? archived,
  }) async {
    await ApiClient.dio.put(
      '${ApiConfig.messages}/$conversationId',
      data: {
        if (pinned != null) "pinned": pinned,
        if (muted != null) "muted": muted,
        if (archived != null) "archived": archived,
      },
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // -----------------------------
  // REACT TO MESSAGE (optional)
  // PUT /messages/:conversationId/messages/:messageId/reaction
  // -----------------------------
  Future<void> reactToMessage({
    required String token,
    required String conversationId,
    required String messageId,
    required String reaction,
  }) async {
    await ApiClient.dio.put(
      '${ApiConfig.messages}/$conversationId/messages/$messageId/reaction',
      data: {"reaction": reaction},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // -----------------------------
  // TYPING
  // PUT /messages/:conversationId/typing
  // -----------------------------
  Future<void> setTyping({
    required String token,
    required String conversationId,
    required bool value,
  }) async {
    await ApiClient.dio.put(
      '${ApiConfig.messages}/$conversationId/typing',
      data: {"value": value},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }
}
