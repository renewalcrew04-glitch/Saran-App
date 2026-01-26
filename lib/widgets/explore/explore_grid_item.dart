import 'package:flutter/material.dart';
import '../../models/post_model.dart';

class ExploreGridItem extends StatelessWidget {
  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  const ExploreGridItem({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = (post.media != null && post.media!.isNotEmpty);
    final preview = hasMedia ? post.media!.first : null;

    return InkWell(
      onTap: onOpen,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: hasMedia
                  ? Image.network(
                      preview!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackText(),
                    )
                  : _fallbackText(),
            ),
          ),

          // top-right menu
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onMore,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
              ),
            ),
          ),

          // bottom-left type badge
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                (post.type ?? "text").toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackText() {
    final text = (post.text ?? "").trim();
    return Container(
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? "SARAN" : text,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}
