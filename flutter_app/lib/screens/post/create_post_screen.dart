import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/category_multi_select_sheet.dart';
import '../../widgets/quote_post_embed.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';

class CreatePostScreen extends StatefulWidget {
  /// When set (e.g. from Quote flow), show quoted post and publish as quote.
  final Post? quotedPost;

  const CreatePostScreen({super.key, this.quotedPost});

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
  final String _visibility = "public";

  String? _pickedMediaPath;
  bool _isVideo = false;

  Post? _quotedPost;

  @override
  void initState() {
    super.initState();
    _quotedPost = widget.quotedPost;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quotedPost ??= ModalRoute.of(context)?.settings.arguments is Post
        ? ModalRoute.of(context)!.settings.arguments as Post
        : null;
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

      if (_quotedPost != null) {
        await _postService.quotePost(
          postId: _quotedPost!.id,
          text: text,
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }

      List<String> mediaUrls = [];
      if (_pickedMediaPath != null) {
        final uploadedUrl =
            await _uploadService.uploadMedia(_pickedMediaPath!);
        mediaUrls.add(uploadedUrl);
      }

      final type =
          mediaUrls.isEmpty ? "text" : (_isVideo ? "video" : "photo");

      await _postService.createPost(
        type: type,
        text: text,
        media: mediaUrls,
        visibility: _visibility,
        category:
            _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
        hashtags: [
          ...hashtags,
          ..._selectedCategories.map((c) => "#$c"),
        ],
      );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _canPublish && !_publishing ? _publish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Post",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PROFILE HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: user?.avatar != null
                      ? NetworkImage(
                          ApiConfig.networkImageUrl(user!.avatar!) ??
                              user.avatar!)
                      : null,
                  backgroundColor: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? "User",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '@${user?.username ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// CONTENT WRITING AREA (clean & premium)
TextField(
  controller: _textController,
  autofocus: true,
  minLines: 5,        // space for 5 lines
  maxLines: null,     // grows as user types
  maxLength: 1098,    // character limit
  style: const TextStyle(
    fontSize: 18,
    color: Colors.black,
    height: 1.45,
    fontWeight: FontWeight.w400,
  ),
  decoration: InputDecoration(
    hintText: "What's on your mind?",
    hintStyle: TextStyle(
      color: Colors.grey.shade500,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    border: InputBorder.none,
    counterText: "",
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
  ),
  onChanged: (_) => setState(() {}),
),

const SizedBox(height: 16),

Divider(
  color: Colors.grey.shade200,
  thickness: 1,
  height: 1,
),

            /// QUOTED POST
            if (_quotedPost != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: QuotePostEmbed(
                  originalPost: _quotedPost!,
                  onTap: () {},
                ),
              ),

            /// MEDIA
            if (_pickedMediaPath != null) _mediaPreview(),

            if (_quotedPost == null) ...[
              const SizedBox(height: 20),

              /// HASHTAGS BOX
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: TextField(
                  controller: _hashtagsController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tag, size: 18),
                    hintText: "Add hashtags (#wellness #health)",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
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
          Text(
            'Everyone can reply',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedCategories.isEmpty
                    ? "Select Topic"
                    : _selectedCategories.first,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Colors.blue.shade700),
            ],
          ),
        ),
      );

  Widget _mediaPreview() => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isVideo
                ? Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_fill,
                        size: 50, color: Colors.white),
                  )
                : Image.file(
                    File(_pickedMediaPath!),
                    width: double.infinity,
                    height: 250,
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
                child:
                    const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
}
