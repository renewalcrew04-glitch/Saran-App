import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  bool _loading = false;
  bool get loading => _loading;

  List<ConversationModel> _all = [];
  List<ConversationModel> get all => _all;

  String _search = "";
  String get search => _search;

  bool _showArchived = false;
  bool get showArchived => _showArchived;

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setShowArchived(bool v) {
    _showArchived = v;
    notifyListeners();
  }

  Future<void> loadConversations({required String token}) async {
    try {
      _loading = true;
      notifyListeners();

      final data = await _service.getConversations(token: token);

      final list = (data['conversations'] as List? ?? []);
      _all = list
          .whereType<Map<String, dynamic>>()
          .map((e) => ConversationModel.fromJson(e))
          .toList();
    } catch (_) {
      _all = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<ConversationModel> get visibleConversations {
    final q = _search.trim().toLowerCase();

    // filter archived or inbox
    final filtered = _all.where((c) {
      if (_showArchived) {
        return c.isArchived == true;
      } else {
        return c.isArchived != true;
      }
    }).where((c) {
      if (q.isEmpty) return true;
      final name = c.otherUser?.name?.toLowerCase() ?? "";
      return name.contains(q);
    }).toList();

    // pinned first
    filtered.sort((a, b) {
      final ap = a.isPinned == true ? 1 : 0;
      final bp = b.isPinned == true ? 1 : 0;

      if (ap != bp) return bp.compareTo(ap); // pinned top

      // latest message top
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });

    return filtered;
  }

  List<ConversationModel> get pinnedConversations =>
      visibleConversations.where((c) => c.isPinned == true).toList();

  List<ConversationModel> get normalConversations =>
      visibleConversations.where((c) => c.isPinned != true).toList();
}
