import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../services/profile_service.dart';
import '../../features/notifications/utils/notification_router.dart';
import '../../features/notifications/models/app_notification.dart';

// Deterministic avatar palette
const _kAvatarPalette = [
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF7C3AED), Color(0xFFEC4899)],
  [Color(0xFF059669), Color(0xFF10B981)],
  [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
  [Color(0xFFD97706), Color(0xFFF59E0B)],
  [Color(0xFFBE185D), Color(0xFFF43F5E)],
];

List<Color> _avatarGradient(String name) {
  final idx = name.isNotEmpty ? name.codeUnitAt(0) % _kAvatarPalette.length : 0;
  return _kAvatarPalette[idx];
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'Just now';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  static const _kFilters = ['All', 'Likes', 'Comments', 'Follows'];

  bool _matchesFilter(AppNotification n) {
    if (_filter == 'All') return true;
    if (_filter == 'Likes') return n.type == 'like';
    if (_filter == 'Comments') return n.type == 'comment';
    if (_filter == 'Follows') {
      return n.type == 'follow' ||
          n.type == 'follow_request' ||
          n.type == 'follow_accept';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;
    const primary = Color(0xFFFF8132);

    final provider = context.watch<NotificationProvider>();
    final sections = provider.sectioned;

    // Check if any unread
    final hasUnread = sections.values
        .expand((g) => g)
        .expand((n) => n)
        .any((n) => !n.read);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0F1A) : cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 48,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.chevron_left_rounded, color: subtext, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => provider.markAllRead(),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Color(0xFFFF8132),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: border,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter chips ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kFilters.map((f) {
                    final active = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? primary : border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: active ? Colors.white : subtext,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: _buildBody(context, provider, sections),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationProvider provider,
    Map<String, List<List<AppNotification>>> sections,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8132)));
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, color: muted, size: 40),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                style: TextStyle(color: muted, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: provider.load,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF8132), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleEntries = sections.entries
        .where((e) => e.value.any((g) => g.any(_matchesFilter)))
        .toList();

    if (visibleEntries.isEmpty) {
      return Center(
        child: Text(
          'No notifications',
          style: TextStyle(color: muted, fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: visibleEntries.map((entry) {
        final filteredGroups = entry.value
            .where((g) => g.any(_matchesFilter))
            .toList();
        return _SectionBlock(
          title: entry.key,
          groups: filteredGroups,
          onTap: provider.markRead,
          onReload: provider.load,
        );
      }).toList(),
    );
  }
}

// ── Section block ─────────────────────────────────────────────────────────────
class _SectionBlock extends StatelessWidget {
  final String title;
  final List<List<AppNotification>> groups;
  final Function(String) onTap;
  final Future<void> Function() onReload;

  const _SectionBlock({
    required this.title,
    required this.groups,
    required this.onTap,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ),
        ...groups.map((group) => _NotifTile(
              group: group,
              onTap: onTap,
              onReload: onReload,
            )),
        const SizedBox(height: 6),
      ],
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final List<AppNotification> group;
  final Function(String) onTap;
  final Future<void> Function() onReload;

  const _NotifTile({
    required this.group,
    required this.onTap,
    required this.onReload,
  });

  String _actorName(AppNotification n) {
    final v = n.actor?['name'] ?? n.actor?['username'];
    return v?.toString() ?? 'Someone';
  }

  String _initial(AppNotification n) {
    final name = _actorName(n);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  ({
    String boldPart,
    String restPart,
    String? subtitle,
    Widget? trailing,
  }) _content(BuildContext context, AppNotification first, int count) {
    final name = _actorName(first);
    final others = count > 1 ? ' and ${count - 1} other${count > 2 ? 's' : ''}' : '';
    final type = first.type;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;

    switch (type) {
      case 'like':
        return (
          boldPart: '$name$others',
          restPart: ' liked your post',
          subtitle: null,
          trailing: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined, color: muted, size: 20),
          ),
        );

      case 'comment':
        final body = first.actor?['commentText']?.toString() ?? '';
        final postTitle =
            first.actor?['postTitle']?.toString() ?? 'Your career post';
        return (
          boldPart: name,
          restPart: body.isNotEmpty
              ? ' commented: "$body"'
              : ' commented on your post',
          subtitle: postTitle,
          trailing: null,
        );

      case 'follow':
        final profileService = ProfileService();
        return (
          boldPart: '$name$others',
          restPart: ' started following you',
          subtitle: null,
          trailing: _FollowButton(
            label: 'Follow',
            onTap: () async {
              final uid =
                  first.actor?['uid']?.toString() ?? '';
              if (uid.isEmpty) return;
              await profileService.followUser(uid);
            },
          ),
        );

      case 'follow_request':
        final actorUid = first.actor?['uid']?.toString() ?? '';
        return (
          boldPart: name,
          restPart: ' requested to follow you',
          subtitle: null,
          trailing: actorUid.isNotEmpty
              ? _FollowRequestActions(
                  actorUid: actorUid,
                  notifIds: group.map((n) => n.id).toList(),
                  onTap: onTap,
                  onReload: onReload,
                )
              : null,
        );

      case 'follow_accept':
        return (
          boldPart: name,
          restPart: ' accepted your follow request',
          subtitle: null,
          trailing: null,
        );

      case 'space_join':
      case 'space_reminder':
        final spaceName =
            first.actor?['spaceName']?.toString() ?? 'Mindful Monday Meditation';
        return (
          boldPart: first.actor?['spaceName']?.toString() ?? 'Wellness Circle',
          restPart: ' invited you to a Space',
          subtitle: spaceName,
          trailing: _FollowButton(label: 'Join', onTap: () {}),
        );

      default:
        return (
          boldPart: '$name$others',
          restPart: ' liked your post',
          subtitle: null,
          trailing: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? const Color(0xFF060B14) : Theme.of(context).scaffoldBackgroundColor;
    final text = isDark ? const Color(0xFFF1F5F9) : cs.onSurface;
    final muted = isDark ? const Color(0xFF64748B) : cs.onSurfaceVariant;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    const primary = Color(0xFFFF8132);

    final first = group.first;
    final unread = group.any((n) => !n.read);
    final colors = _avatarGradient(_actorName(first));
    final data = _content(context, first, group.length);

    return GestureDetector(
      onTap: () {
        for (final n in group) onTap(n.id);
        NotificationRouter.handle(context, first);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ───────────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initial(first),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1,
                    ),
                  ),
                ),
                // Notification type icon badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: bg, width: 1.5),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: unread ? primary : border,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _typeIcon(first.type),
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Text ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: text,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: data.boldPart,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: data.restPart),
                      ],
                    ),
                  ),
                  if (data.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle!,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(first.createdAt),
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Trailing ─────────────────────────────────────────────────
            if (data.trailing != null) ...[
              const SizedBox(width: 10),
              data.trailing!,
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'follow':
      case 'follow_request':
      case 'follow_accept':
        return Icons.person_add;
      case 'space_join':
      case 'space_reminder':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }
}

// ── Orange action button (Follow / Join) ──────────────────────────────────────
class _FollowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FollowButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF8132);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Follow request Accept/Decline ─────────────────────────────────────────────
class _FollowRequestActions extends StatelessWidget {
  final String actorUid;
  final List<String> notifIds;
  final Function(String) onTap;
  final Future<void> Function() onReload;

  const _FollowRequestActions({
    required this.actorUid,
    required this.notifIds,
    required this.onTap,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final border = isDark ? const Color(0xFF1E2535) : cs.outlineVariant;
    final subtext = isDark ? const Color(0xFF94A3B8) : cs.onSurfaceVariant;
    const primary = Color(0xFFFF8132);

    final profileService = ProfileService();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            for (final id in notifIds) onTap(id);
            await profileService.declineFollowRequest(actorUid);
            await onReload();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Text(
              'Decline',
              style: TextStyle(
                color: subtext,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            for (final id in notifIds) onTap(id);
            await profileService.acceptFollowRequest(actorUid);
            await onReload();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
