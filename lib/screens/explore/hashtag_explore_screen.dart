import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import 'hashtag_posts_screen.dart';

class HashtagExploreScreen extends StatefulWidget {
  const HashtagExploreScreen({super.key});

  @override
  State<HashtagExploreScreen> createState() =>
      _HashtagExploreScreenState();
}

class _HashtagExploreScreenState
    extends State<HashtagExploreScreen> {
  final PostService service = PostService();
  List<Map<String, dynamic>> hashtags = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      hashtags = await service.getTrendingHashtags();
    } catch (_) {
      hashtags = [];
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Trending Hashtags",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hashtags.length,
              itemBuilder: (_, i) {
                final h = hashtags[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4),
                  title: Text(
                    h['tag'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${h['count']} posts',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HashtagPostsScreen(tag: h['tag']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
