import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/explore_service.dart';
import '../../services/profile_service.dart';
import '../../utils/media_utils.dart';
import '../profile/user_profile_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0E1A);
const _kCard   = Color(0xFF111827);
const _kBorder = Color(0xFF1E2535);
const _kText   = Color(0xFFF1F5F9);
const _kMuted  = Color(0xFF94A3B8);
const _kOrange = Color(0xFFFF8132);

class ExplorePeopleScreen extends StatefulWidget {
  const ExplorePeopleScreen({super.key});

  @override
  State<ExplorePeopleScreen> createState() => _ExplorePeopleScreenState();
}

class _ExplorePeopleScreenState extends State<ExplorePeopleScreen> {
  final _service        = ExploreService();
  final _profileService = ProfileService();

  List<User> _people = [];
  bool _loading = true;

  final Set<String> _followingIds = {};
  final Set<String> _pendingIds   = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getSuggestions(limit: 50);
      if (!mounted) return;
      setState(() { _people = list; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }

    // Load follow state
    final myUid = context.read<AuthProvider>().user?.uid;
    if (myUid == null || myUid.isEmpty) return;
    try {
      final result = await _profileService.getFollowing(myUid);
      final followList = List<Map<String, dynamic>>.from(result['following'] ?? []);
      final pendingIds = await _profileService.getMyPendingFollowingIds();
      if (!mounted) return;
      setState(() {
        for (final u in followList) {
          final uid = (u['uid'] ?? u['_id'] ?? '').toString();
          if (uid.isNotEmpty && u['isFollowing'] == true) _followingIds.add(uid);
        }
        _pendingIds.addAll(pendingIds);
      });
    } catch (_) {}
  }

  Future<void> _onFollow(User user) async {
    final uid = user.uid;
    if (uid.isEmpty) return;
    if (_followingIds.contains(uid) || _pendingIds.contains(uid)) {
      final err = await _profileService.unfollowUser(uid);
      if (!mounted) return;
      if (err == null) {
        setState(() { _followingIds.remove(uid); _pendingIds.remove(uid); });
      }
      return;
    }
    final result = await _profileService.followUser(uid);
    if (!mounted) return;
    if (result.error == null) {
      setState(() {
        if (result.status == 'pending') _pendingIds.add(uid);
        else _followingIds.add(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'People You May Know',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : _people.isEmpty
              ? const Center(
                  child: Text(
                    'No suggestions right now.',
                    style: TextStyle(color: _kMuted, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _people.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: _kBorder,
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, i) {
                    final u = _people[i];
                    final isFollowing = _followingIds.contains(u.uid) || u.isFollowing == true;
                    final isPending   = _pendingIds.contains(u.uid) || u.isFollowPending == true;
                    return _PeopleTile(
                      user: u,
                      isFollowing: isFollowing,
                      isPending: isPending,
                      onFollow: () => _onFollow(u),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserProfileScreen(user: u)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PeopleTile extends StatelessWidget {
  final User user;
  final bool isFollowing;
  final bool isPending;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _PeopleTile({
    required this.user,
    required this.isFollowing,
    required this.isPending,
    required this.onFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatar != null ? ApiConfig.networkImageUrl(user.avatar!) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            safeAvatarNetworkImage(url: avatarUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.username,
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: (isFollowing || isPending) ? _kCard : _kOrange,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isFollowing || isPending) ? _kBorder : _kOrange,
                  ),
                ),
                child: Text(
                  isFollowing ? 'Following' : isPending ? 'Requested' : 'Follow',
                  style: TextStyle(
                    color: (isFollowing || isPending) ? _kMuted : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
