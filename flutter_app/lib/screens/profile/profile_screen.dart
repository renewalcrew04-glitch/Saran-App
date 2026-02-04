import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/features/menu/menu_sheet.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

import '../../models/post_model.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/feed_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_update_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/post_card.dart';
import 'edit_profile_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';
import '../post/post_detail_screen.dart';

/// When this notifier's value equals [kProfileTabIndex], profile will refresh posts.
const int kProfileTabIndex = 4;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.tabIndexNotifier});

  /// When the main nav switches to Profile tab, this is set to [kProfileTabIndex].
  /// Profile screen refreshes posts when that happens so new posts appear.
  final ValueNotifier<int>? tabIndexNotifier;

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

  // Tabs: Post, Wellness, Games, Saved
  String _activeMainTab = 'post';

  List<Post> _savedPosts = [];
  bool _savedLoading = false;

  File? _localAvatarPreview;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    widget.tabIndexNotifier?.addListener(_onTabIndexChanged);
    // Defer so we don't call loadUser() (notifyListeners) during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshUserCounts();
      _loadUserPosts();
      _loadWellnessStreak();
    });
  }

  Future<void> _refreshUserCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser();
  }

  void _onTabIndexChanged() {
    if (widget.tabIndexNotifier?.value == kProfileTabIndex && mounted) {
      _refreshProfile();
    }
  }

  Future<void> _refreshProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser();
    if (mounted) _loadUserPosts();
  }

  @override
  void dispose() {
    widget.tabIndexNotifier?.removeListener(_onTabIndexChanged);
    super.dispose();
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
      final uid = authProvider.user?.uid.trim() ?? '';

      if (uid.isEmpty) {
        await authProvider.loadUser();
        final retryUid = authProvider.user?.uid.trim() ?? '';
        if (retryUid.isEmpty) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final posts = await _feedService.getUserFeed(retryUid);
        if (mounted) {
          setState(() {
            _posts = posts;
            _isLoading = false;
          });
        }
        return;
      }

      final posts = await _feedService.getUserFeed(uid);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = 'Could not load posts.';
        if (e.toString().contains('404')) {
          msg = 'Profile posts unavailable. Pull to refresh or log out and back in.';
        } else if (e.toString().contains('500')) {
          msg = 'Server error. Please try again later.';
        } else {
          final raw = e.toString().replaceFirst('Exception: ', '');
          if (!raw.contains('DioException') && raw.length < 80) msg = raw;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<void> _pickAvatarImage() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) throw Exception("No token");

      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localAvatarPreview = File(picked.path);
      });

      setState(() => _uploadingAvatar = true);

      final url = await _uploadService.uploadSingle(
        token: token,
        file: File(picked.path),
      );

      await _profileUpdateService.updateAvatar(url, currentUserUid: auth.user?.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Avatar updated")),
      );

      setState(() => _uploadingAvatar = false);

      await auth.loadUser();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update avatar")),
      );
    }
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
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.grey[800], size: 24),
            onPressed: () => MenuSheet.open(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.loadUser();
          await _loadUserPosts();
          await _loadWellnessStreak();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user),
              _buildMainTabs(),
              _buildBodyContent(user),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    final coverUrl = user.coverImage != null && user.coverImage!.isNotEmpty
        ? (ApiConfig.networkImageUrl(user.coverImage!) ?? user.coverImage)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover photo (full width)
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (!mounted) return;
            final auth = Provider.of<AuthProvider>(context, listen: false);
            await auth.loadUser();
          },
          child: Container(
            height: 160,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey[500]),
                    ),
                  )
                : Center(
                    child: Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[500]),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar overlapping cover (negative margin)
              Transform.translate(
                offset: const Offset(0, -44),
                child: Center(
                  child: GestureDetector(
                    onTap: _pickAvatarImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
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
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _localAvatarPreview != null
                                ? FileImage(_localAvatarPreview!)
                                : (user.avatar != null && user.avatar!.isNotEmpty
                                    ? NetworkImage(user.avatar!)
                                    : null) as ImageProvider?,
                            child: ((user.avatar == null || user.avatar!.isEmpty) &&
                                    _localAvatarPreview == null)
                                ? Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.add, color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Name
              Center(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Add location in Edit profile',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatButton(
                      count: _posts.length,
                      label: 'posts',
                      onTap: () => setState(() => _activeMainTab = 'post'),
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      count: user.followersCount,
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
                        ).then((_) {
                          if (mounted) _refreshUserCounts();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _StatButton(
                      count: user.followingCount,
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
                        ).then((_) {
                          if (mounted) _refreshUserCounts();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Edit | Share | Add
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                          if (!mounted) return;
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          await auth.loadUser();
                          await _loadUserPosts();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share profile')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Share profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.grey[800], size: 20),
                      onPressed: () => context.push('/explore'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileLabelTab(
              label: 'Post',
              icon: Icons.grid_on,
              isActive: _activeMainTab == 'post',
              onTap: () => setState(() => _activeMainTab = 'post'),
            ),
          ),
          Expanded(
            child: _ProfileLabelTab(
              label: 'Wellness',
              icon: Icons.favorite_border,
              isActive: _activeMainTab == 'wellness',
              onTap: () => setState(() => _activeMainTab = 'wellness'),
            ),
          ),
          Expanded(
            child: _ProfileLabelTab(
              label: 'Games',
              icon: Icons.sports_esports_outlined,
              isActive: _activeMainTab == 'games',
              onTap: () => setState(() => _activeMainTab = 'games'),
            ),
          ),
          Expanded(
            child: _ProfileLabelTab(
              label: 'Saved',
              icon: Icons.bookmark_border,
              isActive: _activeMainTab == 'saved',
              onTap: () {
                setState(() {
                  _activeMainTab = 'saved';
                  _savedLoading = true;
                });
                _loadSavedPosts();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(dynamic user) {
    if (_activeMainTab == 'post') {
      if (_isLoading) {
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator(color: Colors.black54)),
        );
      }
      return _buildPostsSection();
    }

    if (_activeMainTab == 'wellness') {
      return _buildWellnessTabContent();
    }

    if (_activeMainTab == 'games') {
      return _buildGamesTabContent();
    }

    if (_activeMainTab == 'saved') {
      return _buildSavedTabContent();
    }

    return const SizedBox.shrink();
  }

  Widget _buildWellnessTabContent() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/wellness'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Wellness',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _wellnessLoading
                  ? 'Loading…'
                  : 'Streak: $_wellnessStreak day${_wellnessStreak == 1 ? '' : 's'} • ${_wellnessHistory.length} activities',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to open Wellness',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesTabContent() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/games'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play wellness games',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to open Games',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSavedPosts() async {
    if (_savedLoading) return;
    setState(() => _savedLoading = true);
    try {
      final list = await PostService().getSavedPosts();
      if (mounted) setState(() {
        _savedPosts = list;
        _savedLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _savedPosts = [];
        _savedLoading = false;
      });
    }
  }

  Widget _buildSavedTabContent() {
    if (_savedLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.black54)),
      );
    }
    if (_savedPosts.isEmpty) {
      return _buildEmptySection(
        icon: Icons.bookmark_border,
        title: 'No saved posts',
        subtitle: 'Posts you save will appear here.',
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _savedPosts.length,
      itemBuilder: (context, i) {
        final post = _savedPosts[i];
        return PostCard(
          post: post,
          initialIsSaved: true,
          onSavedChanged: _loadSavedPosts,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    final list = _posts;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration placeholder (curtains / share vibe)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Create your first post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your point of view.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.push('/post/create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final post = list[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    posts: list,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
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
                  color: Colors.black.withValues(alpha: 0.55),
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
                  color: Colors.black.withValues(alpha: 0.55),
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
  final networkUrl = ApiConfig.networkImageUrl(path);
  if (networkUrl != null) {
    return Image.network(
      networkUrl,
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
                color: Colors.black,
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
