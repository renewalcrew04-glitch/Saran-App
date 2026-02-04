import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/explore_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/explore/explore_search_bar.dart';
import '../post/post_detail_screen.dart';
import '../profile/user_profile_screen.dart';

const List<String> _exploreFilters = ['All', 'People', 'Text', 'Photo', 'Vid'];

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

  @override
  void initState() {
    super.initState();
    _loadExplore();
    _loadSuggestions();
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
    final error = await _profileService.followUser(uid);
    if (!mounted) return;
    if (error == null) {
      setState(() => _followingIds.add(uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Following ${user.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
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

  /// Filters posts by the selected tab. "All" = all posts; "People" = no posts (only suggestions); "Text"/"Photo"/"Vid" = by type.
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
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Explore',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExplore,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExploreSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: () {},
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _users = [];
                  _searchPosts = [];
                  _error = null;
                  _searching = false;
                });
              },
            ),
            const SizedBox(height: 12),
            // Category filters: All, People, Text, Photo, Vid
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
                          color: isActive ? Colors.black : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black87,
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
                const Text(
                  'Suggestions for you',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
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
                      return _SuggestionCard(
                        user: u,
                        isFollowing: _followingIds.contains(u.uid),
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
                    child: const Text(
                      'View more',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
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
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No people to show.',
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  ..._suggestions.map((u) => _PeopleListTile(
                        user: u,
                        isFollowing: _followingIds.contains(u.uid),
                        onFollow: () => _onFollow(u),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                          );
                        },
                      )),
              ]
              else
                // All / Text / Photo / Vid: show post grid
                _buildExploreGrid(_filteredExplorePosts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
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
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
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
          ..._users.map(_userTile),
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

  Widget _userTile(User user) {
    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        backgroundColor: Colors.grey[200],
        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.black54) : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('@${user.username}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
        );
      },
    );
  }

  Widget _buildExploreGrid(List<Post> posts) {
    if (posts.isEmpty) {
      final message = _selectedFilter == 'All'
          ? 'Nothing to explore yet.'
          : 'No $_selectedFilter posts.';
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 6),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _ExploreTile(
          post: post,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
        );
      },
    );
  }
}

/// Vertical list row for People tab: avatar, name, username, Follow button.
class _PeopleListTile extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _PeopleListTile({
    required this.user,
    required this.isFollowing,
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
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.black54, size: 28)
                  : null,
            ),
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
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: isFollowing ? null : onFollow,
              style: TextButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey : Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
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
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.user,
    required this.isFollowing,
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
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.black54, size: 24)
                  : null,
            ),
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
                  backgroundColor: isFollowing ? Colors.grey : Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
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

class _ExploreTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _ExploreTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasMedia = post.media.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: hasMedia ? _media(post.media.first) : _fallback(post.text),
      ),
    );
  }

  Widget _media(String path) {
    final url = ApiConfig.networkImageUrl(path);
    if (url == null) return _fallback('');
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(''),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _fallback(String text) {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.topLeft,
      child: Text(
        text.isNotEmpty ? text : 'Post',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
