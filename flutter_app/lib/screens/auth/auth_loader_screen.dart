import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Shown on app start. Restores session from stored token, then redirects
/// to /home if logged in or /login if not. Prevents "logout on close".
/// Includes timeout so app never gets stuck (fixes App Store 2.1.0 rejection).
///
/// iPad support (including 13-inch iPad Pro):
/// - Uses SafeArea and Center for consistent layout on all screen sizes.
/// - Logo and loading indicator scale appropriately on tablet displays.
class AuthLoaderScreen extends StatefulWidget {
  const AuthLoaderScreen({super.key});

  @override
  State<AuthLoaderScreen> createState() => _AuthLoaderScreenState();
}

class _AuthLoaderScreenState extends State<AuthLoaderScreen> {
  static const Duration _maxWait = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreAndRedirect());
  }

  Future<void> _restoreAndRedirect() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.loadUserFromToken().timeout(
        _maxWait,
        onTimeout: () {
          // Backend unreachable (e.g. during App Review) – go to login
          auth.clearSessionSafe();
        },
      );
    } catch (_) {
      auth.clearSessionSafe();
    }
    if (!mounted) return;
    if (auth.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Responsive: works on iPhone and iPad (13-inch, 11-inch, etc.)
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon for branded loading (avoids "blank screen" impression)
              Image.asset(
                'assets/app_icon.png',
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.spa,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SARAN',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
