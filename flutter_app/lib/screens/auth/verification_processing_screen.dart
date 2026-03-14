import 'dart:async';
import 'package:flutter/material.dart';
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

    _startVerification();
  }

  Future<void> _startVerification() async {
    await Future.delayed(const Duration(seconds: 3));

    bool approved = DateTime.now().millisecondsSinceEpoch % 5 != 0;

    if (!mounted) return;

    if (approved) {
      Navigator.pushReplacementNamed(context, "/home");
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
              "Analyzing your selfie...",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text("Face detection"),
            Text("Authenticity verification"),
            Text("Identity validation"),
          ],
        ),
      ),
    );
  }
}