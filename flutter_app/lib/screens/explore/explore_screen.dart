import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../utils/media_utils.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/explore_service.dart';
import '../../services/profile_service.dart';
import '../post/post_detail_screen.dart';
import '../profile/user_profile_screen.dart';

const List<String> _exploreFilters = ['All', 'People', 'Text', 'Photo', 'Video'];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ExploreService _service = ExploreService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _searching = false;
  String? _error;
  String _selectedFilter = 'All';
  List<User> _suggestions = [];
  final Set<String> _followingIds = {};

  List<Post> _posts = [];
  List<User> _users = [];
  List<Post> _searchPosts = [];

  /// IDs of users we have sent a follow request to (private accounts, not yet accepted).
  final Set<String> _pendingFollowIds = {};

  @override
  void initState() {
    super.initState();
    _loadExplore();
    _loadSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowState());
  }

  /// Load our following and pending state so Explore shows "Following" / "Requested" consistently.
  Future<void> _loadFollowState() async {
    final context = this.context;
    if (!context.mounted) return;
    final myUid = context.read<AuthProvider>().user?.uid;
    if (myUid == null || myUid.isEmpty) return;
    try {
      final result = await _profileService.getFollowing(myUid);
      final list = List<Map<String, dynamic>>.from(result['following'] ?? []);
      final pendingIds = await _profileService.getMyPendingFollowingIds();
      if (!mounted) return;
      setState(() {
        for (final u in list) {
          final uid = (u['uid'] ?? u['_id'] ?? '').toString();
          if (uid.isEmpty) continue;
          if (u['isFollowing'] == true) _followingIds.add(uid);
        }
        _pendingFollowIds.addAll(pendingIds);
      });
    } catch (_) {}
  }

  Future<void> _loadSuggestions() async {
    try {
      final list = await _service.getSuggestions(limit: 10);
      if (!mounted) return;
      setState(() => _suggestions = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = []);
    }
  }

  Future<void> _onFollow(User user) async {
    final uid = user.uid;
    if (uid.isEmpty) return;
    final alreadyFollowing = _followingIds.contains(uid);
    final alreadyPending = _pendingFollowIds.contains(uid);
    if (alreadyFollowing || alreadyPending) {
      final error = await _profileService.unfollowUser(uid);
      if (!mounted) return;
      if (error == null) {
        setState(() {
          _followingIds.remove(uid);
          _pendingFollowIds.remove(uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      } else {
        final lower = error.toLowerCase();
        if (!lower.contains('pending') && !lower.contains('request already') && !lower.contains('already following')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
          );
        }
      }
      return;
    }
    final result = await _profileService.followUser(uid);
    if (!mounted) return;
    if (result.error == null) {
      setState(() {
        if (result.status == 'pending') {
          _pendingFollowIds.add(uid);
        } else {
          _followingIds.add(uid);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == 'pending' ? 'Request sent' : 'Following ${user.name}',
          ),
        ),
      );
    } else {
      final err = result.error!;
      final lower = err.toLowerCase();
      if (!lower.contains('pending') && !lower.contains('request already') && !lower.contains('already following')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
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

  Future<void> _loadExplore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _service.getExploreFeed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String msg = 'Could not load explore feed.';
      final s = e.toString();
      if (s.contains('500')) {
        msg = 'Server error. Try again later.';
      } else if (s.contains('404')) {
        msg = 'Feed not available.';
      } else if (!s.contains('DioException') && s.length < 100) {
        msg = s.replaceFirst('Exception: ', '');
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  /// Filters posts by the selected tab. "All" = all posts; "People" = no posts (only suggestions); "Text"/"Photo"/"Video" = by type.
  List<Post> _filterPosts(List<Post> posts) {
    switch (_selectedFilter) {
      case 'All':
        return posts;
      case 'People':
        return []; // People tab shows only suggestions section
      case 'Text':
        return posts.where((p) => p.type == 'text' || p.media.isEmpty).toList();
      case 'Photo':
        return posts.where((p) {
          if (p.type == 'video') return false;
          return p.type == 'photo' || p.type == 'image' || p.media.isNotEmpty;
        }).toList();
      case 'Vid':
        return posts.where((p) => p.type == 'video').toList();
      default:
        return posts;
    }
  }

  List<Post> get _filteredExplorePosts => _filterPosts(_posts);
  List<Post> get _filteredSearchPosts => _filterPosts(_searchPosts);

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() {
          _searching = false;
          _users = [];
          _searchPosts = [];
          _error = null;
        });
        return;
      }

      setState(() => _searching = true);
      try {
        final res = await _service.searchAll(q);
        if (!mounted) return;
        setState(() {
          _users = (res['users'] as List<User>);
          _searchPosts = (res['posts'] as List<Post>);
          _searching = false;
          _error = null;
        });
      } catch (e) {
        if (!mounted) return;
        String msg = 'Search failed.';
        final s = e.toString();
        if (s.contains('500')) {
          msg = 'Search is temporarily unavailable. Try again.';
        } else if (s.contains('404')) {
          msg = 'Search not available.';
        } else if (!s.contains('DioException') && s.length < 100) {
          msg = s.replaceFirst('Exception: ', '');
        }
        setState(() {
          _error = msg;
          _searching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadExplore();
          await _loadFollowState();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          children: [
            Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: scheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(14),
  ),
  child: Row(
    children: [
      Icon(
        Icons.search,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged, // ✅ SAME logic
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search People, posts, topics...',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
      if (_searchController.text.isNotEmpty)
        GestureDetector(
          onTap: () {
            setState(() {
              _searchController.clear();
              _users = [];
              _searchPosts = [];
              _error = null;
              _searching = false;
            });
          },
          child: Icon(
            Icons.close,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
    ],
  ),
),
            const SizedBox(height: 12),
            // Category filters: All, People, Text, Photo, Video
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _exploreFilters.map((f) {
                  final isActive = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? scheme.primary : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isActive ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!)
            else if (_loading || _searching)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (hasQuery)
              _buildSearchResults()
            else ...[
              // Suggestions for you: only in All tab (horizontal cards + View more)
              if (_selectedFilter == 'All' && _suggestions.isNotEmpty) ...[
                Text(
                  'Suggestions for you',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, i) {
                      final u = _suggestions[i];
                      final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
                      final isFollowPending = _pendingFollowIds.contains(u.uid) || u.isFollowPending == true;
                      return _SuggestionCard(
                        user: u,
                        isFollowing: isFollowing,
                        isFollowPending: isFollowPending,
                        onFollow: () => _onFollow(u),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _loadSuggestions,
                    child: Text(
                      'View more',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // People tab: show people in a vertical list (no suggestions header)
              if (_selectedFilter == 'People') ...[
                if (_suggestions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No people to show.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  ..._suggestions.map((u) {
                        final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
                        final isFollowPending = _pendingFollowIds.contains(u.uid) || u.isFollowPending == true;
                        return _PeopleListTile(
                        user: u,
                        isFollowing: isFollowing,
                        isFollowPending: isFollowPending,
                        onFollow: () => _onFollow(u),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                          );
                        },
                      ); }),
              ]
              else
                // All / Text / Photo / Video: show post grid
                _buildExploreGrid(_filteredExplorePosts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final scheme = Theme.of(context).colorScheme;
    final showUsers = (_selectedFilter == 'All' || _selectedFilter == 'People') && _users.isNotEmpty;
    final filteredPosts = _filteredSearchPosts;
    final showPosts = filteredPosts.isNotEmpty;

    if (!showUsers && !showPosts) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            _selectedFilter == 'People'
                ? 'No people found.'
                : 'No results for $_selectedFilter.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showUsers) ...[
          const Text(
            'Accounts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ..._users.map((u) {
                final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
                final isFollowPending = _pendingFollowIds.contains(u.uid) || u.isFollowPending == true;
                return _PeopleListTile(
                user: u,
                isFollowing: isFollowing,
                isFollowPending: isFollowPending,
                onFollow: () => _onFollow(u),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                  );
                },
              ); }),
          const SizedBox(height: 16),
        ],
        if (showPosts) ...[
          const Text(
            'Posts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildExploreGrid(filteredPosts),
        ],
      ],
    );
  }

  Widget _buildExploreGrid(List<Post> posts) {
    final scheme = Theme.of(context).colorScheme;
    if (posts.isEmpty) {
      final message = _selectedFilter == 'All'
          ? 'Nothing to explore yet.'
          : 'No $_selectedFilter posts.';
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Same 3-column grid as profile Post tab: tight spacing, grey background, same tile style
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final post = posts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Container(
                color: scheme.surfaceContainerHighest,
                child: _ExploreTile(post: post),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Vertical list row for People tab: avatar, name, username, Follow button.
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
    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            safeAvatarNetworkImage(url: avatarUrl, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: isFollowing ? null : onFollow,
              style: TextButton.styleFrom(
                backgroundColor: (isFollowing || isFollowPending) ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                foregroundColor: (isFollowing || isFollowPending) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : isFollowPending ? 'Requested' : 'Follow',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final bool isFollowPending;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.user,
    required this.isFollowing,
    this.isFollowPending = false,
    required this.onFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            safeAvatarNetworkImage(url: avatarUrl, size: 52),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                user.name.isNotEmpty ? user.name : user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: TextButton(
                onPressed: isFollowing ? null : onFollow,
                style: TextButton.styleFrom(
                  backgroundColor: (isFollowing || isFollowPending) ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                  foregroundColor: (isFollowing || isFollowPending) ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : isFollowPending ? 'Requested' : 'Follow',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same tile style as profile Post tab: image with video/repost badges, or text-only cell.
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
          _buildImage(post.media.first),
          if (post.type == 'video')
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
            ),
          if (post.type == 'repost')
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.repeat, color: Colors.white, size: 16),
              ),
            ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      alignment: Alignment.topLeft,
      child: Text(
        post.text.isNotEmpty ? post.text : 'Text',
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    final url = ApiConfig.networkImageUrl(path);
    if (url == null) {
      return const Center(child: Icon(Icons.broken_image));
    }
    return safeNetworkImage(url: url, fit: BoxFit.cover);
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
      ),
    );
  }
}
