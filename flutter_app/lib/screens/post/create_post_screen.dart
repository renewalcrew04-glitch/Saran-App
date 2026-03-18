import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/quote_post_embed.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../utils/media_utils.dart';
import '../../constants/post_categories.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

  static const _categories = PostCategories.categories;

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

  Future<String?> _cropImage(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioPresets: const [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );
    return cropped?.path;
  }

  Future<String> _processImage(String path) async {
    if (path.toLowerCase().endsWith(".heic")) {
      final dir = await getTemporaryDirectory();
      final converted =
          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final result = await FlutterImageCompress.compressAndGetFile(
        path, converted,
        format: CompressFormat.jpeg,
        quality: 95,
      );
      path = result?.path ?? path;
    }

    final bytes = await File(path).readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return path;

    if (original.width > 1080) {
      original = img.copyResize(original, width: 1080);
    }

    original = img.convolution(original, filter: [
      0, -1,  0,
     -1,  5, -1,
      0, -1,  0,
    ]);

    final dir = await getTemporaryDirectory();
    final outputPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final jpg = img.encodeJpg(original, quality: 88);
    await File(outputPath).writeAsBytes(jpg);
    return outputPath;
  }

  Future<String> _compressImage(String path) async {
    final dir = Directory.systemTemp;
    final targetPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      path, targetPath,
      quality: 88,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );
    return result?.path ?? path;
  }

  Future<void> _pickImage() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 95);
    if (files.isEmpty) return;

    List<String> processedPaths = [];
    for (final file in files) {
      final cropped = await _cropImage(file.path);
      if (cropped == null) continue;
      final processed = await _processImage(cropped);
      final dir = await getTemporaryDirectory();
      final target =
          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final result = await FlutterImageCompress.compressAndGetFile(
        processed, target,
        quality: 88,
        format: CompressFormat.jpeg,
      );
      processedPaths.add(result?.path ?? processed);
    }

    if (processedPaths.isEmpty) return;
    setState(() {
      _pickedMediaPaths.addAll(processedPaths);
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
        _currentMediaPage.value =
            (_currentMediaPage.value).clamp(0, _pickedMediaPaths.length - 1);
      }
    });
  }

  Future<void> _publish() async {
    if (!_canPublish || _publishing) return;
    setState(() => _publishing = true);

    try {
      final text = _textController.text.trim();
      final fromField =
          _parseHashtagsFromField(_hashtagsController.text, maxCount: 10);
      final fromText = _parseHashtagsFromText(text, maxCount: 10);
      final seen = <String>{};
      final hashtags = <String>[];
      for (final tag in [...fromField, ...fromText]) {
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

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Post',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _canPublish && !_publishing ? _publish : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8132),
                foregroundColor: Colors.white,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                      'Post',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: scheme.outlineVariant),

            // ── Profile avatar + text input ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  user?.avatar != null
                      ? safeAvatarNetworkImage(
                          url: ApiConfig.networkImageUrl(user!.avatar!) ??
                              user.avatar,
                          size: 40,
                          backgroundColor: scheme.surfaceContainerHighest,
                        )
                      : CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.85),
                          child: Text(
                            (user?.name?.isNotEmpty == true
                                    ? user!.name![0]
                                    : 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      minLines: 3,
                      maxLines: null,
                      maxLength: 1098,
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurface,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share something with your community...',
                        hintStyle: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Quoted post ─────────────────────────────────────────
            if (_quotedPost != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: QuotePostEmbed(
                  originalPost: _quotedPost!,
                  onTap: () {},
                ),
              ),

            // ── Media upload card or preview ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _pickedMediaPaths.isNotEmpty
                  ? _mediaPreview()
                  : _mediaUploadCard(),
            ),

            if (_quotedPost == null) ...[
              const SizedBox(height: 20),

              // ── Category chips ─────────────────────────────────────
              _categorySection(),

              const SizedBox(height: 12),

              // ── Location ───────────────────────────────────────────
              _locationRow(),

              const SizedBox(height: 8),

              // ── Hashtags ───────────────────────────────────────────
              _hashtagsRow(),

              const SizedBox(height: 8),

              // ── Audience ───────────────────────────────────────────
              _audienceRow(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _mediaUploadCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt_outlined,
                color: scheme.onSurfaceVariant, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to add photo or video',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _mediaTypeChip('Photo', onTap: _pickImage),
              const SizedBox(width: 8),
              _mediaTypeChip('Video', onTap: _pickVideo),
              const SizedBox(width: 8),
              _mediaTypeChip('Carousel', onTap: _pickImage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mediaTypeChip(String label, {required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _categorySection() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories
                        ..clear()
                        ..add(cat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF8132)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF8132)
                          : scheme.outline,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : scheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _locationRow() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Text(
              'Add Location',
              style:
                  TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hashtagsRow() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.tag, color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hashtagsController,
                style: TextStyle(fontSize: 14, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Add Hashtags',
                  hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            Icon(Icons.add, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _audienceRow() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline,
                color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Text(
              'Audience',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Everyone',
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                color: scheme.onSurfaceVariant, size: 20),
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
                            color: scheme.surfaceContainerLow,
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
                          color: scheme.inverseSurface
                              .withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            color: scheme.onInverseSurface, size: 18),
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
                      color: i == page
                          ? const Color(0xFFFF8132)
                          : scheme.outlineVariant,
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
