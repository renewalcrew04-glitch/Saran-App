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
  final Map<String, bool> _buttonLoading = {};

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  bool _restricted = false;

  Future<void> _loadFollowing() async {
    final currentUid = context.read<AuthProvider>().user?.uid;
    setState(() => _loading = true);
    try {
      final result = await _profileService.getFollowing(widget.userId);
      final data = List<Map<String, dynamic>>.from(result['following'] ?? []);
      final restricted = result['restricted'] == true;
      // Resolve who *we* follow so the button shows "Following" vs "Follow" correctly
      final Set<String> myFollowingUids = {};
      if (currentUid != null && currentUid.isNotEmpty && !restricted) {
        final myResult = await _profileService.getFollowing(currentUid);
        final myFollowing = List<Map<String, dynamic>>.from(myResult['following'] ?? []);
        myFollowingUids.addAll(
          myFollowing
              .map((u) => (u['uid'] ?? u['_id'] ?? '').toString())
              .where((s) => s.isNotEmpty),
        );
      }
      if (mounted) {
        setState(() {
          _following = data;
          _restricted = restricted;
          for (final u in data) {
            final uid = (u['uid'] ?? u['_id'] ?? '').toString();
            if (uid.isNotEmpty) {
              _isFollowing[uid] = myFollowingUids.contains(uid);
            }
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

  Future<void> _toggleFollow(String uid, bool currentlyFollowing) async {
    if (_buttonLoading[uid] == true) return;
    final currentUid = context.read<AuthProvider>().user?.uid;
    final isOwnList = currentUid != null && widget.userId == currentUid;
    setState(() {
      _buttonLoading[uid] = true;
      _isFollowing[uid] = !currentlyFollowing;
    });
    final error = currentlyFollowing
        ? await _profileService.unfollowUser(uid)
        : await _profileService.followUser(uid);
    if (!mounted) return;
    setState(() {
      _buttonLoading[uid] = false;
      if (error != null) {
        _isFollowing[uid] = currentlyFollowing;
      } else if (currentlyFollowing && isOwnList) {
        // Unfollowed from our own following list: remove from list so count stays correct
        _following.removeWhere((u) => (u['uid'] ?? u['_id'] ?? '').toString() == uid);
        _isFollowing.remove(uid);
      }
    });
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.username} • Following"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
                        Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          "Only accepted followers can see this list.",
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
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
                      Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final u = _following[index];
                    final uid = (u['uid'] ?? u['_id'] ?? '').toString();
                    final name = (u['name'] ?? '').toString();
                    final username = (u['username'] ?? '').toString();
                    final avatar = u['avatar']?.toString();
                    final isFollowing = _isFollowing[uid] ?? false;
                    final loading = _buttonLoading[uid] ?? false;

                    return ListTile(
                      onTap: () => _openProfile(u),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            avatar != null && avatar.startsWith('http')
                                ? NetworkImage(avatar)
                                : null,
                        child: avatar == null || !avatar.startsWith('http')
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.white,
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
                        child: isFollowing
                            ? OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => _toggleFollow(uid, true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: const Size(100, 36),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Following",
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () => _toggleFollow(uid, false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: const Size(100, 36),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Follow",
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
