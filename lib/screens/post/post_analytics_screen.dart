import 'package:flutter/material.dart';
import '../../models/post_model.dart';

class PostAnalyticsScreen extends StatelessWidget {
  final Post post;
  const PostAnalyticsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Post Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _metric("Views", "—"),
            _metric("Reach", "—"),
            _metric("Likes", post.likesCount.toString()),
            _metric("Comments", post.commentsCount.toString()),
            _metric("Reposts", post.repostsCount.toString()),
            _metric("Saves", "—"),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
