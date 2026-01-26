import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String output = "Click a button to test backend";

  Future<void> testMe() async {
    try {
      final data = await AuthService.getCurrentUser();
      setState(() {
        output = "✅ /auth/me SUCCESS\n\n$data";
      });
    } catch (e) {
      setState(() {
        output = "❌ /auth/me FAILED\n\n$e";
      });
    }
  }

  Future<void> testLogin() async {
    try {
      final data = await AuthService.login(
        email: "test@saran.com",
        password: "123456",
      );
      setState(() {
        output = "✅ /auth/login SUCCESS\n\n$data";
      });
    } catch (e) {
      setState(() {
        output = "❌ /auth/login FAILED\n\n$e";
      });
    }
  }

  Future<void> clearToken() async {
    await AuthService.clearToken();
    setState(() {
      output = "🧹 Token cleared";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Backend Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: testLogin,
                  child: const Text("Test Login"),
                ),
                ElevatedButton(
                  onPressed: testMe,
                  child: const Text("Test /me"),
                ),
                OutlinedButton(
                  onPressed: clearToken,
                  child: const Text("Clear Token"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(output),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
