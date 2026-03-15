import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _Item(title: "User information", onTap: () => context.push('/settings/user-information')),
          _Item(title: "Appearance", onTap: () => context.push('/settings/appearance')),
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

          _Item(title: "Terms of Use", onTap: () => _openUrl("https://saranapp.com/terms-of-use.html")),
          _Item(title: "Privacy Policy", onTap: () => _openUrl("https://saranapp.com/privacy-policy.html")),
          _Item(title: "Wellness Feature Disclosure", onTap: () => _openUrl("https://saranapp.com/wellness-feature-disclosure.html")),
          _Item(title: "Community Guidelines & Moderation", onTap: () => context.push('/settings/moderation-info')),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Item({required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
