import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/explore_service.dart';
import '../../widgets/explore/explore_search_bar.dart';
import '../post/post_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ExploreService _service = ExploreService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _searching = false;
  String? _error;

  List<Post> _posts = [];
  List<User> _users = [];
  List<Post> _searchPosts = [];

  @override
  void initState() {
    super.initState();
    _loadExplore();
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
        setState(() {
          _error = e.toString();
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () => context.push('/messages'),
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
            else
              _buildExploreGrid(_posts),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_users.isEmpty && _searchPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'No results yet.',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_users.isNotEmpty) ...[
          const Text(
            'Accounts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ..._users.map(_userTile),
          const SizedBox(height: 16),
        ],
        if (_searchPosts.isNotEmpty) ...[
          const Text(
            'Posts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildExploreGrid(_searchPosts),
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
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Nothing to explore yet.',
            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
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
