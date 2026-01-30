import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/upload_service.dart';
import '../../constants/post_categories.dart';
import '../../widgets/category_multi_select_sheet.dart';
import '../../widgets/quote_post_embed.dart'; // Ensure you have this widget

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final UploadService _uploadService = UploadService();

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  bool _publishing = false;
  final List<String> _selectedCategories = [];
  String _visibility = "public";

  String? _pickedMediaPath;
  bool _isVideo = false;

  Post? _quotedPost;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Post) {
      _quotedPost = args;
    }
  }

  bool get _canPublish =>
      _textController.text.trim().isNotEmpty || _pickedMediaPath != null;

  List<String> _parseHashtags(String input) {
    return input
        .replaceAll("\n", " ")
        .split(RegExp(r"[ ,]+"))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith("#") ? e : "#$e")
        .toSet()
        .toList();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _pickedMediaPath = file.path;
      _isVideo = false;
    });
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _pickedMediaPath = file.path;
      _isVideo = true;
    });
  }

  void _removeMedia() {
    setState(() {
      _pickedMediaPath = null;
      _isVideo = false;
    });
  }

  Future<void> _publish() async {
    if (!_canPublish || _publishing) return;
    setState(() => _publishing = true);

    try {
      final text = _textController.text.trim();
      final hashtags = _parseHashtags(_hashtagsController.text);

      // 1. QUOTE REPOST LOGIC
      if (_quotedPost != null) {
        await _postService.quotePost(
          postId: _quotedPost!.id,
          text: text,
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      // 2. NORMAL POST LOGIC (with Media Upload)
      List<String> mediaUrls = [];
      if (_pickedMediaPath != null) {
        // Upload locally picked file to server
        final String uploadedUrl = await _uploadService.uploadMedia(_pickedMediaPath!);
        mediaUrls.add(uploadedUrl);
      }

      final type = mediaUrls.isNotEmpty 
          ? (_isVideo ? "video" : "photo") 
          : "text";

      await _postService.createPost(
        type: type,
        text: text,
        media: mediaUrls,
        visibility: _visibility,
        category: _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
        hashtags: [
          ...hashtags,
          ..._selectedCategories.map((c) => "#$c"),
        ],
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to publish: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(), // Minimal header
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _canPublish && !_publishing ? _publish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Post",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar Row (Optional, adds context)
            const SizedBox(height: 10),
            
            // Input Area
            TextField(
              controller: _textController,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.4),
              decoration: InputDecoration(
                hintText: _quotedPost != null ? "Add a comment..." : "What's happening?",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Quoted Post Preview
            if (_quotedPost != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: QuotePostEmbed(post: _quotedPost!), // Reusing your existing embed widget
              ),

            // Media Preview
            if (_pickedMediaPath != null) _mediaPreview(),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFEEEEEE)),
            
            // Category & Hashtags (Only for new posts)
            if (_quotedPost == null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _hashtagsController,
                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                decoration: const InputDecoration(
                  hintText: "Add tags #wellness #health",
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.tag, size: 18, color: Colors.grey),
                  prefixIconConstraints: BoxConstraints(minWidth: 24),
                ),
              ),
              const SizedBox(height: 10),
              _categorySelector(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 10, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 10
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
        color: Colors.white,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined, color: Colors.blueAccent),
          ),
          IconButton(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent),
          ),
          const Spacer(),
          // Visibility indicator
          Text(
            _visibility == 'public' ? 'Everyone can reply' : 'Restricted',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => CategoryMultiSelectSheet(
            selected: _selectedCategories,
            onDone: (cats) => setState(() => _selectedCategories..clear()..addAll(cats)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCategories.isEmpty ? "Select Topic" : _selectedCategories.first,
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isVideo
              ? Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                )
              : Image.file(
                  File(_pickedMediaPath!),
                  width: double.infinity,
                  height: 250, // Standard preview height
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeMedia,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}