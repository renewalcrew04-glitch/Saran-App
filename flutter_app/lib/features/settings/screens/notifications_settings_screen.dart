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

    if (provider.loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Notifications"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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
