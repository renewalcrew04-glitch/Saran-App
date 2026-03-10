import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app content moderation info for App Store Guideline 1.2 (User Generated Content).
class ModerationInfoScreen extends StatelessWidget {
  const ModerationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Community Guidelines & Moderation"),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Content moderation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "SARAN has no tolerance for objectionable content or abusive users. "
              "Violating content will be removed and accounts may be restricted, suspended, or permanently removed.",
              style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
            ),
            const SizedBox(height: 24),
            Text(
              "How to report",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "• On a post: tap the 3-dot menu → Report. Choose a reason (Spam, Harassment, etc.) and submit.\n"
              "• On a profile: tap the menu (⋯) → Report this account.\n"
              "Reports are reviewed within 24 hours. We remove violating content and take action against offending accounts.",
              style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
            ),
            const SizedBox(height: 24),
            Text(
              "Blocking",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You can block any user from the 3-dot menu on their post or from their profile menu. "
              "Blocking immediately removes their content from your feed and prevents them from interacting with you.",
              style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse("https://saranapp.com/terms-of-use.html");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text("Full Terms of Use & Community Guidelines"),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
