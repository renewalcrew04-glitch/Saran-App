import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'verification_pending_screen.dart';

class VerificationProcessingScreen extends StatefulWidget {
  const VerificationProcessingScreen({super.key});

  @override
  State<VerificationProcessingScreen> createState() =>
      _VerificationProcessingScreenState();
}

class _VerificationProcessingScreenState
    extends State<VerificationProcessingScreen> {

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    // Poll the backend up to 5 times (every 2 seconds) waiting for verification
    const maxAttempts = 5;
    const delay = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(delay);
      if (!mounted) return;

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadUser();

        if (!mounted) return;

        final user = authProvider.user;
        if (user != null && user.verified) {
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      } catch (_) {
        // continue polling
      }
    }

    // After all attempts, check final status
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.verified) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VerificationPendingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 30),
            Text(
              "Verifying your identity...",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text("Face detection"),
            Text("Authenticity check"),
            Text("Identity validation"),
          ],
        ),
      ),
    );
  }
}
