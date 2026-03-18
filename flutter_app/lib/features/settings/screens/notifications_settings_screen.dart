import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../providers/notification_settings_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<NotificationSettingsProvider>();
      if (auth.token != null && auth.token!.isNotEmpty) {
        provider.setToken(auth.token!);
        provider.load();
      } else {
        provider.clearLoading();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationSettingsProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (provider.loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: _appBar(scheme),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _appBar(scheme),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _NotifSection(
            title: 'Social',
            items: [
              _NotifItem(
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEC4899),
                label: 'Likes',
                description: 'When someone likes your post',
                value: provider.settings['likes'] ?? false,
                onChanged: (v) => provider.toggle('likes', v),
              ),
              _NotifItem(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF3B82F6),
                label: 'Comments',
                description: 'When someone comments on your post',
                value: provider.settings['comments'] ?? false,
                onChanged: (v) => provider.toggle('comments', v),
              ),
              _NotifItem(
                icon: Icons.repeat_rounded,
                color: const Color(0xFF10B981),
                label: 'Reposts',
                description: 'When someone reposts your content',
                value: provider.settings['reposts'] ?? false,
                onChanged: (v) => provider.toggle('reposts', v),
              ),
              _NotifItem(
                icon: Icons.alternate_email_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'Mentions',
                description: 'When someone mentions you',
                value: provider.settings['mentions'] ?? false,
                onChanged: (v) => provider.toggle('mentions', v),
              ),
              _NotifItem(
                icon: Icons.spatial_audio_off_rounded,
                color: const Color(0xFF06B6D4),
                label: 'Spaces',
                description: 'Updates about live spaces',
                value: provider.settings['spaces'] ?? false,
                onChanged: (v) => provider.toggle('spaces', v),
              ),
            ],
          ),
          _NotifSection(
            title: 'SOS & Safety',
            items: [
              _NotifItem(
                icon: Icons.sos_rounded,
                color: const Color(0xFFEF4444),
                label: 'SOS – Close Friends',
                description: 'Emergency alerts from close friends',
                value: provider.settings['sosCloseFriends'] ?? false,
                onChanged: (v) => provider.toggle('sosCloseFriends', v),
              ),
              _NotifItem(
                icon: Icons.location_on_rounded,
                color: const Color(0xFFF97316),
                label: 'SOS – Nearby (2 km)',
                description: 'Emergency alerts from people nearby',
                value: provider.settings['sosNearby'] ?? false,
                onChanged: (v) => provider.toggle('sosNearby', v),
              ),
            ],
          ),
          _NotifSection(
            title: 'Wellness',
            items: [
              _NotifItem(
                icon: Icons.favorite_border_rounded,
                color: const Color(0xFF10B981),
                label: 'Wellness',
                description: 'Daily wellness check-ins and updates',
                value: provider.settings['wellness'] ?? false,
                onChanged: (v) => provider.toggle('wellness', v),
              ),
              _NotifItem(
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFEAB308),
                label: 'Daily Affirmations',
                description: 'Morning affirmations and motivation',
                value: provider.settings['sDaily'] ?? false,
                onChanged: (v) => provider.toggle('sDaily', v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBar _appBar(ColorScheme scheme) => AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      );
}

class _NotifSection extends StatelessWidget {
  final String title;
  final List<_NotifItem> items;

  const _NotifSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                return Column(
                  children: [
                    item,
                    if (idx < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
