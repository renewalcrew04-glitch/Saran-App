import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../settings/screens/delete_account_screen.dart';

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  static void open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const MenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),

            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text(
                "Settings",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                "Delete account",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.logout();

                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
