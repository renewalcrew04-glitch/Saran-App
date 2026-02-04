import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart';
import '../../features/settings/services/settings_api.dart';
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
  final SettingsApi _settingsApi = SettingsApi();

  List<Post> _posts = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _isFollowPending = false;
  bool _followLoading = false;
  bool _isCloseFriend = false;
  bool _isBlocked = false;
  bool _isMuted = false;
  bool _isBlockedView = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadFollowState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRelationshipState());
  }

  /// Load close friend, blocked, muted state for the profile user (only when viewing someone else).
  Future<void> _loadRelationshipState() async {
    final current = context.read<AuthProvider>().user;
    if (current == null || current.uid == widget.user.uid) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;
    final targetUid = widget.user.uid;
    if (targetUid.isEmpty) return;

    _settingsApi.setToken(token);
    try {
      final closeFriends = await _settingsApi.getCloseFriends();
      final blocked = await _settingsApi.getBlockedUsers();
      final muted = await _settingsApi.getMuted();

      bool isClose = false;
      for (final u in closeFriends) {
        final uid = (u is Map ? (u['uid'] ?? u['_id']) : u)?.toString() ?? '';
        if (uid == targetUid) { isClose = true; break; }
      }
      bool isBlock = false;
      for (final u in blocked) {
        final uid = (u is Map ? (u['uid'] ?? u['_id']) : u)?.toString() ?? '';
        if (uid == targetUid) { isBlock = true; break; }
      }
      bool isMute = false;
      for (final u in muted) {
        final uid = (u is Map ? (u['uid'] ?? u['_id']) : u)?.toString() ?? '';
        if (uid == targetUid) { isMute = true; break; }
      }
      if (mounted) {
        setState(() {
          _isCloseFriend = isClose;
          _isBlocked = isBlock;
          _isMuted = isMute;
        });
      }
    } catch (_) {}
  }

  /// Load initial follow state from API so button shows "Follow" / "Following" / "Requested" correctly.
  Future<void> _loadFollowState() async {
    final uid = widget.user.uid.trim();
    if (uid.isEmpty) {
      return;
    }
    try {
      final profile = await _profileService.getUserProfile(uid);
      if (!mounted) return;
      if (profile != null && profile['blocked'] == true) {
        setState(() => _isBlockedView = true);
        return;
      }
      if (profile != null) {
        setState(() {
          _isFollowing = profile['isFollowing'] == true;
          _isFollowPending = profile['isFollowPending'] == true;
        });
      }
    } catch (_) {}
  }

  bool get _isOwnProfile {
    final current = context.read<AuthProvider>().user;
    return current != null &&
        current.uid.isNotEmpty &&
        current.uid == widget.user.uid;
  }

  /// Can viewer see posts? Owner always can; public always; private only if accepted follow.
  bool get _canSeePosts =>
      _isOwnProfile ||
      (widget.user.isPrivate != true) ||
      (widget.user.isPrivate == true && _isFollowing);

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

  Future<void> _onProfileMenuSelected(String value) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;
    final uid = widget.user.uid;
    if (uid.isEmpty) return;

    _settingsApi.setToken(token);

    switch (value) {
      case 'close_friend':
        try {
          if (_isCloseFriend) {
            await _settingsApi.removeCloseFriend(uid);
            if (mounted) {
              setState(() => _isCloseFriend = false);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.user.name} removed from Close Friends')),
              );
            }
          } else {
            await _settingsApi.addCloseFriend(uid);
            if (mounted) {
              setState(() => _isCloseFriend = true);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.user.name} added to Close Friends')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red.shade700),
            );
          }
        }
        break;
      case 'block':
        try {
          await _settingsApi.blockUser(uid);
          if (mounted) {
            setState(() => _isBlocked = true);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.user.name} blocked')),
            );
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to block'), backgroundColor: Colors.red.shade700),
            );
          }
        }
        break;
      case 'unblock':
        try {
          await _settingsApi.unblockUser(uid);
          if (mounted) {
            setState(() => _isBlocked = false);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.user.name} unblocked')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to unblock'), backgroundColor: Colors.red.shade700),
            );
          }
        }
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'mute':
        try {
          await _settingsApi.muteUser(uid);
          if (mounted) {
            setState(() => _isMuted = true);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Muted ${widget.user.name}'s messages")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to mute'), backgroundColor: Colors.red.shade700),
            );
          }
        }
        break;
      case 'unmute':
        try {
          await _settingsApi.unmuteUser(uid);
          if (mounted) {
            setState(() => _isMuted = false);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unmuted ${widget.user.name}'s messages")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to unmute'), backgroundColor: Colors.red.shade700),
            );
          }
        }
        break;
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this account'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for report (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reason = reasonController.text.trim().isEmpty
                  ? 'Reported from profile'
                  : reasonController.text.trim();
              final token = context.read<AuthProvider>().token;
              if (token == null) return;
              _settingsApi.setToken(token);
              try {
                await _settingsApi.reportUser(uid: widget.user.uid, reason: reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit report'), backgroundColor: Colors.red.shade700),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    if (_isBlockedView) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(user.username),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  "You can't view this profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "This account has blocked you or you have blocked them.",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(user.username),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (!_isOwnProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onSelected: _onProfileMenuSelected,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'close_friend',
                  child: Row(
                    children: [
                      Icon(_isCloseFriend ? Icons.person_remove : Icons.person_add, size: 22, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Text(_isCloseFriend ? 'Remove from Close Friends' : 'Add to Close Friends'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _isBlocked ? 'unblock' : 'block',
                  child: Row(
                    children: [
                      Icon(_isBlocked ? Icons.lock_open : Icons.block, size: 22, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Text(_isBlocked ? 'Unblock' : 'Block this account'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 22, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Report this account'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _isMuted ? 'unmute' : 'mute',
                  child: Row(
                    children: [
                      Icon(_isMuted ? Icons.notifications : Icons.notifications_off_outlined, size: 22, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Text(_isMuted ? "Unmute this account's messages" : "Mute this account's messages"),
                    ],
                  ),
                ),
              ],
            ),
        ],
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
                            child: _isFollowPending
                                ? OutlinedButton(
                                    onPressed: _followLoading
                                        ? null
                                        : () async {
                                            // Optimistic: show Follow immediately
                                            setState(() {
                                              _isFollowPending = false;
                                              _followLoading = true;
                                            });
                                            final error = await _profileService.unfollowUser(
                                              widget.user.uid,
                                            );
                                            if (!mounted) return;
                                            setState(() => _followLoading = false);
                                            if (error != null) {
                                              setState(() => _isFollowPending = true);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(error),
                                                    backgroundColor: Colors.red.shade700,
                                                  ),
                                                );
                                              }
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Request cancelled"),
                                                ),
                                              );
                                            }
                                          },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                      side: BorderSide(color: Colors.grey.shade400),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text("Requested"),
                                  )
                                : ElevatedButton(
                                    onPressed: _followLoading
                                        ? null
                                        : () async {
                                            final wasFollowing = _isFollowing;
                                            final isPrivate = widget.user.isPrivate == true;
                                            // Optimistic: update button state immediately
                                            setState(() {
                                              _followLoading = true;
                                              if (wasFollowing) {
                                                _isFollowing = false;
                                              } else {
                                                if (isPrivate) {
                                                  _isFollowPending = true;
                                                } else {
                                                  _isFollowing = true;
                                                }
                                              }
                                            });
                                            final error = wasFollowing
                                                ? await _profileService.unfollowUser(
                                                      widget.user.uid,
                                                    )
                                                : await _profileService.followUser(
                                                      widget.user.uid,
                                                    );
                                            if (!mounted) return;
                                            setState(() => _followLoading = false);
                                            if (error != null) {
                                              setState(() {
                                                _isFollowing = wasFollowing;
                                                _isFollowPending = wasFollowing ? _isFollowPending : false;
                                              });
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(error),
                                                    backgroundColor: Colors.red.shade700,
                                                  ),
                                                );
                                              }
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    wasFollowing
                                                        ? "Unfollowed ${widget.user.name}"
                                                        : _isFollowPending
                                                            ? "Request sent"
                                                            : "Following ${widget.user.name}",
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
                                    child: Text(_isFollowing ? "Following" : "Follow"),
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

              if (!_canSeePosts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        "This Account is Private",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Follow to see photos and videos.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_loading)
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
