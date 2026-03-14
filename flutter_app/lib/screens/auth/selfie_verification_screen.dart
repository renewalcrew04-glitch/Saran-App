import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'verification_processing_screen.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  File? _image;

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void _continue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerificationProcessingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Identity"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Take a live selfie to verify your identity",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 90,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null
                  ? const Icon(Icons.camera_alt, size: 40)
                  : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _takeSelfie,
              child: const Text("Take Selfie"),
            ),
            const SizedBox(height: 20),
            if (_image != null)
              ElevatedButton(
                onPressed: _continue,
                child: const Text("Continue"),
              ),
          ],
        ),
      ),
    );
  }
}