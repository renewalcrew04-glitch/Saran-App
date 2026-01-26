import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/sframe_api.dart';

class SFrameCreateScreen extends StatefulWidget {
  const SFrameCreateScreen({super.key});

  @override
  State<SFrameCreateScreen> createState() => _SFrameCreateScreenState();
}

class _SFrameCreateScreenState extends State<SFrameCreateScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _media;
  bool _loading = false;
  final TextEditingController _text = TextEditingController();

  Future<void> _pickMedia(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _media = File(picked.path));
    }
  }

  Future<void> _share() async {
    if (_text.text.trim().isEmpty && _media == null) return;

    setState(() => _loading = true);

    String? mediaUrl;

    if (_media != null) {
      mediaUrl = await SFrameApi.uploadMedia(_media!);
    }

    await SFrameApi.createFrame({
      "mediaType": _media != null ? "photo" : "text",
      "mediaUrl": mediaUrl,
      "textContent": _text.text.trim(),
      "durationHours": 24,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("S-Frame"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _media != null
                  ? Image.file(_media!, fit: BoxFit.cover)
                  : TextField(
                      controller: _text,
                      maxLength: 200,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "Write your moment…",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => _pickMedia(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.white),
                  onPressed: () => _pickMedia(ImageSource.gallery),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _loading ? null : _share,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Share",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
