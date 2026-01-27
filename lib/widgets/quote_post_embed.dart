import 'dart:ui';
import 'package:flutter/material.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.45),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  originalPost.userName ?? originalPost.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${TimeFormatter.format(originalPost.createdAt)}',
                  style: const TextStyle(
                    color: Colors.white54,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
