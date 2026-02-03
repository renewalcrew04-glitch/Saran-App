import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/feed_service.dart';
import '../../models/post_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/post_card.dart';
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

  String _selectedTab = 'For You';

  static const List<String> _homeTabs = ['For You', 'Following', 'Wellness', 'Career'];

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
      final bool followingOnly = _selectedTab == 'Following';
      final String? category = ['Wellness', 'Career'].contains(_selectedTab)
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

  Widget _buildChip(String label) {
    final isActive = _selectedTab == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedTab = label);
            _loadFeed();
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.black : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Black pill-shaped quote banner with white text.
  Widget _buildQuoteBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Text(
          'You are not too much. You are enough.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Light gray post input row: avatar, "What's on your mind?", black Post button.
  Widget _buildPostComposer() {
    return GestureDetector(
      onTap: () => context.push('/post-create'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.grey.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "What's on your mind?",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            ),
            Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.push('/post-create'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: "SARAN",
        dark: false,
        unreadCount: 0,
        onOpenNotifications: () => context.push('/notifications'),
        onOpenSearch: () => context.push('/explore'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // S-Frame row (rectangular dashed create + user frames) — refresh when user shares a story
            SFrameRow(onStoryCreated: () => setState(() {})),
            _buildQuoteBanner(),
            const SizedBox(height: 16),

            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: _homeTabs.map(_buildChip).toList(),
              ),
            ),

            const SizedBox(height: 16),
            _buildPostComposer(),
            const SizedBox(height: 20),

            // Feed section header
            if (!_loading && _error == null && _posts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _selectedTab,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your feed…',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Couldn’t load feed',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadFeed,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Try again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow people or share your first post',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/post-create'),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Create post'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/explore'),
                          icon: const Icon(Icons.explore_rounded, size: 20),
                          label: const Text('Explore'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              ..._posts.asMap().entries.map((entry) {
                final index = entry.key;
                final post = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _posts.length - 1 ? 16 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PostCard(
                      post: post,
                      onTap: () => context.push('/post', extra: post),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
