import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../utils/media_utils.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _blue   = Color(0xFF3B82F6);
const _purple = Color(0xFF8B5CF6);
const _indigo = Color(0xFF6366F1);
const _pink   = Color(0xFFEC4899);
const _slate  = Color(0xFF64748B);
const _amber  = Color(0xFFEAB308);
const _orange = Color(0xFFF97316);
const _green  = Color(0xFF10B981);
const _cyan   = Color(0xFF06B6D4);
const _red    = Color(0xFFEF4444);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [

          // ── Profile Header ─────────────────────────────────────────────
          if (user != null) _ProfileHeader(user: user),
          const SizedBox(height: 8),

          // ── Account ────────────────────────────────────────────────────
          _Section(title: 'Account', items: [
            _SettingsItem(
              icon: Icons.person_outline_rounded,
              color: _blue,
              title: 'User Information',
              subtitle: 'Name, gender, date of birth',
              onTap: () => context.push('/settings/user-information'),
            ),
            _SettingsItem(
              icon: Icons.palette_outlined,
              color: _purple,
              title: 'Appearance',
              subtitle: 'Light, dark or system theme',
              onTap: () => context.push('/settings/appearance'),
            ),
          ]),

          // ── Privacy & Safety ───────────────────────────────────────────
          _Section(title: 'Privacy & Safety', items: [
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              color: _indigo,
              title: 'Account Privacy',
              subtitle: 'Private account, explore visibility',
              onTap: () => context.push('/settings/privacy'),
            ),
            _SettingsItem(
              icon: Icons.block_rounded,
              color: _pink,
              title: 'Blocked Accounts',
              subtitle: 'Manage blocked users',
              onTap: () => context.push('/settings/blocked-list'),
            ),
            _SettingsItem(
              icon: Icons.volume_off_rounded,
              color: _slate,
              title: 'Muted Accounts',
              subtitle: 'Manage muted users',
              onTap: () => context.push('/settings/muted/search'),
            ),
            _SettingsItem(
              icon: Icons.star_rounded,
              color: _amber,
              title: 'Close Friends',
              subtitle: 'Manage your close friends list',
              onTap: () => context.push('/settings/close-friends/search'),
            ),
          ]),

          // ── Notifications ──────────────────────────────────────────────
          _Section(title: 'Notifications', items: [
            _SettingsItem(
              icon: Icons.notifications_outlined,
              color: _orange,
              title: 'Notifications',
              subtitle: 'Likes, comments, mentions & more',
              onTap: () => context.push('/settings/notifications'),
            ),
          ]),

          // ── Messaging ─────────────────────────────────────────────────
          _Section(title: 'Messaging', items: [
            _SettingsItem(
              icon: Icons.chat_bubble_outline_rounded,
              color: _green,
              title: 'DM Controls',
              subtitle: 'Who can message you',
              onTap: () => context.push('/settings/dm'),
            ),
            _SettingsItem(
              icon: Icons.comment_outlined,
              color: _cyan,
              title: 'Comments Controls',
              subtitle: 'Who can comment on your posts',
              onTap: () => context.push('/settings/comments'),
            ),
          ]),

          // ── Support ───────────────────────────────────────────────────
          _Section(title: 'Support', items: [
            _SettingsItem(
              icon: Icons.bug_report_outlined,
              color: _blue,
              title: 'Report a Problem',
              subtitle: 'Let us know about any issues',
              onTap: () => context.push('/settings/report'),
            ),
          ]),

          // ── Legal ──────────────────────────────────────────────────────
          _Section(title: 'Legal', items: [
            _SettingsItem(
              icon: Icons.description_outlined,
              color: _slate,
              title: 'Terms of Use',
              onTap: () => _openUrl('https://saranapp.com/terms-of-use.html'),
            ),
            _SettingsItem(
              icon: Icons.privacy_tip_outlined,
              color: _slate,
              title: 'Privacy Policy',
              onTap: () => _openUrl('https://saranapp.com/privacy-policy.html'),
            ),
            _SettingsItem(
              icon: Icons.health_and_safety_outlined,
              color: _green,
              title: 'Wellness Feature Disclosure',
              onTap: () => _openUrl('https://saranapp.com/wellness-feature-disclosure.html'),
            ),
            _SettingsItem(
              icon: Icons.gavel_outlined,
              color: _slate,
              title: 'Community Guidelines',
              onTap: () => context.push('/settings/moderation-info'),
            ),
          ]),

          // ── Logout ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outlineVariant),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // ── Danger Zone ────────────────────────────────────────────────
          _Section(title: 'Danger Zone', titleColor: _red, items: [
            _SettingsItem(
              icon: Icons.delete_forever_rounded,
              color: _red,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              textColor: _red,
              onTap: () => context.push('/settings/delete-account'),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = user.avatar != null && user.avatar!.isNotEmpty
        ? ApiConfig.networkImageUrl(user.avatar!) ?? user.avatar!
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5C842), Color(0xFFE8813A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: avatarUrl != null
                    ? safeAvatarNetworkImage(url: avatarUrl, size: 51)
                    : Container(
                        color: scheme.surface,
                        alignment: Alignment.center,
                        child: Text(
                          (user.name as String).isNotEmpty
                              ? (user.name as String)[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Edit profile chip
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                if (context.mounted) context.read<AuthProvider>().loadUser();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;
  final Color? titleColor;

  const _Section({required this.title, required this.items, this.titleColor});

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
                color: titleColor ?? scheme.onSurfaceVariant,
                letterSpacing: 1.1,
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
                        endIndent: 0,
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
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

// ── Settings Item ─────────────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon container
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
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
