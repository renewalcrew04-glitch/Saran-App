import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/explore_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../utils/category_gradients.dart';
import '../../utils/media_utils.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/post_card.dart';
import '../post/post_detail_screen.dart';
import '../profile/user_profile_screen.dart';
import 'explore_people_screen.dart';

// ── Design tokens (accent / UI colors only — not theme backgrounds) ────────────
const _kOrange = Color(0xFFFF8132);

// ── Tab definitions ────────────────────────────────────────────────────────────
// "Sparks" = text-only posts (short thought-bursts, like micro-posts)
const List<String> _kFilters = ['All', 'People', 'Posts', 'Topics', 'Sparks'];

// ── Trending hashtag chip accent colours ──────────────────────────────────────
// A single vivid accent per topic. LiquidGlassChip uses it as both the glass
// tint and the text colour — vivid on both light and dark themes.
class _ChipStyle {
  final Color accent;
  const _ChipStyle(this.accent);
}

const _kChipStyles = [
  _ChipStyle(Color(0xFF8B5CF6)), // violet
  _ChipStyle(Color(0xFF14B8A6)), // teal
  _ChipStyle(Color(0xFFA855F7)), // purple
  _ChipStyle(Color(0xFF22C55E)), // green
  _ChipStyle(Color(0xFF06B6D4)), // cyan
  _ChipStyle(Color(0xFFF59E0B)), // amber
  _ChipStyle(Color(0xFFEC4899)), // pink
  _ChipStyle(Color(0xFF3B82F6)), // blue
];

// ── Fallback mock topics shown while API loads or if empty ────────────────────
const _kMockTopics = [
  '#WomenInTech', '#SelfCare',  '#Mindfulness',
  '#CareerGrowth','#FitnessGoals','#Sisterhood',
  '#GirlBoss',    '#MorningRoutine',
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _service        = ExploreService();
  final _profileService = ProfileService();
  final _postService    = PostService();

  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading    = true;
  bool _searching  = false;
  String? _error;
  String _selectedFilter = 'All';

  List<Post> _posts       = [];
  List<User> _suggestions = [];
  List<Post> _searchPosts = [];
  List<User> _searchUsers = [];
  List<Map<String, dynamic>> _trending = [];

  final Set<String> _followingIds = {};
  final Set<String> _pendingIds   = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowState());
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final postsF = _service.getExploreFeed();
      final suggsF = _service.getSuggestions(limit: 10);
      _loadTrending(); // fire-and-forget; updates _trending independently
      final posts = await postsF;
      final suggs = await suggsF;
      if (!mounted) return;
      setState(() {
        _posts       = posts;
        _suggestions = suggs;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      String msg = 'Could not load explore feed.';
      final s = e.toString();
      if (s.contains('500'))      msg = 'Server error. Try again later.';
      else if (s.contains('404')) msg = 'Feed not available.';
      else if (!s.contains('DioException') && s.length < 100)
        msg = s.replaceFirst('Exception: ', '');
      setState(() { _error = msg; _loading = false; });
    }
  }

  Future<void> _loadTrending() async {
    try {
      final list = await _postService.getTrendingHashtags();
      if (!mounted) return;
      if (list.isNotEmpty) setState(() => _trending = list);
    } catch (_) {
      // API unavailable — _trending stays empty; UI uses mock fallback
    }
  }

  /// Returns tags to display: API data if available, otherwise mocks.
  List<String> get _topicTags {
    if (_trending.isNotEmpty) {
      return _trending
          .map((m) => (m['tag'] ?? m['hashtag'] ?? '').toString())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return _kMockTopics;
  }

  Future<void> _loadFollowState() async {
    if (!mounted) return;
    final myUid = context.read<AuthProvider>().user?.uid;
    if (myUid == null || myUid.isEmpty) return;
    try {
      final result = await _profileService.getFollowing(myUid);
      final list   = List<Map<String, dynamic>>.from(result['following'] ?? []);
      final pending = await _profileService.getMyPendingFollowingIds();
      if (!mounted) return;
      setState(() {
        for (final u in list) {
          final uid = (u['uid'] ?? u['_id'] ?? '').toString();
          if (uid.isNotEmpty && u['isFollowing'] == true) _followingIds.add(uid);
        }
        _pendingIds.addAll(pending);
      });
    } catch (_) {}
  }

  Future<void> _onFollow(User user) async {
    final uid = user.uid;
    if (uid.isEmpty) return;
    if (_followingIds.contains(uid) || _pendingIds.contains(uid)) {
      final err = await _profileService.unfollowUser(uid);
      if (!mounted) return;
      if (err == null) {
        setState(() { _followingIds.remove(uid); _pendingIds.remove(uid); });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      } else {
        final lower = err.toLowerCase();
        if (!lower.contains('pending') && !lower.contains('already')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
          );
        }
      }
      return;
    }
    final result = await _profileService.followUser(uid);
    if (!mounted) return;
    if (result.error == null) {
      setState(() {
        if (result.status == 'pending') _pendingIds.add(uid);
        else _followingIds.add(uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          result.status == 'pending' ? 'Request sent' : 'Following ${user.name}',
        )),
      );
    } else {
      final lower = result.error!.toLowerCase();
      if (!lower.contains('pending') && !lower.contains('already')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ───────────────────────────────────────────────────────────────
  List<Post> _filterPosts(List<Post> posts) {
    switch (_selectedFilter) {
      case 'All':
        return posts.where((p) => p.media.isNotEmpty && p.type != 'text').toList();
      case 'Posts':
        return posts.where((p) => p.media.isNotEmpty && p.type != 'text').toList();
      case 'Sparks':
        return posts.where((p) => p.type == 'text' || p.media.isEmpty).toList();
      case 'People':
      case 'Topics':
        return [];
      default:
        return posts;
    }
  }

  List<Post> get _filteredPosts       => _filterPosts(_posts);
  List<Post> get _filteredSearchPosts => _filterPosts(_searchPosts);

  // ── Search ──────────────────────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searching  = false;
          _searchUsers = [];
          _searchPosts = [];
          _error       = null;
        });
        return;
      }
      setState(() => _searching = true);
      try {
        final res = await _service.searchAll(q);
        if (!mounted) return;
        setState(() {
          _searchUsers = res['users'] as List<User>;
          _searchPosts = res['posts'] as List<Post>;
          _searching   = false;
          _error       = null;
        });
      } catch (e) {
        if (!mounted) return;
        String msg = 'Search failed.';
        final s = e.toString();
        if (s.contains('500'))      msg = 'Search is temporarily unavailable.';
        else if (s.contains('404')) msg = 'Search not available.';
        else if (!s.contains('DioException') && s.length < 100)
          msg = s.replaceFirst('Exception: ', '');
        setState(() { _error = msg; _searching = false; });
      }
    });
  }

  /// Populates the search bar with the tapped hashtag and triggers search.
  void _searchHashtag(String tag) {
    final query = tag.startsWith('#') ? tag : '#$tag';
    _searchController.text = query;
    _onSearchChanged(query);
    setState(() {});
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: scheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search people, topics, spaces...',
                    hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant, size: 20),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: scheme.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: _kOrange, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Filter tabs (Liquid Glass) ────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _kFilters.map((f) {
                  final isActive = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LiquidGlassChip(
                      label: f,
                      isActive: isActive,
                      onTap: () => setState(() => _selectedFilter = f),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: _error != null
                  ? _ErrorCard(message: _error!)
                  : (_loading || _searching)
                      ? Center(
                          child: CircularProgressIndicator(color: _kOrange),
                        )
                      : hasQuery
                          ? _buildSearchResults(context)
                          : _buildMainFeed(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main feed (no search query) ─────────────────────────────────────────────
  Widget _buildMainFeed(BuildContext context) {
    switch (_selectedFilter) {
      case 'People':
        return _buildPeopleFeed(context);
      case 'Topics':
        return _buildTopicsFeed(context);
      case 'Sparks':
        return _buildSparksFeed(context, _filteredPosts);
      default: // All / Posts
        return _buildAllFeed(context);
    }
  }

  Widget _buildAllFeed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── People you may know ────────────────────────────────────────
        if (_suggestions.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'People you may know',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExplorePeopleScreen(),
                  ),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: _kOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 145,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, i) {
                final u = _suggestions[i];
                final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
                final isPending   = _pendingIds.contains(u.uid) || u.isFollowPending == true;
                return _SuggestionCard(
                  user: u,
                  isFollowing: isFollowing,
                  isPending: isPending,
                  onFollow: () => _onFollow(u),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Trending Topics ────────────────────────────────────────────
        Text(
          'Trending Topics',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_topicTags.length.clamp(0, 10), (i) {
            final tag = _topicTags[i];
            return _HashtagChip(
              tag: tag,
              style: _kChipStyles[i % _kChipStyles.length],
              onTap: () => _searchHashtag(tag),
            );
          }),
        ),
        const SizedBox(height: 24),

        // ── Recommended for You ────────────────────────────────────────
        if (_filteredPosts.isNotEmpty) ...[
          Text(
            'Recommended for You',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildExploreGrid(context, _filteredPosts),
        ] else if (!_loading)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'Nothing to explore yet.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeopleFeed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          'No people to show.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) =>
          Divider(color: scheme.outline, height: 1),
      itemBuilder: (context, i) {
        final u = _suggestions[i];
        final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
        final isPending   = _pendingIds.contains(u.uid) || u.isFollowPending == true;
        return _PeopleListTile(
          user: u,
          isFollowing: isFollowing,
          isFollowPending: isPending,
          onFollow: () => _onFollow(u),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
          ),
        );
      },
    );
  }

  Widget _buildTopicsFeed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = _topicTags;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Trending Topics',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(tags.length, (i) {
            final tag = tags[i];
            return _HashtagChip(
              tag: tag,
              style: _kChipStyles[i % _kChipStyles.length],
              large: true,
              onTap: () => _searchHashtag(tag),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSparksFeed(BuildContext context, List<Post> posts) {
    final scheme = Theme.of(context).colorScheme;

    if (posts.isEmpty) {
      return Center(
        child: Text(
          'No Sparks yet.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sparks',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Short thoughts & text posts from the community',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...posts.map((p) => PostCard(post: p)),
      ],
    );
  }

  // ── Search results ──────────────────────────────────────────────────────────
  Widget _buildSearchResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final showUsers = (_selectedFilter == 'All' || _selectedFilter == 'People') &&
        _searchUsers.isNotEmpty;
    final filteredPosts = _filteredSearchPosts;
    final showPosts = filteredPosts.isNotEmpty;

    if (!showUsers && !showPosts) {
      return Center(
        child: Text(
          _selectedFilter == 'People' ? 'No people found.' : 'No results.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (showUsers) ...[
          Text(
            'People',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ..._searchUsers.map((u) {
            final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
            final isPending   = _pendingIds.contains(u.uid) || u.isFollowPending == true;
            return _PeopleListTile(
              user: u,
              isFollowing: isFollowing,
              isFollowPending: isPending,
              onFollow: () => _onFollow(u),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (showPosts) ...[
          Text(
            'Posts',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _buildExploreGrid(context, filteredPosts),
        ],
      ],
    );
  }

  // ── Masonry grid ────────────────────────────────────────────────────────────
  Widget _buildExploreGrid(BuildContext context, List<Post> posts) {
    final scheme = Theme.of(context).colorScheme;

    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final height = post.type == 'video'
            ? (index % 3 == 0 ? 320.0 : 220.0)
            : (index.isEven ? 200.0 : 240.0);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: height,
              child: Container(
                color: scheme.surfaceContainerHighest,
                child: _ExploreTile(post: post),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Suggestion card (horizontal scroll) ────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final bool isPending;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.user,
    required this.isFollowing,
    required this.isPending,
    required this.onFollow,
    required this.onTap,
  });

  static const _kAvatarBg = [
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    final initials  = (user.name.isNotEmpty ? user.name : user.username)
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(1)
        .map((s) => s[0].toUpperCase())
        .join();
    final colorIndex = (user.username.codeUnits.fold(0, (a, b) => a + b)) % _kAvatarBg.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAvatarBg[colorIndex],
              ),
              child: avatarUrl != null
                  ? ClipOval(
                      child: safeNetworkImage(
                        url: avatarUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              user.name.isNotEmpty ? user.name : user.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: LiquidGlassChip(
                label: (isFollowing || isPending)
                    ? (isFollowing ? 'Following' : 'Req...')
                    : 'Follow',
                isActive: !(isFollowing || isPending),
                onTap: onFollow,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                borderRadius: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── People list tile (People tab / search) ─────────────────────────────────────
class _PeopleListTile extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final bool isFollowPending;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _PeopleListTile({
    required this.user,
    required this.isFollowing,
    this.isFollowPending = false,
    required this.onFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            safeAvatarNetworkImage(url: avatarUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.username,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            LiquidGlassChip(
              label: (isFollowing || isFollowPending)
                  ? (isFollowing ? 'Following' : 'Requested')
                  : 'Follow',
              isActive: !(isFollowing || isFollowPending),
              onTap: onFollow,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hashtag chip — accent-tinted Liquid Glass ─────────────────────────────────
class _HashtagChip extends StatelessWidget {
  final String tag;
  final _ChipStyle style;
  final bool large;
  final VoidCallback? onTap;

  const _HashtagChip({
    required this.tag,
    required this.style,
    this.large = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = tag.startsWith('#') ? tag : '#$tag';
    // fixedColor = accent → thin tint bg + vivid text (works on both themes)
    return LiquidGlassChip(
      label: label,
      isActive: false,
      onTap: onTap,
      fixedColor: style.accent,
      textColor: style.accent,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 9 : 7,
      ),
      fontSize: large ? 14 : 12.5,
      fontWeight: FontWeight.w700,
    );
  }
}

// ── Explore tile (masonry grid cell) ──────────────────────────────────────────
class _ExploreTile extends StatelessWidget {
  final Post post;
  const _ExploreTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (post.media.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(context, post.media.first),
          // Author overlay at bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.text.isNotEmpty)
                    Text(
                      post.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  if (post.username.isNotEmpty)
                    Text(
                      '@${post.username}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          if (post.type == 'video')
            Positioned(
              right: 8, top: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
              ),
            ),
        ],
      );
    }

    // Text-only (Spark)
    return Container(
      decoration: BoxDecoration(
        gradient: CategoryGradients.forCategory(post.category ?? ''),
      ),
      child: Stack(
        children: [
          Container(color: Colors.black.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.edit_note_rounded, color: Colors.white54, size: 18),
                ),
                const Spacer(),
                Text(
                  post.text.isNotEmpty ? post.text : 'Spark',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                if (post.username.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@${post.username}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context, String path) {
    final scheme = Theme.of(context).colorScheme;
    final url = ApiConfig.networkImageUrl(path);
    if (url == null) return Center(child: Icon(Icons.broken_image, color: scheme.onSurfaceVariant));
    return safeNetworkImage(url: url, fit: BoxFit.cover);
  }
}

// ── Error card ─────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade900),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red.shade300,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
