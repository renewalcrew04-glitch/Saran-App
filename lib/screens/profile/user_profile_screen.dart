import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart';
import '../messages/chat_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FeedService _feedService = FeedService();
  final ProfileService _profileService = ProfileService();

  List<Post> _posts = [];
  bool _isLoading = true;

  // Local state for optimistic updates
  late bool _isFollowing;
  late int _followersCount;
  
  // Post Tabs
  String _activePostTab = 'all'; // all, text, photo, video, repost

  @override
  void initState() {
    super.initState();
    // Initialize local state from passed user object
    _isFollowing = widget.user.isFollowing ?? false;
    _followersCount = widget.user.followersCount;
    
    _fetchLatestProfileData();
    _loadUserPosts();
  }

  /// Fetches fresh profile data to ensure follow status and counts are accurate
  Future<void> _fetchLatestProfileData() async {
    try {
      final freshUser = await _profileService.getUserProfile(widget.user.uid);
      if (mounted) {
        setState(() {
          _isFollowing = freshUser.isFollowing ?? false;
          _followersCount = freshUser.followersCount;
        });
      }
    } catch (e) {
      // Fail silently, use passed data
      debugPrint("Error fetching fresh profile: $e");
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _feedService.getUserFeed(widget.user.uid);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFollowToggle() async {
    // 1. Optimistic Update
    setState(() {
      if (_isFollowing) {
        _isFollowing = false;
        _followersCount--;
      } else {
        _isFollowing = true;
        _followersCount++;
      }
    });

    try {
      // 2. API Call
      if (_isFollowing) {
        await _profileService.followUser(widget.user.uid);
      } else {
        await _profileService.unfollowUser(widget.user.uid);
      }
    } catch (e) {
      // 3. Revert on failure
      if (mounted) {
        setState(() {
          if (_isFollowing) {
            _isFollowing = false;
            _followersCount--;
          } else {
            _isFollowing = true;
            _followersCount++;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  Future<void> _handleMessage() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final dmProvider = context.read<DmProvider>();
    
    // Show loading indicator or simple snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Opening chat..."), duration: Duration(seconds: 1)),
    );

    try {
      final convoId = await dmProvider.openDm(
        token: token,
        otherUid: widget.user.uid,
      );

      if (convoId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convoId,
              otherUserId: widget.user.uid,
              otherName: widget.user.name,
              otherAvatar: widget.user.avatar,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open chat")),
        );
      }
    }
  }

  List<Post> get _filteredPosts {
    if (_activePostTab == 'all') return _posts;
    if (_activePostTab == 'text') return _posts.where((p) => p.type == 'text').toList();
    if (_activePostTab == 'photo') return _posts.where((p) => p.type == 'photo').toList();
    if (_activePostTab == 'video') return _posts.where((p) => p.type == 'video').toList();
    if (_activePostTab == 'repost') return _posts.where((p) => p.type == 'repost').toList();
    return _posts;
  }

  @override
  Widget build(BuildContext context) {
    // Current user validation to prevent actions on self if routed incorrectly
    final currentUser = Provider.of<AuthProvider>(context).user;
    final isMe = currentUser?.uid == widget.user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.user.username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Report/Block logic placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("More options coming soon")),
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchLatestProfileData();
          await _loadUserPosts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildStatsRow(),
              const SizedBox(height: 16),
              if (!isMe) _buildActionButtons(),
              const SizedBox(height: 20),
              const Divider(height: 1),
              _buildPostSubTabs(),
              _buildPostsGrid(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Cover Image & Avatar Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: widget.user.coverImage != null && widget.user.coverImage!.isNotEmpty
                  ? Image.network(
                      widget.user.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : const Center(child: Icon(Icons.image, color: Colors.grey)),
            ),
            
            // Avatar
            Positioned(
              left: 16,
              bottom: -32,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: widget.user.avatar != null && widget.user.avatar!.isNotEmpty
                      ? NetworkImage(widget.user.avatar!)
                      : null,
                  child: widget.user.avatar == null || widget.user.avatar!.isEmpty
                      ? Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 42),

        // Name & Bio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "@${widget.user.username}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.user.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              count: widget.user.postsCount,
              label: 'Posts',
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FollowersListScreen(
                    userId: widget.user.uid, 
                    username: widget.user.username
                  )
                ));
              },
              child: _StatItem(
                count: _followersCount, // Uses local state
                label: 'Followers',
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FollowingListScreen(
                    userId: widget.user.uid, 
                    username: widget.user.username
                  )
                ));
              },
              child: _StatItem(
                count: widget.user.followingCount,
                label: 'Following',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Follow / Following Button
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _handleFollowToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.white : Colors.black,
                  foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  elevation: 0,
                  side: _isFollowing ? const BorderSide(color: Colors.black12) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isFollowing ? "Following" : "Follow",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Message Button (Only if following)
          if (_isFollowing) ...[
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Message",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostSubTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _PostTabChip(
              label: 'All',
              isActive: _activePostTab == 'all',
              onTap: () => setState(() => _activePostTab = 'all'),
            ),
            _PostTabChip(
              label: 'Texts',
              isActive: _activePostTab == 'text',
              onTap: () => setState(() => _activePostTab = 'text'),
            ),
            _PostTabChip(
              label: 'Photos',
              isActive: _activePostTab == 'photo',
              onTap: () => setState(() => _activePostTab = 'photo'),
            ),
            _PostTabChip(
              label: 'Videos',
              isActive: _activePostTab == 'video',
              onTap: () => setState(() => _activePostTab = 'video'),
            ),
            _PostTabChip(
              label: 'Reposts',
              isActive: _activePostTab == 'repost',
              onTap: () => setState(() => _activePostTab = 'repost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final list = _filteredPosts;

    if (list.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "No posts yet",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final post = list[index];
          return GestureDetector(
            onTap: () {
              context.push('/post', extra: post);
            },
            child: _PostGridItem(post: post),
          );
        },
      ),
    );
  }
}

// --- Helper Widgets ---

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}

class _PostTabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PostTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }
}

class _PostGridItem extends StatelessWidget {
  final Post post;
  const _PostGridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.media.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            post.media.first,
            fit: BoxFit.cover,
            errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200),
          ),
          if (post.type == 'video')
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
            ),
        ],
      );
    }
    
    // Text Post Fallback
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          post.text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}