import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class MirrorScreen extends StatefulWidget {
  const MirrorScreen({super.key});

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  CameraController? _controller;
  bool _loading = true;

  final List<String> prompts = const [
    "I am enough",
    "I am proud of myself",
    "I deserve peace",
  ];

  late final String prompt;

  @override
  void initState() {
    super.initState();
    prompt = prompts[Random().nextInt(prompts.length)];
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      // front camera
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("S-Mirror Challenge"),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.black,
            child: Text(
              prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : (_controller == null || !_controller!.value.isInitialized)
                    ? const Center(
                        child: Text(
                          "Camera not available",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : CameraPreview(_controller!),
          ),
        ],
      ),
    );
  }
}
