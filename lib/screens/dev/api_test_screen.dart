import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String result = "Click button to test API";

  Future<void> testSendOtp() async {
    try {
      final res = await AuthService.sendOtp("9999999999");
      setState(() {
        result = "SUCCESS ✅\nStatus: ${res.statusCode}\nData: ${res.data}";
      });
    } catch (e) {
      setState(() {
        result = "FAILED ❌\nError: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("API Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: testSendOtp,
              child: const Text("Test /auth/send-otp"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
