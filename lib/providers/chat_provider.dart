import 'dart:async';
import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  bool _loading = false;
  bool get loading => _loading;

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  Timer? _pollTimer;

  // ✅ Typing map
  Map<String, bool> _typingMap = {};
  Map<String, bool> get typingMap => _typingMap;

  Future<void> openConversation({
    required String token,
    required String conversationId,
  }) async {
    await _load(token: token, conversationId: conversationId);

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _load(token: token, conversationId: conversationId, silent: true);
    });
  }

  Future<void> _load({
    required String token,
    required String conversationId,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _loading = true;
        notifyListeners();
      }

      final data = await _service.getConversation(
        token: token,
        conversationId: conversationId,
      );

      // ✅ messages
      final list = (data['messages'] as List? ?? []);
      _messages = list
          .whereType<Map<String, dynamic>>()
          .map((e) => MessageModel.fromJson(e))
          .toList();

      // ✅ typing status
      final convo = data['conversation'];
      if (convo is Map<String, dynamic>) {
        final typing = convo['typing'];
        if (typing is Map) {
          _typingMap = typing.map((k, v) => MapEntry(k.toString(), v == true));
        } else {
          _typingMap = {};
        }
      } else {
        _typingMap = {};
      }
    } catch (_) {
      // ignore
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> sendText({
    required String token,
    required String conversationId,
    required String receiverUid,
    required String text,
  }) async {
    await _service.sendMessage(
      token: token,
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: 'text',
      text: text,
    );
    await _load(token: token, conversationId: conversationId, silent: true);
  }

  Future<void> sendImage({
    required String token,
    required String conversationId,
    required String receiverUid,
    required String imageUrl,
  }) async {
    await _service.sendMessage(
      token: token,
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: 'image',
      imageUrl: imageUrl,
    );
    await _load(token: token, conversationId: conversationId, silent: true);
  }

  Future<void> sendVoice({
    required String token,
    required String conversationId,
    required String receiverUid,
    required String voiceUrl,
  }) async {
    await _service.sendMessage(
      token: token,
      conversationId: conversationId,
      receiverUid: receiverUid,
      type: 'voice',
      voiceUrl: voiceUrl,
    );
    await _load(token: token, conversationId: conversationId, silent: true);
  }

  Future<void> react({
    required String token,
    required String conversationId,
    required String messageId,
    required String reaction,
  }) async {
    await _service.reactToMessage(
      token: token,
      conversationId: conversationId,
      messageId: messageId,
      reaction: reaction,
    );
    await _load(token: token, conversationId: conversationId, silent: true);
  }

  Future<void> markRead({
    required String token,
    required String conversationId,
  }) async {
    await _service.markAsRead(token: token, conversationId: conversationId);
  }

  // ✅ typing update API call
  Future<void> setTyping({
    required String token,
    required String conversationId,
    required bool value,
  }) async {
    await _service.setTyping(
      token: token,
      conversationId: conversationId,
      value: value,
    );
  }

  void disposePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    disposePolling();
    super.dispose();
  }
}
