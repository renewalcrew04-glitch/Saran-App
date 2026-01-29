import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart'; // ✅ Import ProfileService
import '../../models/post_model.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FeedService _feedService = FeedService();
  final ProfileService _profileService = ProfileService(); // ✅ Init Service

  List<Post> _posts = [];
  bool _postsLoading = true;
  bool _profileLoading = true;
  
  // ✅ Local State for dynamic updates
  late bool _isFollowing;
  late int _followersCount;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize with passed data
    _currentUser = widget.user;
    _isFollowing = widget.user.isFollowing ?? false;
    _followersCount = widget.user.followersCount;
    
    _loadFullProfile();
    _loadPosts();
  }

  // ✅ Fetch fresh profile data to get accurate isFollowing status
  Future<void> _loadFullProfile() async {
    try {
      final freshUser = await _profileService.getUserProfile(widget.user.uid);
      if (mounted) {
        setState(() {
          _currentUser = freshUser;
          _isFollowing = freshUser.isFollowing ?? false;
          _followersCount = freshUser.followersCount;
          _profileLoading = false;
        });
      }
    } catch (e) {
      // If fetch fails, we rely on initial data
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _postsLoading = true);
    try {
      final posts = await _feedService.getUserFeed(widget.user.uid);
      if (mounted) {
        setState(() {
          _posts = posts;
          _postsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _postsLoading = false);
    }
  }

  // ✅ Handle Follow/Unfollow Logic (Optimistic Update)
  Future<void> _toggleFollow() async {
    // 1. Update UI Immediately
    setState(() {
      if (_isFollowing) {
        _followersCount = (_followersCount > 0) ? _followersCount - 1 : 0;
        _isFollowing = false;
      } else {
        _followersCount = _followersCount + 1;
        _isFollowing = true;
      }
    });

    try {
      // 2. Perform API Call
      if (_isFollowing) {
        await _profileService.followUser(widget.user.uid);
      } else {
        await _profileService.unfollowUser(widget.user.uid);
      }
    } catch (e) {
      // 3. Revert if API fails
      if (mounted) {
        setState(() {
          if (_isFollowing) {
            _followersCount = (_followersCount > 0) ? _followersCount - 1 : 0;
            _isFollowing = false;
          } else {
            _followersCount = _followersCount + 1;
            _isFollowing = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentUser.username),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadFullProfile();
          await _loadPosts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Cover
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: _currentUser.coverImage != null
                    ? Image.network(_currentUser.coverImage!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),

              const SizedBox(height: 12),

              // Avatar + name
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _currentUser.avatar != null 
                    ? NetworkImage(_currentUser.avatar!) 
                    : null,
                child: _currentUser.avatar == null
                    ? Text(
                        _currentUser.name.isNotEmpty ? _currentUser.name[0].toUpperCase() : "S",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),

              const SizedBox(height: 10),

              Text(
                _currentUser.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                "@${_currentUser.username}",
                style: TextStyle(color: Colors.grey[700]),
              ),

              if (_currentUser.bio != null && _currentUser.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: Text(
                    _currentUser.bio!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),

              const SizedBox(height: 12),

              // Stats Row (Uses local state for optimistic update)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem("Posts", _currentUser.postsCount.toString()),
                  _statItem("Followers", _followersCount.toString()),
                  _statItem("Following", _currentUser.followingCount.toString()),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Follow Button (Uses local state)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      // Change style based on state
                      backgroundColor: _isFollowing ? Colors.white : Colors.black,
                      foregroundColor: _isFollowing ? Colors.black : Colors.white,
                      elevation: 0,
                      side: _isFollowing ? const BorderSide(color: Colors.black12) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _isFollowing ? "Following" : "Follow",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),

              // Posts Grid
              if (_postsLoading)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text("No posts yet")),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final post = _posts[index];

                      return GestureDetector(
                        onTap: () {
                          // Optional: Navigate to post detail
                        },
                        child: Container(
                          color: Colors.grey.shade200,
                          child: post.media.isNotEmpty
                              ? Image.network(post.media.first, fit: BoxFit.cover)
                              : post.thumbnail != null 
                                  ? Image.network(post.thumbnail!, fit: BoxFit.cover)
                                  : const Center(child: Icon(Icons.text_fields)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }
}