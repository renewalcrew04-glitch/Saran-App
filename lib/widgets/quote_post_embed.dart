import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago; 
import '../models/post_model.dart';

class QuotePostEmbed extends StatelessWidget {
  final Post post;

  const QuotePostEmbed({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.grey.shade200,
                    // ✅ Using flat fields
                    backgroundImage: post.userAvatar != null
                        ? NetworkImage(post.userAvatar!)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(
                            text: post.userName ?? post.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: " · ${timeago.format(post.createdAt, locale: 'en_short')}",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Text
            if (post.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Text(
                  post.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),

            // Media
            if (post.media.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: post.media.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}