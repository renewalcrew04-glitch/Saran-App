import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../features/notifications/utils/notification_router.dart';
import '../../features/notifications/models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final sections = provider.sectioned;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
      ),
      body: sections.values.every((e) => e.isEmpty)
          ? const Center(child: Text("No notifications"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: sections.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) => _Section(
                        title: entry.key,
                        groups: entry.value,
                        onTap: provider.markRead,
                      ))
                  .toList(),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<List<AppNotification>> groups;
  final Function(String) onTap;

  const _Section({
    required this.title,
    required this.groups,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...groups.map((group) => _NotificationTile(
              group: group,
              onTap: onTap,
            )),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final List<AppNotification> group;
  final Function(String) onTap;

  const _NotificationTile({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final count = group.length;
    final unread = group.any((n) => !n.read);

    return Card(
      elevation: unread ? 2 : 0,
      child: ListTile(
        leading: unread
            ? const Icon(Icons.circle, size: 8, color: Colors.blue)
            : null,
        title: Text(_title(first.type, count)),
        subtitle: Text(
          first.createdAt.toLocal().toString(),
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
  for (final n in group) {
    onTap(n.id); // mark read
  }

  NotificationRouter.handle(context, group.first);
},
      ),
    );
  }

  String _title(String type, int count) {
    switch (type) {
      case "like":
        return "$count new like${count > 1 ? 's' : ''} on your post";
      case "comment":
        return "$count new comment${count > 1 ? 's' : ''}";
      case "repost":
        return "$count repost${count > 1 ? 's' : ''}";
      case "quote":
        return "$count quote repost${count > 1 ? 's' : ''}";
      case "space_join":
        return "$count people joined your Space";
      case "space_reminder":
        return "Your Space is starting soon";
      case "sos_close":
        return "SOS from a close friend";
      case "sos_nearby":
        return "Emergency SOS nearby";
      default:
        return "New notification";
    }
  }
}
