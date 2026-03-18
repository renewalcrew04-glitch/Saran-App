import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  final api = SettingsApi();

  bool privateAccount = false;
  bool hideFromExplore = false;
  bool loading = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        privateAccount = user.isPrivate ?? false;
      }
      _initialised = true;
    }
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return;

    api.setToken(auth.token!);
    setState(() => loading = true);

    try {
      await api.updateUserProfile(
        uid: auth.user!.uid,
        body: {'isPrivate': privateAccount, 'hideFromExplore': hideFromExplore},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Privacy settings updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update privacy settings'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: const Text('Account Privacy', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: loading ? null : _save,
              child: Text(
                loading ? 'Saving…' : 'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: loading ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Control who can see your profile and content.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings container
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _PrivacyToggle(
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Private Account',
                  subtitle: 'Only approved followers can see your posts and profile',
                  value: privateAccount,
                  onChanged: (v) => setState(() => privateAccount = v),
                ),
                Divider(height: 1, indent: 56, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                _PrivacyToggle(
                  icon: Icons.explore_off_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Hide from Explore',
                  subtitle: 'Your profile won\'t appear in explore suggestions',
                  value: hideFromExplore,
                  onChanged: (v) => setState(() => hideFromExplore = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}
