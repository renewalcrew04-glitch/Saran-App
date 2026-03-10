import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../utils/hashtag_utils.dart';
import '../utils/media_utils.dart';
import '../utils/time_formatter.dart';

class QuotePostEmbed extends StatelessWidget {
  final Post originalPost;
  final VoidCallback onTap;

  const QuotePostEmbed({
    super.key,
    required this.originalPost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.5);
    final containerColor = scheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: containerColor,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  originalPost.userName ?? originalPost.username,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${TimeFormatter.format(originalPost.createdAt)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (originalPost.text.isNotEmpty || originalPost.hashtags.isNotEmpty) ...[
              const SizedBox(height: 6),
              RichText(
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                  ),
                  children: buildTextSpansWithHashtags(
                    combinedPostText(text: originalPost.text, hashtags: originalPost.hashtags),
                    textColor: scheme.onSurface,
                    hashtagColor: scheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if (originalPost.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _QuoteMedia(mediaUrls: originalPost.media),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteMedia extends StatefulWidget {
  final List<String> mediaUrls;

  const _QuoteMedia({required this.mediaUrls});

  @override
  State<_QuoteMedia> createState() => _QuoteMediaState();
}

class _QuoteMediaState extends State<_QuoteMedia> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  static const double _mediaHeight = 200.0;

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.mediaUrls.isEmpty) return const SizedBox.shrink();
    if (widget.mediaUrls.length == 1) {
      return SizedBox(
        height: _mediaHeight,
        child: _buildSingle(context, widget.mediaUrls.first),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _mediaHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            onPageChanged: (i) => _currentPage.value = i,
            itemBuilder: (context, i) => _buildSingle(context, widget.mediaUrls[i]),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (_, page, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.mediaUrls.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == page ? scheme.onSurfaceVariant : scheme.outlineVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingle(BuildContext context, String mediaUrl) {
    final scheme = Theme.of(context).colorScheme;
    final url = ApiConfig.networkImageUrl(mediaUrl);
    if (url == null) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(Icons.broken_image, color: scheme.onSurfaceVariant)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: _mediaHeight,
        color: scheme.surfaceContainerHighest,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return ImageLoadingPlaceholder(width: double.infinity, height: _mediaHeight);
          },
          errorBuilder: (_, __, ___) {
            return Container(
              color: scheme.surfaceContainerHighest,
              child: Center(child: Icon(Icons.broken_image, color: scheme.onSurfaceVariant)),
            );
          },
        ),
      ),
    );
  }
}
