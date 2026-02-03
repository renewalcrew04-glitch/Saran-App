import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart';
import '../messages/chat_screen.dart';

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
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  bool get _isOwnProfile {
    final current = context.read<AuthProvider>().user;
    return current != null &&
        current.uid.isNotEmpty &&
        current.uid == widget.user.uid;
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);

    try {
      final uid = widget.user.uid.trim();
      if (uid.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final posts = await _feedService.getUserFeed(uid);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load posts: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Widget _buildPostMedia(String mediaUrl) {
    final url = ApiConfig.networkImageUrl(mediaUrl);
    if (url == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image)),
      );
    }
    return Image.network(url, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(user.username),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Cover
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: user.coverImage != null
                    ? Image.network(user.coverImage!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),

              const SizedBox(height: 12),

              // Avatar + name
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : "S",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),

              const SizedBox(height: 10),

              Text(
                user.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                "@${user.username}",
                style: TextStyle(color: Colors.grey[700]),
              ),

              const SizedBox(height: 12),

              // Follow + Message (or Edit profile when own)
              Builder(
                builder: (context) {
                  final isOwn = _isOwnProfile;
                  if (isOwn) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Edit profile – could push to edit screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Edit profile")),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Edit profile"),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _followLoading
                                  ? null
                                  : () async {
                                      setState(() => _followLoading = true);
                                      final ok = _isFollowing
                                          ? await _profileService.unfollowUser(
                                                widget.user.uid,
                                              )
                                          : await _profileService.followUser(
                                                widget.user.uid,
                                              );
                                      if (!mounted) return;
                                      setState(() {
                                        _followLoading = false;
                                        if (ok) _isFollowing = !_isFollowing;
                                      });
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _isFollowing
                                                  ? "Following ${widget.user.name}"
                                                  : "Unfollowed ${widget.user.name}",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey
                                    : Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _followLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isFollowing ? "Following" : "Follow"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final auth = context.read<AuthProvider>();
                                final token = auth.token;
                                if (token == null || token.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Please log in to message")),
                                  );
                                  return;
                                }
                                final convoId = await context
                                    .read<DmProvider>()
                                    .openDm(
                                      token: token,
                                      otherUid: widget.user.uid,
                                    );
                                if (!context.mounted) return;
                                if (convoId == null || convoId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Could not start chat")),
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
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
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 20),
                              label: const Text("Message"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              if (_loading)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_posts.isEmpty)
                const SizedBox(
                  height: 220,
                  child: Center(child: Text("No posts yet")),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      final post = _posts[index];

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          color: Colors.grey.shade200,
                          child: post.media.isNotEmpty
                              ? _buildPostMedia(post.media.first)
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
}
