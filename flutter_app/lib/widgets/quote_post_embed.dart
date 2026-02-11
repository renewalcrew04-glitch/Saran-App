import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../utils/time_formatter.dart';
import '../utils/media_utils.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final containerColor = isDark ? Colors.black.withValues(alpha: 0.45) : Colors.grey.shade100;

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
                    color: theme.textTheme.titleMedium?.color ?? Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${TimeFormatter.format(originalPost.createdAt)}',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8) ?? Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (originalPost.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                originalPost.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9) ?? Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
            if (originalPost.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _QuoteMedia(
                  mediaUrls: originalPost.media,
                  mediaDisplay: originalPost.mediaDisplay,
                ),
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
  final String? mediaDisplay;

  const _QuoteMedia({required this.mediaUrls, this.mediaDisplay});

  @override
  State<_QuoteMedia> createState() => _QuoteMediaState();
}

class _QuoteMediaState extends State<_QuoteMedia> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  static const double _portraitAspectRatio = 4 / 5; // 1080×1350
  static const double _landscapeAspectRatio = 1.91; // 1080×566

  double _heightForWidth(double width) {
    if (widget.mediaDisplay == 'portrait') return width / _portraitAspectRatio;
    if (widget.mediaDisplay == 'landscape') return width / _landscapeAspectRatio;
    return width / _portraitAspectRatio; // auto-detect: fit portrait (taller)
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) return const SizedBox.shrink();
    if (widget.mediaUrls.length == 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return SizedBox(
            height: _heightForWidth(w),
            child: _buildSingle(widget.mediaUrls.first),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final maxH = _heightForWidth(w);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: maxH,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaUrls.length,
                onPageChanged: (i) => _currentPage.value = i,
                itemBuilder: (_, i) => _buildSingle(widget.mediaUrls[i]),
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
                      color: i == page ? Colors.black54 : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingle(String mediaUrl) {
    final url = ApiConfig.networkImageUrl(mediaUrl);
    if (url == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    }
    if (widget.mediaDisplay == 'portrait' || widget.mediaDisplay == 'landscape') {
      final aspectRatio = widget.mediaDisplay == 'portrait'
          ? _portraitAspectRatio
          : _landscapeAspectRatio;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: safeNetworkImage(
            url: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AutoAspectNetworkImage(url: url),
    );
  }
}
