import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/features/menu/menu_sheet.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/profile_update_service.dart';
import '../../services/upload_service.dart';
import '../messages/chat_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FeedService _feedService = FeedService();
  final UploadService _uploadService = UploadService();
  final ProfileUpdateService _profileUpdateService = ProfileUpdateService();
  final ImagePicker _picker = ImagePicker();

  List<Post> _posts = [];
  bool _isLoading = true;

  int _wellnessStreak = 0;
  List<String> _wellnessHistory = [];
  bool _wellnessLoading = true;

  // Main Tabs
  String _activeMainTab = 'posts'; // posts, wellness, games, saved

  // Sub Tabs (inside Posts)
  String _activePostTab = 'all'; // all, text, photo, video, repost

  // Local previews (KEEP - not used now but safe)
  File? _localCoverPreview;
  File? _localAvatarPreview;

  bool _uploadingCover = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
    _loadWellnessStreak();
  }

  Future<void> _loadWellnessStreak() async {
    setState(() => _wellnessLoading = true);

    try {
      final s = await WellnessStreakService.getStreak();
      final h = await WellnessStreakService.getHistory();

      if (!mounted) return;
      setState(() {
        _wellnessStreak = s;
        _wellnessHistory = h;
        _wellnessLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _wellnessLoading = false);
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user?.uid != null) {
        final posts = await _feedService.getUserFeed(authProvider.user!.uid);
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Post> get _filteredPosts {
    if (_activePostTab == 'all') return _posts;

    if (_activePostTab == 'text') {
      return _posts.where((p) => p.type == 'text').toList();
    }

    if (_activePostTab == 'photo') {
      return _posts.where((p) => p.type == 'photo').toList();
    }

    if (_activePostTab == 'video') {
      return _posts.where((p) => p.type == 'video').toList();
    }

    if (_activePostTab == 'repost') {
      return _posts.where((p) => p.type == 'repost').toList();
    }

    return _posts;
  }

  // KEEP THESE (not used now because camera icons removed)
  Future<void> _pickCoverImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localCoverPreview = File(picked.path);
      });

      setState(() => _uploadingCover = true);

      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) throw Exception("No token");

      final url = await _uploadService.uploadSingle(
        token: token,
        file: File(picked.path),
      );

      await _profileUpdateService.updateCover(url);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cover updated")),
      );

      setState(() => _uploadingCover = false);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUser();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update cover")),
      );
    }
  }

  Future<void> _pickAvatarImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localAvatarPreview = File(picked.path);
      });

      setState(() => _uploadingAvatar = true);

      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) throw Exception("No token");

      final url = await _uploadService.uploadSingle(
        token: token,
        file: File(picked.path),
      );

      await _profileUpdateService.updateAvatar(url);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Avatar updated")),
      );

      setState(() => _uploadingAvatar = false);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadUser();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update avatar")),
      );
    }
  }

  Future<void> _openDm(
    BuildContext context,
    String otherUid,
    String otherName,
    String? otherAvatar,
  ) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final dm = context.read<DmProvider>();

    final convoId = await dm.openDm(
      token: token,
      otherUid: otherUid,
    );

    if (convoId == null || convoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open chat")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convoId,
          otherUserId: otherUid,
          otherName: otherName,
          otherAvatar: otherAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          user.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
  icon: const Icon(Icons.notifications_none, color: Colors.black),
  onPressed: () {
    context.push('/notifications');
  },
),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.menu, color: Colors.grey[800], size: 20),
            ),
            onPressed: () {
              MenuSheet.open(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserPosts();
          await _loadWellnessStreak();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              const SizedBox(height: 8),
              _buildMainTabs(),
              if (_activeMainTab == 'posts') _buildPostSubTabs(),
              _buildBodyContent(user),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Column(
      children: [
        // Cover Image
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: _localCoverPreview != null
                  ? Image.file(_localCoverPreview!, fit: BoxFit.cover)
                  : (user.coverImage != null && user.coverImage!.isNotEmpty
                      ? Image.network(
                          user.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(Icons.image, color: Colors.grey, size: 40),
                        )),
            ),

            // Avatar (NO camera icon now)
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
                  backgroundImage: _localAvatarPreview != null
                      ? FileImage(_localAvatarPreview!)
                      : (user.avatar != null && user.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null) as ImageProvider?,
                  child: ((user.avatar == null || user.avatar!.isEmpty) &&
                          _localAvatarPreview == null)
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
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

        // Name + Bio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              if (user.bio != null && user.bio.toString().trim().isNotEmpty)
                Text(
                  user.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.35,
                  ),
                ),

              const SizedBox(height: 14),

              // Edit Profile button (CONNECTED + REFRESH)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );

                    // refresh user + posts after edit
                    if (!mounted) return;
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.loadUser();
                    await _loadUserPosts();
                  },
                  icon: const Icon(Icons.edit, size: 18, color: Colors.black),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats row (clickable)
              Row(
                children: [
                  Expanded(
                    child: _StatButton(
                      count: _posts.length,
                      label: 'Posts',
                      onTap: () {
                        setState(() {
                          _activeMainTab = 'posts';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      count: user.followersCount,
                      label: 'Followers',
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
                    child: _StatButton(
                      count: user.followingCount,
                      label: 'Following',
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
              _buildWellnessPreviewCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessPreviewCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await _loadWellnessStreak();
        if (!mounted) return;
        context.push('/wellness');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEDED)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Wellness",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _wellnessLoading
                      ? const Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          "Streak: $_wellnessStreak day${_wellnessStreak == 1 ? '' : 's'} • Activities: ${_wellnessHistory.length}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _MainTabChip(
                icon: Icons.grid_on,
                label: 'Posts',
                isActive: _activeMainTab == 'posts',
                onTap: () => setState(() => _activeMainTab = 'posts'),
              ),
            ),
            Expanded(
              child: _MainTabChip(
                icon: Icons.favorite_border,
                label: 'Wellness',
                isActive: _activeMainTab == 'wellness',
                onTap: () async {
                  await _loadWellnessStreak();
                  if (!mounted) return;
                  context.push('/wellness');
                },
              ),
            ),
            Expanded(
              child: _MainTabChip(
                icon: Icons.sports_esports_outlined,
                label: 'Games',
                isActive: _activeMainTab == 'games',
                onTap: () {
                  context.push('/games');
                },
              ),
            ),
            Expanded(
              child: _MainTabChip(
                icon: Icons.bookmark_border,
                label: 'Saved',
                isActive: _activeMainTab == 'saved',
                onTap: () => setState(() => _activeMainTab = 'saved'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostSubTabs() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PostFilterChip(
              label: 'All',
              isActive: _activePostTab == 'all',
              onTap: () => setState(() => _activePostTab = 'all'),
            ),
            _PostFilterChip(
              label: 'Texts',
              isActive: _activePostTab == 'text',
              onTap: () => setState(() => _activePostTab = 'text'),
            ),
            _PostFilterChip(
              label: 'Photos',
              isActive: _activePostTab == 'photo',
              onTap: () => setState(() => _activePostTab = 'photo'),
            ),
            _PostFilterChip(
              label: 'Videos',
              isActive: _activePostTab == 'video',
              onTap: () => setState(() => _activePostTab = 'video'),
            ),
            _PostFilterChip(
              label: 'Reposts',
              isActive: _activePostTab == 'repost',
              onTap: () => setState(() => _activePostTab = 'repost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(dynamic user) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeMainTab == 'posts') {
      return _buildPostsGrid();
    }

    if (_activeMainTab == 'games') {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Games')),
      );
    }

    if (_activeMainTab == 'saved') {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Saved - Coming soon')),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPostsGrid() {
    final list = _filteredPosts;

    if (list.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No posts yet')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          final post = list[index];

          return GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.grey.shade200,
                child: _PostGridTile(post: post),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostGridTile extends StatelessWidget {
  final Post post;

  const _PostGridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.media.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          buildSafeImage(post.media.first),
          if (post.type == 'video')
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
            ),
          if (post.type == 'repost')
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.repeat, color: Colors.white, size: 16),
              ),
            ),
        ],
      );
    }

    return Container(
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
    );
  }
}

Widget buildSafeImage(String path) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image)),
  );
}

class _StatButton extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatButton({
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
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainTabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MainTabChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.black : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PostFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
