import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../utils/daily_quotes.dart';
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
  int _sframeRefresh = 0;

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

  Widget _buildChip(BuildContext context, String label) {
    final isActive = _selectedTab == label;
    final theme = Theme.of(context);

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact quote chip – one quote per day.
  Widget _buildQuoteBanner() {
    final theme = Theme.of(context);
    final quote = getDailyQuote();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        quote,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Post input row: avatar, "What's on your mind?", Post button.
  Widget _buildPostComposer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = user?.avatar != null ? ApiConfig.networkImageUrl(user!.avatar!) ?? user.avatar : null;
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>('/post-create');
        if (result == true && mounted) {
          _loadFeed();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.outlineVariant,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, color: colorScheme.onSurfaceVariant, size: 22)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "What's on your mind?",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
            ),
            Material(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  final result = await context.push<bool>('/post-create');
                  if (result == true && mounted) {
                    _loadFeed();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppHeader(
        title: "SARAN",
        dark: false,
        unreadCount: 0,
        onOpenNotifications: () => context.push('/notifications'),
        onOpenMessages: () => context.push('/messages'),
        onOpenAI: () => context.push('/ai'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFeed();
          if (mounted) setState(() => _sframeRefresh++);
        },
        color: theme.colorScheme.primary,
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, 6, 0, MediaQuery.of(context).padding.bottom + 100),
          children: [
            // S-Frame row (rectangular dashed create + user frames) — refresh when user shares a story
            SFrameRow(
              key: ValueKey(_sframeRefresh),
              darkTheme: isDark,
              onStoryCreated: () => setState(() => _sframeRefresh++),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuoteBanner(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Category tabs (For You, Following, etc.) – end to end with space between
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Row(
                children: [
                  ..._homeTabs.map((label) => _buildChip(context, label)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildPostComposer(),
            ),
            const SizedBox(height: 10),

            // Feed section header
            if (!_loading && _error == null && _posts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  _selectedTab,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
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
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Couldn’t load feed',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadFeed,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: const Text('Try again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.article_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow people or share your first post',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await context.push<bool>('/post-create');
                            if (result == true && mounted) _loadFeed();
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Create post'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/explore'),
                          icon: const Icon(Icons.explore_rounded, size: 20),
                          label: const Text('Explore'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.outline),
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
                final authorUid = post.originalPost?.uid ?? post.quotedPost?.uid ?? post.uid;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _posts.length - 1 ? 4 : 0),
                  child: PostCard(
                    post: post,
                    onPostDeleted: () {
                      if (mounted) _loadFeed();
                    },
                    onBlockedUser: () {
                      if (mounted) {
                        setState(() {
                          _posts.removeWhere((p) {
                            final a = p.originalPost?.uid ?? p.quotedPost?.uid ?? p.uid;
                            return a == authorUid;
                          });
                        });
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
