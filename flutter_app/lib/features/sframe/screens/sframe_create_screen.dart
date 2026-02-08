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

    try {
      String? mediaUrl;
      if (_media != null) {
        mediaUrl = await SFrameApi.uploadMedia(_media!);
        if (mediaUrl == null && _media != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload failed: no URL returned')),
            );
          }
          return;
        }
      }

      await SFrameApi.createFrame({
        "mediaType": _media != null ? "photo" : "text",
        "mediaUrl": mediaUrl,
        "textContent": _text.text.trim(),
        "durationHours": 24,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                      decoration: InputDecoration(
                        hintText: "Write your moment…",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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
                TextButton(
                  onPressed: _loading ? null : _share,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    "Share",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
