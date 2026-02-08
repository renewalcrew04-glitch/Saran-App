import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String uri;

  const ImagePreviewScreen({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(uri, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48))),
          ),
        ),
      ),
    );
  }
}
