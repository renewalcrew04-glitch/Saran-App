import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/message_provider.dart';
import '../../config/api_config.dart';
import '../../utils/media_utils.dart';
import '../../utils/daily_quotes.dart';
import '../../services/feed_service.dart';
import '../../models/post_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/post_card.dart';
import '../../features/sframe/widgets/sframe_row.dart';
import '../../constants/post_categories.dart';

// ── SARAN Dark-theme brand tokens ────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kSurface   = Color(0xFF0B0F1A);
const _kCard      = Color(0xFF111827);
const _kBorder    = Color(0xFF1E2535);
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);
const _kText      = Color(0xFFF1F5F9);
const _kMuted     = Color(0xFF64748B);
const _kSubtext   = Color(0xFF94A3B8);
const _kHashtag   = Color(0xFFFF8132);

class HomeScreen extends StatefulWidget {
  final Function(ScrollDirection direction)? onScrollDirection;

  const HomeScreen({super.key, this.onScrollDirection});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  List<Post> _posts = [];
  int _sframeRefresh = 0;

  String _selectedTab = 'For You';
  final List<String> _homeTabs = PostCategories.homeChips;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(() {
      if (widget.onScrollDirection != null) {
        widget.onScrollDirection!(
          _scrollController.position.userScrollDirection,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bool followingOnly = _selectedTab == 'Following';
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

  // ── Feed filter chip (Liquid Glass) ─────────────────────────────────────────
  Widget _buildChip(String label) {
    final isActive = _selectedTab == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LiquidGlassChip(
        label: label,
        isActive: isActive,
        onTap: () {
          setState(() => _selectedTab = label);
          _loadFeed();
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── S-Daily quote banner — Today's Affirmation style ────────────────────────
  Widget _buildSDailyBanner() {
    final quote = getDailyQuote();
    return GestureDetector(
      onTap: () => context.push('/sdaily'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4338CA), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF312E81).withValues(alpha: 0.38),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "TODAY'S AFFIRMATION",
                  style: TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'S-Daily',
                    style: TextStyle(
                      color: Color(0xFFA5B4FC),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '"$quote"',
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient avatar with user initial (used when no photo set) ─────────────
  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE040FB), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          height: 1,
        ),
      ),
    );
  }

  // ── Post composer ───────────────────────────────────────────────────────────
  Widget _buildPostComposer() {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = user?.avatar != null
        ? ApiConfig.networkImageUrl(user!.avatar!) ?? user.avatar
        : null;

    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>('/post-create');
        if (result == true && mounted) _loadFeed();
      },
      child: GlassBox(
        borderRadius: BorderRadius.circular(14),
        blur: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            avatarUrl != null
                ? safeAvatarNetworkImage(
                    url: avatarUrl, size: 34, backgroundColor: _kBorder)
                : _buildInitialAvatar(user?.name.isNotEmpty == true ? user!.name : (user?.username ?? '?')),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "What's on your mind?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            _OrangeButton(
              label: 'Post',
              onTap: () async {
                final result = await context.push<bool>('/post-create');
                if (result == true && mounted) _loadFeed();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Feed content ────────────────────────────────────────────────────────────
  Widget _buildFeedContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 36, color: _kMuted),
            const SizedBox(height: 8),
            const Text(
              "Couldn't load feed",
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: _kText),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _OrangeButton(label: 'Try again', onTap: _loadFeed),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _posts.asMap().entries.map((entry) {
        final index = entry.key;
        final post = entry.value;
        final authorUid =
            post.originalPost?.uid ?? post.quotedPost?.uid ?? post.uid;
        return Padding(
          padding:
              EdgeInsets.only(bottom: index < _posts.length - 1 ? 4 : 0),
          child: PostCard(
            post: post,
            onPostDeleted: () {
              if (mounted) _loadFeed();
            },
            onBlockedUser: () {
              if (mounted) {
                setState(() {
                  _posts.removeWhere((p) {
                    final a =
                        p.originalPost?.uid ?? p.quotedPost?.uid ?? p.uid;
                    return a == authorUid;
                  });
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kCard,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.article_outlined, size: 36, color: _kMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'No posts yet',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17, color: _kText),
          ),
          const SizedBox(height: 6),
          const Text(
            'Follow people or share your first post',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OrangeButton(
                label: 'Create post',
                onTap: () async {
                  final result = await context.push<bool>('/post-create');
                  if (result == true && mounted) _loadFeed();
                },
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.push('/explore'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPrimary, width: 1.5),
                  ),
                  child: const Text(
                    'Explore',
                    style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _kBg : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(
        title: 'SARAN',
        dark: false,
        unreadCount: context.watch<NotificationProvider>().unreadCount,
        messageUnreadCount: context.watch<MessageProvider>().totalUnreadCount,
        onOpenNotifications: () => context.push('/notifications'),
        onOpenMessages: () => context.push('/messages'),
        onOpenAI: () => context.push('/ai'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFeed();
          if (mounted) setState(() => _sframeRefresh++);
        },
        color: _kPrimary,
        backgroundColor: _kCard,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (widget.onScrollDirection != null) {
              widget.onScrollDirection!(notification.direction);
            }
            return false;
          },
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              0,
              6,
              0,
              MediaQuery.of(context).padding.bottom + 100,
            ),
            children: [
              // S-Frames row
              SFrameRow(
                key: ValueKey(_sframeRefresh),
                darkTheme: isDark,
                onStoryCreated: () => setState(() => _sframeRefresh++),
              ),

              // S-Daily banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildSDailyBanner(),
              ),

              // Feed filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children:
                      _homeTabs.map((label) => _buildChip(label)).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Post composer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPostComposer(),
              ),
              const SizedBox(height: 10),

              // Feed
              _buildFeedContent(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared orange CTA button ───────────────────────────────────────────────
class _OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OrangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const kA = Color(0xFFFF8C42); // warm light orange
    const kB = Color(0xFFFF5722); // vivid deep orange
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kA, kB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55FF5722),
              blurRadius: 10,
              spreadRadius: -2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          'Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
