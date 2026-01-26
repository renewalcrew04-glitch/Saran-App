import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../constants/post_categories.dart';
import '../../utils/category_gradients.dart';
import '../../widgets/category_multi_select_sheet.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();

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
    if (args is Post) _quotedPost = args;
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

      // QUOTE REPOST
      if (_quotedPost != null) {
        await _postService.quotePost(
          postId: _quotedPost!.id,
          text: text,
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      // NORMAL POST
      final media =
          _pickedMediaPath != null ? <String>[_pickedMediaPath!] : <String>[];

      final type =
          _pickedMediaPath == null ? "text" : (_isVideo ? "video" : "photo");

      await _postService.createPost(
        type: type,
        text: text,
        media: media,
        visibility: _visibility,
        category:
            _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
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
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _quotedPost != null ? "Quote Post" : "Create Post",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_quotedPost != null) _quotePreview(),

            if (_quotedPost == null) _categorySelector(),

            _input(_textController, "Write something...", max: 6),
            const SizedBox(height: 14),
            _input(_hashtagsController, "Hashtags (ex: #women #wellness)"),
            const SizedBox(height: 14),

            if (_pickedMediaPath != null) _mediaPreview(),

            Row(
              children: [
                _mediaBtn(Icons.image_outlined, "Image", _pickImage),
                const SizedBox(width: 12),
                _mediaBtn(Icons.videocam_outlined, "Video", _pickVideo),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _publishing ? null : _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _publishing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Publish",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }

  // =========================
  // WIDGETS
  // =========================

  Widget _quotePreview() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quote post",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _quotedPost!.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      );

  Widget _categorySelector() => GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => CategoryMultiSelectSheet(
              selected: _selectedCategories,
              onDone: (cats) {
                setState(() {
                  _selectedCategories
                    ..clear()
                    ..addAll(cats);
                });
              },
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: _selectedCategories.isNotEmpty
                ? CategoryGradients.forCategories(_selectedCategories)
                : null,
            color: _selectedCategories.isEmpty
                ? Colors.grey.shade100
                : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const Icon(Icons.category, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedCategories.isEmpty
                      ? "Select categories"
                      : _selectedCategories.join(", "),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ],
          ),
        ),
      );

  Widget _mediaPreview() => Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isVideo
                    ? Container(
                        height: 220,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Text("Video selected"),
                      )
                    : Image.file(
                        File(_pickedMediaPath!),
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _removeMedia,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      );

  Widget _input(TextEditingController c, String hint, {int max = 1}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: TextField(
          controller: c,
          maxLines: max,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
          ),
        ),
      );

  Widget _mediaBtn(IconData icon, String label, VoidCallback onTap) =>
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.black),
          label: Text(label, style: const TextStyle(color: Colors.black)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
}
