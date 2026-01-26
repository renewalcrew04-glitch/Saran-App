import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openPolicies() async {
    final uri = Uri.parse("https://www.saranapp.com/policies.html");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _Item(title: "Notifications", onTap: () => context.push('/settings/notifications')),
          _Item(title: "Account Privacy", onTap: () => context.push('/settings/privacy')),
          _Item(title: "Close Friends", onTap: () => context.push('/settings/close-friends/search')),
          _Item(title: "Muted", onTap: () => context.push('/settings/muted/search')),
          _Item(title: "DM Controls", onTap: () => context.push('/settings/dm')),
          _Item(title: "Comments Controls", onTap: () => context.push('/settings/comments')),
          _Item(title: "Blocked Accounts", onTap: () => context.push('/settings/blocked-list')),
          _Item(title: "Report a problem", onTap: () => context.push('/settings/report')),
          _Item(title: "Delete Account", onTap: () => context.push('/settings/delete-account')),

          const Divider(height: 24),

          _Item(title: "Terms & Policies", onTap: _openPolicies),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _Item({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
