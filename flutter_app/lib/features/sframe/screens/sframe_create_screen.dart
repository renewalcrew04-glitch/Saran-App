import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Light theme: black and white only
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

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
    HapticFeedback.lightImpact();

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
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "New moment",
          style: TextStyle(
            color: _black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Content card: media preview or text input
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _black.withValues(alpha: 0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _media != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _media!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: _black.withValues(alpha: 0.5),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () => setState(() => _media = null),
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(Icons.close_rounded, color: _white, size: 20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _text,
                                    onChanged: (_) => setState(() {}),
                                    maxLength: 200,
                                    maxLines: 8,
                                    minLines: 4,
                                    style: const TextStyle(
                                      color: _black,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Write your moment…",
                                      hintStyle: TextStyle(
                                        color: _black.withValues(alpha: 0.35),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding: EdgeInsets.zero,
                                      counterText: '',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${_text.text.length}/200',
                                      style: TextStyle(
                                        color: _black.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom bar: camera, gallery, Share
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: _white,
                border: Border(
                  top: BorderSide(color: _black.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickMedia(ImageSource.camera),
                  ),
                  const SizedBox(width: 10),
                  _ActionChip(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickMedia(ImageSource.gallery),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _loading ? null : _share,
                    style: FilledButton.styleFrom(
                      backgroundColor: _black,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: _white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _loading ? 'Sharing…' : 'Share',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _black.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _black, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
