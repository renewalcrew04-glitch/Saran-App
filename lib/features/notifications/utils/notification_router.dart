import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_notification.dart';

class NotificationRouter {
  static void handle(
    BuildContext context,
    AppNotification notification,
  ) {
    switch (notification.type) {
      case "like":
      case "comment":
      case "reply":
      case "repost":
      case "quote":
        if (notification.entityId != null) {
          context.go('/post/${notification.entityId}');
        }
        break;

      case "space_join":
      case "space_reminder":
        if (notification.entityId != null) {
          context.go('/space/${notification.entityId}');
        }
        break;

      case "sos_close":
      case "sos_nearby":
        if (notification.entityId != null) {
          context.go('/sos/${notification.entityId}');
        }
        break;

      default:
        context.go('/notifications');
    }
  }
}
