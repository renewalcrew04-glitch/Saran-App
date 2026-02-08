import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
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
                child: _QuoteMedia(mediaUrls: originalPost.media),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteMedia extends StatelessWidget {
  final List<String> mediaUrls;

  const _QuoteMedia({required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    const maxHeight = 180.0;
    final url = ApiConfig.networkImageUrl(mediaUrls.first);
    if (url == null) {
      return Container(
        height: maxHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      height: maxHeight,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        height: maxHeight,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      ),
    );
  }
}
