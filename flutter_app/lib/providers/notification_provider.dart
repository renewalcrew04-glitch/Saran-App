import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/notifications/models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? errorMessage;

  int get unreadCount => notifications.where((n) => !n.read).length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await _service.getNotifications();
      notifications = data.map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('[NotificationProvider] load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    await _service.markRead(id);
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] =
          notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }

  /// GROUP BY TYPE + ENTITY
  Map<String, List<AppNotification>> get grouped {
    final map = <String, List<AppNotification>>{};
    for (final n in notifications) {
      final key = "${n.type}_${n.entityId}";
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  /// TIME SECTIONS
  Map<String, List<List<AppNotification>>> get sectioned {
    final now = DateTime.now();
    final sections = {
      "Today": <List<AppNotification>>[],
      "Yesterday": <List<AppNotification>>[],
      "This week": <List<AppNotification>>[],
      "This month": <List<AppNotification>>[],
    };

    for (final group in grouped.values) {
      final date = group.first.createdAt;
      final diff = now.difference(date).inDays;

      if (diff == 0) {
        sections["Today"]!.add(group);
      } else if (diff == 1) {
        sections["Yesterday"]!.add(group);
      } else if (diff <= 7) {
        sections["This week"]!.add(group);
      } else {
        sections["This month"]!.add(group);
      }
    }

    return sections;
  }
}
