import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../utils/media_utils.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/profile_service.dart';
import '../../features/settings/services/settings_api.dart';
import '../messages/chat_screen.dart';
import '../post/post_detail_screen.dart';
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
  int _followersCount = 0;
  int _followingCount = 0;
  String _contentFilter = 'All'; // All, Texts, Photos, Videos, Reposts

  @override
  void initState() {
    super.initState();
    _followersCount = widget.user.followersCount;
    _followingCount = widget.user.followingCount;
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
        // Use API profile's isPrivate so we don't wrongly treat private accounts as public
        // (widget.user may come from a list that doesn't include isPrivate)
        final isPrivateAccount = profile['isPrivate'] == true;
        bool following = profile['isFollowing'] == true;
        bool pending = profile['isFollowPending'] == true;
        // Public accounts: direct follow only, never show "Requested"
        if (!isPrivateAccount && pending) {
          following = true;
          pending = false;
        }
        final fc = (profile['followersCount'] as num?)?.toInt();
        final fg = (profile['followingCount'] as num?)?.toInt();
        setState(() {
          _isFollowing = following;
          _isFollowPending = pending;
          if (fc != null) _followersCount = fc;
          if (fg != null) _followingCount = fg;
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

  List<Post> get _filteredPosts {
    switch (_contentFilter) {
      case 'Texts':
        return _posts.where((p) => p.type == 'text' || p.media.isEmpty).toList();
      case 'Photos':
        return _posts.where((p) {
          if (p.type == 'video') return false;
          return p.type == 'photo' || p.type == 'image' || p.media.isNotEmpty;
        }).toList();
      case 'Videos':
        return _posts.where((p) => p.type == 'video').toList();
      case 'Reposts':
        return _posts
            .where((p) =>
                p.type == 'repost' ||
                p.type == 'quote' ||
                p.isQuote ||
                (p.repostedByUid != null && p.repostedByUid!.isNotEmpty))
            .toList();
      default:
        return _posts;
    }
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
    return safeNetworkImage(url: url, fit: BoxFit.cover);
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reports are reviewed within 24 hours. Violating content may be removed and accounts may be restricted.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for report (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
                    const SnackBar(content: Text("Report submitted. We'll review within 24 hours.")),
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

    final scheme = Theme.of(context).colorScheme;
    if (_isBlockedView) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: Text(user.username),
          backgroundColor: scheme.surface,
          elevation: 0,
          foregroundColor: scheme.onSurface,
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
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(user.username),
        backgroundColor: scheme.surface,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        actions: [
          if (!_isOwnProfile)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: scheme.onSurface),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover (same height as own profile)
              Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: user.coverImage != null && user.coverImage!.isNotEmpty
                    ? safeNetworkImage(
                        url: ApiConfig.networkImageUrl(user.coverImage!) ?? user.coverImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        placeholderIcon: Icons.photo_camera_outlined,
                      )
                    : Center(child: Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[500])),
              ),
              // Avatar overlapping cover (same as own profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(16, -48),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _UserProfileAvatar(avatarUrl: user.avatar, name: user.name, radius: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '@${user.username}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          user.bio!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Location',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats row (same as own profile: posts | followers | following)
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            count: _posts.length,
                            label: 'posts',
                            onTap: () {},
                          ),
                        ),
                        Expanded(
                          child: _ProfileStat(
                            count: _followersCount,
                            label: 'followers',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowersListScreen(
                                    userId: user.uid,
                                    username: user.username,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _ProfileStat(
                            count: _followingCount,
                            label: 'following',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowingListScreen(
                                    userId: user.uid,
                                    username: user.username,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action row (same style as own profile: Edit | Share | +)
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
                          flex: 1,
                          child: SizedBox(
                            height: 44,
                            width: double.infinity,
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
                                              final lower = error.toLowerCase();
                                              if (context.mounted &&
                                                  !lower.contains('pending') &&
                                                  !lower.contains('request already') &&
                                                  !lower.contains('already following')) {
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
                                            // Optimistic: public = direct follow (Following); private = request (Requested)
                                            setState(() {
                                              _followLoading = true;
                                              if (wasFollowing) {
                                                _isFollowing = false;
                                              } else {
                                                if (isPrivate) {
                                                  _isFollowPending = true;
                                                } else {
                                                  // Public account: direct follow, no request
                                                  _isFollowing = true;
                                                  _isFollowPending = false;
                                                }
                                              }
                                            });
                                            final unfollowError = wasFollowing
                                                ? await _profileService.unfollowUser(widget.user.uid)
                                                : null;
                                            final followResult = wasFollowing ? null : await _profileService.followUser(widget.user.uid);
                                            final error = wasFollowing ? unfollowError : followResult?.error;
                                            final followStatus = followResult?.status;
                                            if (!mounted) return;
                                            setState(() {
                                              _followLoading = false;
                                              if (error == null) {
                                                if (wasFollowing) {
                                                  _followersCount = (_followersCount - 1).clamp(0, 1 << 30);
                                                } else {
                                                  _isFollowPending = followStatus == 'pending';
                                                  _isFollowing = followStatus == 'accepted';
                                                  if (!_isFollowPending) _followersCount++;
                                                }
                                              } else {
                                                final lower = error.toLowerCase();
                                                if (lower.contains('pending') || lower.contains('request already')) {
                                                  _isFollowPending = true;
                                                  _isFollowing = false;
                                                } else if (lower.contains('already following')) {
                                                  _isFollowing = true;
                                                  _isFollowPending = false;
                                                } else {
                                                  _isFollowing = wasFollowing;
                                                  _isFollowPending = wasFollowing ? _isFollowPending : false;
                                                }
                                              }
                                            });
                                            if (error != null && context.mounted) {
                                              final lower = error.toLowerCase();
                                              if (!lower.contains('pending') &&
                                                  !lower.contains('request already') &&
                                                  !lower.contains('already following')) {
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
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(_isFollowing ? "Following" : "Follow"),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 44,
                            width: double.infinity,
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
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Main tab bar (Post only, same style as own profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ProfileLabelTab(
                      icon: Icons.grid_on_outlined,
                      label: 'Post',
                      isActive: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Post sub-tabs: All, Texts, Photos, Videos, Reposts (icons only, space between)
              if (_canSeePosts && !_loading && _posts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PostSubTab(
                        icon: Icons.apps,
                        isActive: _contentFilter == 'All',
                        onTap: () => setState(() => _contentFilter = 'All'),
                      ),
                      _PostSubTab(
                        icon: Icons.text_fields,
                        isActive: _contentFilter == 'Texts',
                        onTap: () => setState(() => _contentFilter = 'Texts'),
                      ),
                      _PostSubTab(
                        icon: Icons.image_outlined,
                        isActive: _contentFilter == 'Photos',
                        onTap: () => setState(() => _contentFilter = 'Photos'),
                      ),
                      _PostSubTab(
                        icon: Icons.videocam_outlined,
                        isActive: _contentFilter == 'Videos',
                        onTap: () => setState(() => _contentFilter = 'Videos'),
                      ),
                      _PostSubTab(
                        icon: Icons.repeat,
                        isActive: _contentFilter == 'Reposts',
                        onTap: () => setState(() => _contentFilter = 'Reposts'),
                      ),
                    ],
                  ),
                ),

              if (_canSeePosts && !_loading && _posts.isNotEmpty) const SizedBox(height: 12),

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
                  child: _filteredPosts.isEmpty
                      ? SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'No $_contentFilter yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredPosts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            final embedded = post.quotedPost ?? post.originalPost;
                            final mediaUrls = post.media.isNotEmpty
                                ? post.media
                                : (embedded?.media ?? []);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(
                                      posts: _filteredPosts,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  color: Colors.grey.shade200,
                                  child: mediaUrls.isNotEmpty
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _buildPostMedia(mediaUrls.first),
                                            if (post.type == 'video' || embedded?.type == 'video')
                                              Positioned(
                                                right: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            if (post.type == 'repost' ||
                                                post.type == 'quote' ||
                                                post.isQuote)
                                              Positioned(
                                                left: 8,
                                                top: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    post.isQuote || post.type == 'quote'
                                                        ? Icons.format_quote
                                                        : Icons.repeat,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(10),
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            post.text.isNotEmpty ? post.text : 'Text',
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                ),
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

class _UserProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const _UserProfileAvatar({this.avatarUrl, required this.name, this.radius = 42});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl != null && avatarUrl!.isNotEmpty
        ? (ApiConfig.networkImageUrl(avatarUrl!) ?? avatarUrl)
        : null;
    final size = radius * 2;
    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: TextStyle(fontSize: radius * 0.62, fontWeight: FontWeight.bold),
        ),
      );
    }
    return safeAvatarNetworkImage(
      url: url,
      size: size,
      backgroundColor: Colors.grey.shade300,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _ProfileStat({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLabelTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileLabelTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostSubTab extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PostSubTab({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 20, color: isActive ? Colors.white : Colors.black),
      ),
    );
  }
}
