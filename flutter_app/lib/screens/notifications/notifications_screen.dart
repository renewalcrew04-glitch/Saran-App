import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/profile_service.dart';
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

  String _actorName(AppNotification n) {
    final name = n.actor?['name'] ?? n.actor?['username'];
    return name?.toString() ?? 'Someone';
  }

  String _title(AppNotification first, int count) {
    final type = first.type;
    if (type == 'follow_request') {
      final name = _actorName(first);
      return count > 1 ? '$name and ${count - 1} other${count > 2 ? 's' : ''} requested to follow you' : '$name requested to follow you';
    }
    if (type == 'follow_accept') {
      final name = _actorName(first);
      return count > 1 ? '$name and others accepted your follow request' : '$name accepted your follow request';
    }
    if (type == 'follow') {
      final name = _actorName(first);
      return count > 1 ? '$name and ${count - 1} other${count > 2 ? 's' : ''} started following you' : '$name started following you';
    }
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

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final count = group.length;
    final unread = group.any((n) => !n.read);
    final isFollowRequest = first.type == 'follow_request';
    final actorUid = first.actor?['uid']?.toString();

    if (isFollowRequest && actorUid != null && actorUid.isNotEmpty) {
      final profileService = ProfileService();
      final provider = context.read<NotificationProvider>();
      return Card(
        elevation: unread ? 2 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (unread) const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.circle, size: 8, color: Colors.blue),
                  ),
                  Expanded(
                    child: Text(
                      _title(first, count),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                first.createdAt.toLocal().toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      for (final n in group) onTap(n.id);
                      final err = await profileService.declineFollowRequest(actorUid);
                      if (context.mounted) {
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request declined')),
                          );
                          await provider.load();
                        }
                      }
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      for (final n in group) onTap(n.id);
                      final err = await profileService.acceptFollowRequest(actorUid);
                      if (context.mounted) {
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Follow request accepted')),
                          );
                          await provider.load();
                        }
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: unread ? 2 : 0,
      child: ListTile(
        leading: unread
            ? const Icon(Icons.circle, size: 8, color: Colors.blue)
            : null,
        title: Text(_title(first, count)),
        subtitle: Text(
          first.createdAt.toLocal().toString(),
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
          for (final n in group) onTap(n.id);
          NotificationRouter.handle(context, group.first);
        },
      ),
    );
  }
}
