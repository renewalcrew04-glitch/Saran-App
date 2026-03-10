import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import 'user_profile_screen.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;
  final String username;

  const FollowingListScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<Map<String, dynamic>> _following = [];
  final Map<String, bool> _isFollowing = {};
  final Map<String, bool> _isFollowPending = {};
  final Map<String, bool> _buttonLoading = {};
  bool _isCurrentRoute = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  bool _restricted = false;

  Future<void> _loadFollowing() async {
    if (!mounted) return;
    final currentUid = context.read<AuthProvider>().user?.uid;
    final isOwnList = currentUid != null &&
        currentUid.isNotEmpty &&
        widget.userId == currentUid;

    setState(() => _loading = true);
    try {
      final result = await _profileService.getFollowing(widget.userId);
      final data = List<Map<String, dynamic>>.from(result['following'] ?? []);
      final restricted = result['restricted'] == true;
      if (mounted) {
        setState(() {
          _following = data;
          _restricted = restricted;
          for (final u in data) {
            final uid = (u['uid'] ?? u['_id'] ?? '').toString();
            if (uid.isEmpty) continue;
            // When viewing our own following list, everyone here is someone we follow
            final rawFollowing = u['isFollowing'] == true;
            final rawPending = u['isFollowPending'] == true;
            _isFollowing[uid] = rawFollowing || (isOwnList && !rawPending);
            _isFollowPending[uid] = rawPending;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile(Map<String, dynamic> u) {
    final user = User.fromJson(Map<String, dynamic>.from(u));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  Future<void> _toggleFollow(String uid, bool currentlyFollowing, bool currentlyPending) async {
    if (_buttonLoading[uid] == true) return;
    final currentUid = context.read<AuthProvider>().user?.uid;
    final isOwnList = currentUid != null && widget.userId == currentUid;
    setState(() {
      _buttonLoading[uid] = true;
      if (currentlyFollowing || currentlyPending) {
        _isFollowing[uid] = false;
        _isFollowPending[uid] = false;
      }
    });
    String? error;
    String? followStatusResult;
    if (currentlyFollowing || currentlyPending) {
      error = await _profileService.unfollowUser(uid);
    } else {
      final res = await _profileService.followUser(uid);
      error = res.error;
      followStatusResult = res.status;
    }
    if (!mounted) return;
    setState(() {
      _buttonLoading[uid] = false;
      if (error == null) {
        if (currentlyFollowing || currentlyPending) {
          if (currentlyFollowing && isOwnList) {
            _following.removeWhere((u) => (u['uid'] ?? u['_id'] ?? '').toString() == uid);
            _isFollowing.remove(uid);
            _isFollowPending.remove(uid);
          } else {
            _isFollowing[uid] = false;
            _isFollowPending[uid] = false;
          }
        } else {
          _isFollowing[uid] = followStatusResult == 'accepted';
          _isFollowPending[uid] = followStatusResult == 'pending';
        }
      } else {
        _isFollowing[uid] = currentlyFollowing;
        _isFollowPending[uid] = currentlyPending;
      }
    });
    if (error != null && context.mounted) {
      final lower = error.toLowerCase();
      if (!lower.contains('pending') && !lower.contains('request already') && !lower.contains('already following')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) {
      _isCurrentRoute = false;
    } else {
      if (!_isCurrentRoute) {
        _isCurrentRoute = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadFollowing();
        });
      }
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text("${widget.username} • Following"),
        backgroundColor: scheme.surface,
        elevation: 0,
        foregroundColor: scheme.onSurface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _restricted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          "Only accepted followers can see this list.",
                          style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _following.isEmpty
                  ? const Center(child: Text("Not following anyone yet"))
                  : ListView.separated(
                  itemCount: _following.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: scheme.outlineVariant),
                  itemBuilder: (context, index) {
                    final u = _following[index];
                    final uid = (u['uid'] ?? u['_id'] ?? '').toString();
                    final name = (u['name'] ?? '').toString();
                    final username = (u['username'] ?? '').toString();
                    final avatar = u['avatar']?.toString();
                    final isFollowing = _isFollowing[uid] ?? false;
                    final isFollowPending = _isFollowPending[uid] ?? false;
                    final loading = _buttonLoading[uid] ?? false;

                    Widget trailingButton;
                    if (isFollowing) {
                      trailingButton = OutlinedButton(
                        onPressed: loading ? null : () => _toggleFollow(uid, true, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          side: BorderSide(color: scheme.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(100, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Following", maxLines: 1, overflow: TextOverflow.visible),
                      );
                    } else if (isFollowPending) {
                      trailingButton = OutlinedButton(
                        onPressed: loading ? null : () => _toggleFollow(uid, false, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          side: BorderSide(color: scheme.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(100, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Requested", maxLines: 1, overflow: TextOverflow.visible),
                      );
                    } else {
                      trailingButton = ElevatedButton(
                        onPressed: loading ? null : () => _toggleFollow(uid, false, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(100, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Follow", maxLines: 1, overflow: TextOverflow.visible),
                      );
                    }

                    return ListTile(
                      onTap: () => _openProfile(u),
                      leading: CircleAvatar(
                        backgroundColor: scheme.surfaceContainerHighest,
                        backgroundImage:
                            avatar != null && avatar.startsWith('http')
                                ? NetworkImage(avatar)
                                : null,
                        child: avatar == null || !avatar.startsWith('http')
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text("@$username"),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 100),
                        child: trailingButton,
                      ),
                    );
                  },
                ),
    );
  }
}
