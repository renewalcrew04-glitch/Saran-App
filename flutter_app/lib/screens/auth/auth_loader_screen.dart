import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Shown on app start. Restores session from stored token, then redirects
/// to /home if logged in or /login if not. Prevents "logout on close".
class AuthLoaderScreen extends StatefulWidget {
  const AuthLoaderScreen({super.key});

  @override
  State<AuthLoaderScreen> createState() => _AuthLoaderScreenState();
}

class _AuthLoaderScreenState extends State<AuthLoaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreAndRedirect());
  }

  Future<void> _restoreAndRedirect() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loadUserFromToken();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
