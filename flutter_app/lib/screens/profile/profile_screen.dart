import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/features/menu/menu_sheet.dart';
import 'package:saran_app/services/wellness_streak_service.dart';

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/feed_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_update_service.dart';
import '../../services/upload_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/post_card.dart';
import '../messages/chat_screen.dart';
import '../../providers/chat_provider.dart';
import '../../providers/dm_provider.dart';
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

  // Tabs: Post, Reposted, Wellness, Games, Saved
  String _activeMainTab = 'post';

  // Post sub tabs
  String _activePostTab = 'all'; // all, text, photo, video, repost

  List<Post> _savedPosts = [];
  bool _savedLoading = false;

  static bool _isRepostOrQuote(Post p) =>
      p.type == 'repost' || p.type == 'quote' || p.isQuote;

  /// Posts shown in the Post tab only (reposts and quotes are in the Reposted tab).
  List<Post> get _filteredPosts {
    final onlyOriginals = _posts.where((p) => !_isRepostOrQuote(p)).toList();
    if (_activePostTab == 'all') return onlyOriginals;
    return onlyOriginals.where((p) {
      switch (_activePostTab) {
        case 'text':
          return p.type == 'text';
        case 'photo':
          return p.type == 'photo';
        case 'video':
          return p.type == 'video';
        case 'repost':
          return false; // reposts and quotes only in Reposted tab
        default:
          return true;
      }
    }).toList();
  }

  /// Reposts and quote posts together in the Reposted tab.
  List<Post> get _repostedPosts =>
      _posts.where((p) => _isRepostOrQuote(p)).toList();

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

  void _showShareProfileSheet(BuildContext context, User user) {
    final profileLink = 'https://saran.app/u/${user.username}';
    final shareText = 'Check out @${user.username} on Saran\n$profileLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: ProfileService().getFollowers(user.uid),
          builder: (context, snapshot) {
            final followers = snapshot.hasData && snapshot.data!['restricted'] != true
                ? List<Map<String, dynamic>>.from(snapshot.data!['followers'] ?? [])
                : <Map<String, dynamic>>[];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Share profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.95)),
                    ),
                    const SizedBox(height: 16),
                    // Copy link
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.link, color: Colors.white.withValues(alpha: 0.9), size: 22),
                      ),
                      title: Text('Copy link', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                      subtitle: Text('Copy profile link to share', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      },
                    ),
                    if (followers.isNotEmpty) ...[
                      const Divider(height: 24, color: Colors.white12),
                      Text(
                        'Share with',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: followers.length > 4 ? 220 : (followers.length * 56.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: followers.length,
                          itemBuilder: (context, i) {
                            final f = followers[i];
                            final uid = (f['_id'] ?? f['uid'])?.toString() ?? '';
                            final name = (f['name'] ?? f['username'] ?? '')?.toString() ?? '';
                            final username = (f['username'] ?? '')?.toString() ?? '';
                            final avatar = f['avatar']?.toString();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white12,
                                backgroundImage: avatar != null && avatar.isNotEmpty
                                    ? NetworkImage(ApiConfig.networkImageUrl(avatar) ?? avatar)
                                    : null,
                                child: avatar == null || avatar.isEmpty
                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)))
                                    : null,
                              ),
                              title: Text(name.isNotEmpty ? name : '@$username', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                              subtitle: Text('@$username', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                              trailing: Icon(Icons.send_outlined, size: 18, color: Colors.white.withValues(alpha: 0.5)),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final token = context.read<AuthProvider>().token;
                                if (token == null || token.isEmpty) return;
                                final convoId = await context.read<DmProvider>().openDm(token: token, otherUid: uid);
                                if (!context.mounted) return;
                                if (convoId != null && convoId.isNotEmpty) {
                                  bool shared = false;
                                  try {
                                    await context.read<ChatProvider>().sendProfile(
                                      token: token,
                                      conversationId: convoId,
                                      receiverUid: uid,
                                      uid: user.uid,
                                      username: user.username,
                                      name: user.name,
                                      avatar: user.avatar,
                                    );
                                    shared = true;
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to share profile: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}'),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  }
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: convoId,
                                        otherUserId: uid,
                                        otherName: name,
                                        otherAvatar: avatar,
                                      ),
                                    ),
                                  );
                                  if (shared && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profile shared')),
                                    );
                                  }
                                } else {
                                  Clipboard.setData(ClipboardData(text: shareText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copied to clipboard')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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
  scrolledUnderElevation: 0,
  centerTitle: true,
  title: Text(
    '@${user.username}',
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
  ),
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
              if (_activeMainTab == 'post') _buildPostSubTabs(),
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
            await _loadUserPosts();
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
  offset: const Offset(16, -48), // 25% overlap
  child: Align(
    alignment: Alignment.centerLeft,
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
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
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
              if (user.bio != null && user.bio!.isNotEmpty) ...[
  const SizedBox(height: 12),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      user.bio!,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[800],
        height: 1.4,
      ),
    ),
  ),
],
              Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    children: [
      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          (user.location != null && user.location!.isNotEmpty)
              ? user.location!
              : 'Add location in Edit profile',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
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
                        onPressed: () => _showShareProfileSheet(context, user),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Share profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
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
              label: 'Reposted',
              icon: Icons.repeat,
              isActive: _activeMainTab == 'reposted',
              onTap: () => setState(() => _activeMainTab = 'reposted'),
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
                setState(() => _activeMainTab = 'saved');
                _loadSavedPosts();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSubTabs() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PostSubTab(icon: Icons.apps, label: 'All', value: 'all'),
          _PostSubTab(icon: Icons.text_fields, label: 'Texts', value: 'text'),
          _PostSubTab(icon: Icons.image_outlined, label: 'Photos', value: 'photo'),
          _PostSubTab(icon: Icons.videocam_outlined, label: 'Videos', value: 'video'),
          _PostSubTab(icon: Icons.repeat, label: 'Reposts', value: 'repost'),
        ],
      ),
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

    if (_activeMainTab == 'reposted') {
      if (_isLoading) {
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator(color: Colors.black54)),
        );
      }
      return _buildRepostedTabContent();
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

  Widget _buildRepostedTabContent() {
    final list = _repostedPosts;
    void onRepostUndone() {
      if (mounted) _loadUserPosts();
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.repeat, size: 44, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              const Text(
                'No reposts or quotes yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'When you repost or quote something, it will show here.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // Grid same as Post tab (3 columns)
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    posts: list,
                    initialIndex: index,
                    onRepostUndone: onRepostUndone,
                  ),
                ),
              );
              if (mounted) _loadUserPosts();
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

  Widget _buildWellnessTabContent() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/wellness'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildGamesTabContent() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/games'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                textAlign: TextAlign.center,
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
      ),
    );
  }

  Future<void> _loadSavedPosts() async {
    List<Post> list = [];
    try {
      list = await PostService().getSavedPosts().timeout(
        const Duration(seconds: 6),
        onTimeout: () => <Post>[],
      );
    } catch (_) {
      list = [];
    }
    if (mounted) {
      setState(() {
        _savedPosts = list;
        _savedLoading = false;
      });
    }
  }

  Widget _buildSavedTabContent() {
    if (_savedPosts.isEmpty) {
      return _buildSavedEmptyWithRetry();
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post),
              ),
            );
            if (mounted) _loadSavedPosts();
          },
        );
      },
    );
  }

  Widget _buildSavedEmptyWithRetry() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No saved posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you save will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _savedLoading ? null : _loadSavedPosts,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    final list = _filteredPosts;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Share your point of view.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await context.push<bool>('/post-create');
                    if (result == true && mounted) _loadUserPosts();
                  },
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    posts: list,
                    initialIndex: index,
                    onRepostUndone: _loadUserPosts,
                  ),
                ),
              );
              if (mounted) _loadUserPosts();
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
          if (post.type == 'repost' || post.type == 'quote' || post.isQuote)
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

class _PostSubTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PostSubTab({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProfileScreenState>()!;
    final bool isActive = state._activePostTab == value;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => state.setState(() => state._activePostTab = value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}