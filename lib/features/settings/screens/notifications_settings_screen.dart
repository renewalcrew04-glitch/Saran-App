import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_settings_provider.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationSettingsProvider>();

    if (provider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        children: [
          _toggle(context, "Likes", "likes"),
          _toggle(context, "Comments", "comments"),
          _toggle(context, "Reposts", "reposts"),
          _toggle(context, "Mentions", "mentions"),
          _toggle(context, "Spaces", "spaces"),

          const Divider(),

          _toggle(context, "SOS – Close Friends", "sosCloseFriends"),
          _toggle(context, "SOS – Nearby (2 km)", "sosNearby"),

          const Divider(),

          _toggle(context, "Wellness", "wellness"),
          _toggle(context, "S-Daily Affirmations", "sDaily"),
        ],
      ),
    );
  }

  Widget _toggle(BuildContext context, String label, String key) {
    final provider = context.read<NotificationSettingsProvider>();
    final value = provider.settings[key] ?? false;

    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (v) => provider.toggle(key, v),
    );
  }
}
