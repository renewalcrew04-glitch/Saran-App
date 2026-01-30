import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/upload_service.dart';
import '../services/sframe_service.dart';

class SFrameCreateScreen extends StatefulWidget {
  const SFrameCreateScreen({super.key});

  @override
  State<SFrameCreateScreen> createState() => _SFrameCreateScreenState();
}

class _SFrameCreateScreenState extends State<SFrameCreateScreen> {
  final TextEditingController _textController = TextEditingController();
  final UploadService _uploadService = UploadService();
  
  // State
  File? _selectedImage;
  bool _isUploading = false;
  String _mode = 'photo'; // 'photo', 'text'
  String? _selectedMood;

  final List<String> _moods = ['😊 Happy', '😴 Tired', '🎉 Party', '🧘 Calm', '💪 Active', '🎵 Vibe'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _mode = 'photo';
      });
    }
  }

  Future<void> _postSFrame() async {
    if (_mode == 'photo' && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }
    if (_mode == 'text' && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter some text")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? mediaUrl;
      String mediaType = _mode; // 'photo' or 'text'

      // 1. Upload Image if needed
      if (_mode == 'photo' && _selectedImage != null) {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          mediaUrl = await _uploadService.uploadSingle(
            token: token,
            file: _selectedImage!,
          );
        }
      }

      // 2. Create S-Frame
      await SFrameService.createSFrame(
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        textContent: _textController.text.trim(),
        mood: _selectedMood,
        durationHours: 24,
      );

      if (!mounted) return;
      context.pop(); // Close screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Story posted!")));

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to post: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content Area
          Positioned.fill(
            child: _mode == 'photo' ? _buildPhotoView() : _buildTextView(),
          ),

          // Top Bar (Close)
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),

          // Mood Selector (Floating)
          Positioned(
            top: 60,
            right: 16,
            left: 80,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: _moods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMood == mood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = isSelected ? null : mood),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        mood,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Post Button
                if ((_mode == 'photo' && _selectedImage != null) || (_mode == 'text' && _textController.text.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: _isUploading ? null : _postSFrame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "Share Story",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Tab Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TabButton(
                        label: "Text",
                        isActive: _mode == 'text',
                        onTap: () => setState(() => _mode = 'text'),
                      ),
                      const SizedBox(width: 20),
                      _TabButton(
                        label: "Photo",
                        isActive: _mode == 'photo',
                        onTap: () => setState(() => _mode = 'photo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoView() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(
        color: const Color(0xFF1A1A1A),
        width: double.infinity,
        height: double.infinity,
        child: _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 60),
                  const SizedBox(height: 16),
                  Text(
                    "Tap to pick photo",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: TextField(
            controller: _textController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cursive', // Or any premium font
            ),
            decoration: const InputDecoration(
              hintText: "Type something...",
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
            maxLines: 5,
            onChanged: (val) => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}