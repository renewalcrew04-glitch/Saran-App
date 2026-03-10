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

  final List<String> _pickedMediaPaths = [];
  bool _isVideo = false;
  final PageController _mediaPageController = PageController();
  final ValueNotifier<int> _currentMediaPage = ValueNotifier<int>(0);

  Post? _quotedPost;

  @override
  void initState() {
    super.initState();
    _quotedPost = widget.quotedPost;
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    _currentMediaPage.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quotedPost ??= ModalRoute.of(context)?.settings.arguments is Post
        ? ModalRoute.of(context)!.settings.arguments as Post
        : null;
  }

  bool get _canPublish =>
      _textController.text.trim().isNotEmpty || _pickedMediaPaths.isNotEmpty;

  /// Parse hashtags from the hashtag field (user explicitly adds #wellness or wellness).
  List<String> _parseHashtagsFromField(String input, {int maxCount = 10}) {
    final seen = <String>{};
    final result = <String>[];
    for (final part in input.replaceAll("\n", " ").split(RegExp(r"[ ,]+"))) {
      final e = part.trim();
      if (e.isEmpty) continue;
      final tag = e.startsWith("#") ? e : "#$e";
      final lower = tag.toLowerCase();
      if (seen.contains(lower)) continue;
      seen.add(lower);
      result.add(tag);
      if (result.length >= maxCount) break;
    }
    return result;
  }

  /// Extract only explicit #hashtags from post text – do NOT convert plain words.
  List<String> _parseHashtagsFromText(String text, {int maxCount = 10}) {
    final seen = <String>{};
    final result = <String>[];
    final regex = RegExp(r'#\w+');
    for (final match in regex.allMatches(text)) {
      final tag = match.group(0)!;
      final lower = tag.toLowerCase();
      if (seen.contains(lower)) continue;
      seen.add(lower);
      result.add(tag);
      if (result.length >= maxCount) break;
    }
    return result;
  }

  Future<void> _pickImage() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _pickedMediaPaths.addAll(files.map((f) => f.path));
      _isVideo = false;
    });
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _pickedMediaPaths.clear();
      _pickedMediaPaths.add(file.path);
      _isVideo = true;
    });
  }

  void _removeMediaAt(int index) {
    setState(() {
      _pickedMediaPaths.removeAt(index);
      if (_pickedMediaPaths.isEmpty) {
        _isVideo = false;
        _currentMediaPage.value = 0;
      } else {
        _currentMediaPage.value = (_currentMediaPage.value).clamp(0, _pickedMediaPaths.length - 1);
      }
    });
  }

  Future<void> _publish() async {
    if (!_canPublish || _publishing) return;
    setState(() => _publishing = true);

    try {
      final text = _textController.text.trim();
      final fromField = _parseHashtagsFromField(_hashtagsController.text, maxCount: 10);
      final fromText = _parseHashtagsFromText(text, maxCount: 10);
      final seen = <String>{};
      final hashtags = <String>[];
      for (final tag in [...fromField, ...fromText, ..._selectedCategories.map((c) => "#$c")]) {
        final lower = tag.toLowerCase();
        if (seen.contains(lower)) continue;
        seen.add(lower);
        hashtags.add(tag);
        if (hashtags.length >= 3) break;
      }

      if (_quotedPost != null) {
        await _postService.quotePost(
          postId: _quotedPost!.id,
          text: text,
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }

      List<String> mediaUrls = [];
      for (final path in _pickedMediaPaths) {
        final url = await _uploadService.uploadMedia(path);
        mediaUrls.add(url);
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
        hashtags: hashtags,
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

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _canPublish && !_publishing ? _publish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _publishing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: scheme.onPrimary,
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
                  backgroundColor: scheme.surfaceContainerHighest,
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
                        color: scheme.onSurfaceVariant,
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
  style: TextStyle(
    fontSize: 18,
    color: scheme.onSurface,
    height: 1.45,
    fontWeight: FontWeight.w400,
  ),
  decoration: InputDecoration(
    hintText: "What's on your mind?",
    hintStyle: TextStyle(
      color: scheme.onSurfaceVariant,
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
  color: scheme.outlineVariant,
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

            /// MEDIA (slide/carousel)
            if (_pickedMediaPaths.isNotEmpty) ...[
              _mediaPreview(),
            ],

            if (_quotedPost == null) ...[
              const SizedBox(height: 20),

              /// HASHTAGS BOX
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: TextField(
                  controller: _hashtagsController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tag, size: 18),
                    hintText: "Add hashtags (max 3: #wellness #health)",
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        color: scheme.surface,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImage,
            icon: Icon(Icons.image_outlined, color: scheme.primary),
          ),
          IconButton(
            onPressed: _pickVideo,
            icon: Icon(Icons.videocam_outlined, color: scheme.primary),
          ),
          const Spacer(),
          Text(
            'Everyone can reply',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
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
            color: scheme.primaryContainer,
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
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  size: 16, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      );
  }

  Widget _mediaPreview() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _mediaPageController,
            itemCount: _pickedMediaPaths.length,
            onPageChanged: (i) => _currentMediaPage.value = i,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isVideo
                        ? Container(
                            width: double.infinity,
                            color: scheme.surface,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 50,
                              color: scheme.onSurface,
                            ),
                          )
                        : Image.file(
                            File(_pickedMediaPaths[index]),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeMediaAt(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: scheme.inverseSurface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: scheme.onInverseSurface, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_pickedMediaPaths.length > 1) ...[
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: _currentMediaPage,
            builder: (context, page, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pickedMediaPaths.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page ? scheme.primary : scheme.outline,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
