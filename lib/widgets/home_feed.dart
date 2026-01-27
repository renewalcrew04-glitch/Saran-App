import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post_model.dart';
import 'category_chips.dart';
import 'daily_quote_card.dart';
import 'post_card.dart';
import 'sframe_row.dart';
import 'share_story_card.dart';

class HomeFeed extends StatefulWidget {
  final List<Post> posts;

  const HomeFeed({
    super.key,
    required this.posts,
  });

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String _activeCategory = "For You";

  List<Post> get _filteredPosts {
    if (_activeCategory == "For You") return widget.posts;

    return widget.posts.where((post) {
      final text = post.text.toLowerCase();
      return text.contains(_activeCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        // =========================
        // HEADER
        // =========================
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const SFrameRow(),
              const SizedBox(height: 10),
              const DailyQuoteCard(),
              const SizedBox(height: 12),

              CategoryChips(
                onChanged: (category) {
                  setState(() => _activeCategory = category);
                },
              ),

              const SizedBox(height: 8),
              const ShareStoryCard(),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Showing: $_activeCategory",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 6),
            ],
          );
        }

        // =========================
        // EMPTY STATE
        // =========================
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text(
                "No posts for $_activeCategory",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // =========================
        // POST ITEM
        // =========================
        final post = posts[index - 1];

        return PostCard(
          post: post,
          onTap: () {
            context.push('/post', extra: post);
          },
        );
      },
    );
  }
}
