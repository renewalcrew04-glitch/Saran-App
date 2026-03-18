import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import '../services/local_notification_service.dart';

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

  /// The conversation currently open in ChatScreen — suppress notifications for it.
  String? currentOpenConversationId;

  int _lastTotalUnread = 0;
  Timer? _bgTimer;

  /// Total unread messages across all non-archived conversations.
  int get totalUnreadCount =>
      _all.where((c) => c.isArchived != true).fold(0, (s, c) => s + c.unreadCount);

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void setShowArchived(bool v) {
    _showArchived = v;
    notifyListeners();
  }

  /// Starts a 30-second background poll for new messages.
  void startBackgroundPolling(String token) {
    _bgTimer?.cancel();
    _bgTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _silentRefresh(token);
    });
  }

  void stopBackgroundPolling() {
    _bgTimer?.cancel();
    _bgTimer = null;
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh(String token) async {
    try {
      final data = await _service.getConversations(token: token);
      final list = (data['conversations'] as List? ?? []);
      final fresh = list
          .whereType<Map<String, dynamic>>()
          .map((e) => ConversationModel.fromJson(e))
          .toList();

      // Detect newly unread conversations to show a local notification
      for (final c in fresh) {
        if (c.isArchived == true) continue;
        if (c.id == currentOpenConversationId) continue;
        final prev = _all.firstWhere((old) => old.id == c.id,
            orElse: () => c.copyWith(unreadCount: 0));
        if (c.unreadCount > prev.unreadCount) {
          final name = c.otherUser?.name ?? 'New message';
          final text = c.lastMessage.isNotEmpty ? c.lastMessage : '📎 Attachment';
          await LocalNotificationService.showMessage(
            id: c.id.hashCode,
            senderName: name,
            body: text,
          );
        }
      }

      _all = fresh;
      _lastTotalUnread = totalUnreadCount;
      notifyListeners();
    } catch (_) {}
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
      _lastTotalUnread = totalUnreadCount;
      startBackgroundPolling(token);
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
      final name = c.otherUser?.name.toLowerCase() ?? "";
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
