import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import '../../utils/category_gradients.dart';
import '../../widgets/glass_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:saran_app/features/menu/menu_sheet.dart';
import 'package:saran_app/services/wellness_streak_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../config/api_config.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/feed_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../services/profile_update_service.dart';
import '../../services/upload_service.dart';
import '../../utils/media_utils.dart';
import '../../widgets/post_card.dart';
import '../messages/chat_screen.dart';
import '../post/post_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';

/// When this notifier's value equals [kProfileTabIndex], profile will refresh posts.
const int kProfileTabIndex = 4;

Widget buildSafeImage(String path) {
  final networkUrl = ApiConfig.networkImageUrl(path);
  if (networkUrl != null) {
    return safeNetworkImage(url: networkUrl, fit: BoxFit.cover);
  }

  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image)),
  );
}


class ProfileScreen extends StatefulWidget {
  /// When the main nav switches to Profile tab, this is set to [kProfileTabIndex].
  /// Profile screen refreshes posts when that happens so new posts appear.
  final ValueNotifier<int>? tabIndexNotifier;

  const ProfileScreen({super.key, this.tabIndexNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _PostGridTile extends StatelessWidget {
  final Post post;

  const _PostGridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    // For reposts/quotes, use embedded post's media; otherwise use post's media
    final embedded = post.quotedPost ?? post.originalPost;
    final mediaUrls = post.media.isNotEmpty ? post.media : (embedded?.media ?? []);

    if (mediaUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          buildSafeImage(mediaUrls.first),
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
  decoration: BoxDecoration(
    gradient: CategoryGradients.forCategory(post.category ?? ""),
  ),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.15),
    ),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(12),
    child: Text(
      post.text.isNotEmpty ? post.text : 'Text',
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      ),
    ),
  ),
);
  }
}

/// Individual icon chip inside the post filter pill bar.
class _PostSubTab extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String tooltip;

  const _PostSubTab({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProfileScreenState>()!;
    final bool isActive = state._activePostTab == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 36,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFFF9D5C), Color(0xFFFF6A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    const BoxShadow(
                      color: Color(0x55FF7A20),
                      blurRadius: 10,
                      spreadRadius: -1,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Colors.white
                : (isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : const Color(0xFF48485A).withValues(alpha: 0.70)),
          ),
        ),
      ),
    );
  }
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

  File? _localAvatarPreview;

  bool _uploadingAvatar = false;

  /// Posts shown in the Post tab (originals only, except when Reposts sub-tab is selected).
  List<Post> get _filteredPosts {
  if (_activePostTab == 'repost') return _repostedPosts;

  final onlyOriginals = _posts.where((p) => !_isRepostOrQuote(p)).toList();

  switch (_activePostTab) {
    case 'all':
      return onlyOriginals.where((p) => p.type != 'text').toList(); // hide text
    case 'text':
      return onlyOriginals.where((p) => p.type == 'text').toList();
    case 'photo':
      return onlyOriginals.where((p) => p.type == 'photo').toList();
    case 'video':
      return onlyOriginals.where((p) => p.type == 'video').toList();
    default:
      return onlyOriginals;
  }
  }

  /// Reposts and quote posts together in the Reposted tab.
  List<Post> get _repostedPosts =>
      _posts.where((p) => _isRepostOrQuote(p)).toList();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
  backgroundColor: theme.colorScheme.surface,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  title: Text(
    '@${user.username}',
    style: TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
  ),
  actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface, size: 24),
            onPressed: () => context.push('/settings'),
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _buildHeader(user),
              _buildMainTabs(),
              if (_activeMainTab == 'post') _buildPostSubTabs(),
              _buildBodyContent(user),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
            ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.tabIndexNotifier?.removeListener(_onTabIndexChanged);
    super.dispose();
  }

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

  Widget _buildBodyContent(dynamic user) {
    if (_activeMainTab == 'post') {
      if (_isLoading) {
        return SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
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

  Widget _buildGamesTabContent() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/games'),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.sports_esports, color: scheme.onPrimaryContainer, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Games',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Play wellness games',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Open Games',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // Interest chip accent palette — vivid, used as glass tint + text colour
  static const _chipColors = [
    Color(0xFFFF6B35), // orange
    Color(0xFF22C55E), // green
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF3B82F6), // blue
    Color(0xFFA855F7), // purple
  ];

  Widget _buildHeader(User user) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final coverUrl = user.coverImage != null && user.coverImage!.isNotEmpty
        ? (ApiConfig.networkImageUrl(user.coverImage!) ?? user.coverImage)
        : null;

    // Avatar widget (left-aligned, with gradient border)
    Widget avatarWidget = GestureDetector(
      onTap: _pickAvatarImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD060), Color(0xFFFF8A3A), Color(0xFFE8501A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: ClipOval(
                child: _localAvatarPreview != null
                    ? Image.file(_localAvatarPreview!, fit: BoxFit.cover)
                    : (user.avatar != null && user.avatar!.isNotEmpty)
                        ? safeAvatarNetworkImage(
                            url: ApiConfig.networkImageUrl(user.avatar!) ?? user.avatar!,
                            size: 82,
                            backgroundColor: scheme.surfaceContainerHighest,
                          )
                        : Container(
                            color: scheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 30,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
              ),
            ),
          ),
          if (_uploadingAvatar)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0x88000000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner + overlapping avatar ──────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image / default gradient banner
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
                height: 175,
                width: double.infinity,
                decoration: coverUrl == null
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2D8B), Color(0xFFB83280), Color(0xFFE8501A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      )
                    : null,
                child: coverUrl != null
                    ? safeNetworkImage(
                        url: coverUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 175,
                        placeholderIcon: Icons.photo_camera_outlined,
                      )
                    : null,
              ),
            ),
            // Avatar overlapping banner – left-aligned
            Positioned(
              left: 16,
              bottom: -36,
              child: avatarWidget,
            ),
          ],
        ),

        // ── Row: spacer (avatar width) + Edit/Share buttons ─────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const SizedBox(width: 96), // reserve space for avatar
              const Spacer(),
              _ProfileActionButton(
                label: 'Edit Profile',
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
              ),
              const SizedBox(width: 10),
              _ProfileActionButton(
                label: 'Share',
                filled: true,
                onTap: () => _showShareProfileSheet(context, user),
              ),
            ],
          ),
        ),

        // ── Name, location, bio, website, interests ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              // Location
              if (user.location != null && user.location!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        user.location!,
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              // Bio
              if (user.bio != null && user.bio!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    user.bio!,
                    style: TextStyle(fontSize: 13, color: scheme.onSurface, height: 1.4),
                  ),
                ),
              // Website
              if (user.website != null && user.website!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        user.website!,
                        style: TextStyle(fontSize: 13, color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              // Interest chips — Liquid Glass with color identity
              if (user.interests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: user.interests.asMap().entries.map((e) {
                    final color = _chipColors[e.key % _chipColors.length];
                    return LiquidGlassChip(
                      label: e.value,
                      isActive: false,
                      fixedColor: color,
                      textColor: color, // vivid accent text, works on both themes
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        // ── Stats card ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatButton(
                    count: user.postsCount,
                    label: 'Posts',
                    onTap: () => setState(() => _activeMainTab = 'post'),
                  ),
                ),
                Container(width: 0.8, height: 40, color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
                      ).then((_) {
                        if (mounted) _refreshUserCounts();
                      });
                    },
                  ),
                ),
                Container(width: 0.8, height: 40, color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
                      ).then((_) {
                        if (mounted) _refreshUserCounts();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tab(String label, String value, VoidCallback onTap) {
      final isActive = _activeMainTab == value;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? scheme.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? scheme.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : scheme.onSurfaceVariant),
                letterSpacing: isActive ? 0.1 : 0,
              ),
              child: Text(label),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          tab('Posts', 'post', () => setState(() => _activeMainTab = 'post')),
          tab('Wellness', 'wellness', () => context.push('/wellness')),
          tab('Games', 'games', () => context.push('/games')),
          tab('Saved', 'saved', () {
            setState(() => _activeMainTab = 'saved');
            _loadSavedPosts();
          }),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    final theme = Theme.of(context); // Add this line right here
    final posts = _filteredPosts;

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_off_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your posts will appear here.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // TEXT TAB → show full PostCard like Explore
    if (_activePostTab == 'text') {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return PostCard(
            post: post,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: post),
                ),
              );
              if (mounted) _loadUserPosts();
            },
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          double height;

          if (post.type == 'text') {
            height = 180;
          } else if (post.type == 'photo') {
            height = index.isEven ? 200 : 240;
          } else if (post.type == 'video') {
            if (index % 3 == 0) {
              height = 320;
            } else {
              height = 220;
            }
          } else {
            height = 200;
          }

          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    posts: posts,
                    initialIndex: index,
                    onRepostUndone: _loadUserPosts,
                  ),
                ),
              );
              if (mounted) _loadUserPosts();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: height,
                child: Container(
                  // Now 'theme' is defined and this line will work perfectly!
                  color: theme.colorScheme.surfaceContainerHighest, 
                  child: _PostGridTile(post: post),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostSubTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light: wrap in a gradient-border shell (white top → gray bottom),
    // then blur+cool-tinted fill = real glass gloss.
    // Dark: plain blur container as before.
    Widget pill = ClipRRect(
      borderRadius: BorderRadius.circular(isDark ? 18 : 17),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.white.withValues(alpha: 1.0),
                      const Color(0xFFF0F0FC).withValues(alpha: 0.92),
                      const Color(0xFFE4E4F4).withValues(alpha: 0.96),
                    ],
              stops: isDark ? null : const [0.0, 0.22, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(isDark ? 18 : 17),
            border: isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 0.8,
                  )
                : null,
          ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PostSubTab(icon: Icons.grid_view_rounded,           value: 'all',    tooltip: 'All',     onTap: () => setState(() => _activePostTab = 'all')),
                _PostSubTab(icon: Icons.article_outlined,            value: 'text',   tooltip: 'Text',    onTap: () => setState(() => _activePostTab = 'text')),
                _PostSubTab(icon: Icons.photo_outlined,              value: 'photo',  tooltip: 'Photos',  onTap: () => setState(() => _activePostTab = 'photo')),
                _PostSubTab(icon: Icons.play_circle_outline_rounded, value: 'video',  tooltip: 'Videos',  onTap: () => setState(() => _activePostTab = 'video')),
                _PostSubTab(icon: Icons.repeat_rounded,              value: 'repost', tooltip: 'Reposts', onTap: () => setState(() => _activePostTab = 'repost')),
              ],
            ),
          ),
        ),
      );

    // Light: wrap the pill in a gradient-border shell (bright white → gray)
    // to create the two-tone gloss edge.
    if (!isDark) {
      pill = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFAAAEC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7070A0).withValues(alpha: 0.13),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1),
        child: pill,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: pill,
    );
  }

  Widget _buildSavedEmptyState() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No saved posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Posts you save will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedTabContent() {
    if (_savedPosts.isEmpty) {
      return _buildSavedEmptyState();
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

  Widget _buildWellnessTabContent() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/wellness'),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.favorite, color: theme.colorScheme.onPrimary, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wellness',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _wellnessLoading
                      ? 'Loading…'
                      : 'Streak: $_wellnessStreak day${_wellnessStreak == 1 ? '' : 's'} • ${_wellnessHistory.length} activities',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Open Wellness',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      setState(() => _savedPosts = list);
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

  void _onTabIndexChanged() {
    if (widget.tabIndexNotifier?.value == kProfileTabIndex && mounted) {
      _refreshProfile();
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
      String msg = 'Failed to update avatar.';
      if (e is DioException) {
        final data = e.response?.data;
        final serverMsg = data is Map && data['message'] is String ? (data['message'] as String).trim() : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          msg = serverMsg;
        } else {
          final code = e.response?.statusCode;
          if (code == 500) msg = 'Server error. Try again later.';
          else if (code == 400) msg = 'Invalid request. Try a different photo.';
          else if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            msg = 'No connection. Check network and try again.';
          }
        }
      } else {
        final s = e.toString().replaceFirst('Exception: ', '');
        if (s.isNotEmpty) msg = s;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _refreshProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser();
    if (mounted) _loadUserPosts();
  }

  Future<void> _refreshUserCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUser();
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
                              leading: avatar != null && avatar.isNotEmpty
                                  ? safeAvatarNetworkImage(
                                      url: ApiConfig.networkImageUrl(avatar) ?? avatar,
                                      size: 40,
                                      backgroundColor: Colors.white12,
                                    )
                                  : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white12,
                                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
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

  static bool _isRepostOrQuote(Post p) =>
      p.type == 'repost' || p.type == 'quote' || p.isQuote;
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile action button — Share: solid orange gradient, Edit Profile: liquid glass.
class _ProfileActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ProfileActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE8813A);
    const orangeLight = Color(0xFFFF9D5C);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (filled) {
      // Share button — solid orange gradient
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [orangeLight, orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: orange.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'Share',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    // Edit Profile — liquid glass
    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.95);
    final borderBot = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFCCCCDD).withValues(alpha: 0.90);
    final highlightTop = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.88);
    final baseTint = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF0F0F8).withValues(alpha: 0.82);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [borderTop, borderBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF8888AA).withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: -1,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [highlightTop, baseTint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -7,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 1.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: isDark ? 0.45 : 0.90),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}