import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/feed_service.dart';
import '../../models/post_model.dart';
import '../../widgets/app_header.dart';
import '../../constants/post_categories.dart';
import '../../widgets/post_card.dart'; // ✅ IMPORTANT
import '../../features/sframe/widgets/sframe_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeedService _feedService = FeedService();

  bool _loading = true;
  String? _error;
  List<Post> _posts = [];

  String _selectedTab = PostCategories.forYou;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bool followingOnly = _selectedTab == PostCategories.following;

      final String? category = PostCategories.categories.contains(_selectedTab)
          ? _selectedTab
          : null;

      final posts = await _feedService.getHomeFeed(
        page: 1,
        limit: 20,
        category: category,
        followingOnly: followingOnly,
      );

      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _chip(String label) {
    final isActive = _selectedTab == label;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = label);
        _loadFeed();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _sframeCard({required String title, bool isAdd = false}) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isAdd) {
            context.push('/sframe-create');
          } else {
            context.push('/sframe-viewer');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isAdd
                  ? const Icon(Icons.add, size: 22, color: Colors.black)
                  : const SizedBox(),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _postComposer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Share something with your community...",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/post-create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: const Text(
        "You are not too much. You are enough.",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: "SARAN",
        unreadCount: 0,
        onOpenNotifications: () => context.push('/notifications'),
        onOpenMessages: () => context.push('/messages'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // S-Frames
            const SFrameRow(),
            _quoteCard(),
            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PostCategories.homeChips.map(_chip).toList(),
              ),
            ),

            const SizedBox(height: 14),
            _postComposer(),
            const SizedBox(height: 14),

            Text(
              "Showing: $_selectedTab",
              style: const TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 14),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Error loading feed:\n$_error",
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else if (_posts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    "No posts yet.\nStart following people or create a post!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ..._posts.map(
                (post) => GestureDetector(
                  onTap: () => context.push('/post', extra: post),
                  child: PostCard(post: post),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
