import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import 'user_profile_screen.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String username;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<Map<String, dynamic>> _followers = [];
  final Map<String, bool> _isFollowing = {};
  final Map<String, bool> _isFollowPending = {};
  final Map<String, bool> _buttonLoading = {};
  /// True when this route is the current (top) route. Used to refresh when user navigates back.
  bool _isCurrentRoute = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  bool _restricted = false;

  /// Stable id from API user map (_id string or $oid, else uid).
  static String _userId(Map<String, dynamic> u) {
    final id = u['_id'];
    if (id is String && id.isNotEmpty) return id;
    if (id is Map) {
      final oid = id['\$oid'] ?? id['oid'];
      if (oid != null) return oid.toString();
    }
    return (u['uid'] ?? '').toString();
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;
    final currentUid = context.read<AuthProvider>().user?.uid;

    setState(() => _loading = true);
    try {
      final result = await _profileService.getFollowers(widget.userId);
      final data = List<Map<String, dynamic>>.from(result['followers'] ?? []);
      final restricted = result['restricted'] == true;

      Set<String> myFollowingIds = {};
      Set<String> myPendingIds = {};
      if (currentUid != null && currentUid.isNotEmpty) {
        try {
          myPendingIds = await _profileService.getMyPendingFollowingIds();
          final myFollowing = await _profileService.getFollowing(currentUid);
          final list = List<Map<String, dynamic>>.from(myFollowing['following'] ?? []);
          for (final u in list) {
            final uid = _userId(Map<String, dynamic>.from(u));
            if (uid.isEmpty) continue;
            if (u['isFollowing'] == true) myFollowingIds.add(uid);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _followers = data;
          _restricted = restricted;
          for (final u in data) {
            final uid = _userId(Map<String, dynamic>.from(u));
            if (uid.isEmpty) continue;
            final pending = u['isFollowPending'] == true || myPendingIds.contains(uid);
            final following = u['isFollowing'] == true || myFollowingIds.contains(uid);
            _isFollowPending[uid] = pending;
            _isFollowing[uid] = !pending && following;
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
          _isFollowing[uid] = false;
          _isFollowPending[uid] = false;
        } else {
          _isFollowing[uid] = followStatusResult == 'accepted';
          _isFollowPending[uid] = followStatusResult == 'pending';
        }
      } else {
        // Sync UI when API says we're already following or request is pending
        final lower = error.toLowerCase();
        if (lower.contains('pending') || lower.contains('request already')) {
          _isFollowPending[uid] = true;
          _isFollowing[uid] = false;
        } else if (lower.contains('already following')) {
          _isFollowing[uid] = true;
          _isFollowPending[uid] = false;
        } else {
          _isFollowing[uid] = currentlyFollowing;
          _isFollowPending[uid] = currentlyPending;
        }
      }
    });
    if (error != null && context.mounted) {
      final lower = error.toLowerCase();
      final isAlreadyState = lower.contains('pending') ||
          lower.contains('request already') ||
          lower.contains('already following');
      if (!isAlreadyState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh when user navigates back to this screen so "Requested"/"Following" stay correct
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) {
      _isCurrentRoute = false;
    } else {
      if (!_isCurrentRoute) {
        _isCurrentRoute = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadFollowers();
        });
      }
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text("${widget.username} • Followers"),
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
              : _followers.isEmpty
                  ? const Center(child: Text("No followers yet"))
                  : ListView.separated(
                  itemCount: _followers.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                    final scheme = Theme.of(context).colorScheme;
                    final u = _followers[index];
                    final uid = _userId(Map<String, dynamic>.from(u));
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
