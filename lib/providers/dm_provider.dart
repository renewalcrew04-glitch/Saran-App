import 'package:flutter/material.dart';
import '../services/dm_service.dart';

class DmProvider extends ChangeNotifier {
  final DmService _service = DmService();

  bool _loading = false;
  bool get loading => _loading;

  String? _conversationId;
  String? get conversationId => _conversationId;

  Future<String?> openDm({
    required String token,
    required String otherUid,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final data = await _service.getOrCreateConversation(
        token: token,
        otherUid: otherUid,
      );

      final id = data['conversationId']?.toString();
      _conversationId = id;

      return id;
    } catch (_) {
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
