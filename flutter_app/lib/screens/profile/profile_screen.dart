import 'dart:io';
import '../../utils/category_gradients.dart';
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

/// Creates rounded top corners and a curved cut-out at the bottom center for the profile image overlap.
class _BannerCurvedClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 16.0;
    const curveDepth = 24.0; // how far the center dips up
    final path = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(size.width * 0.5, size.height - curveDepth, 0, size.height)
      ..lineTo(0, radius)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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

class _PostSubTab extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PostSubTab({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProfileScreenState>()!;
    final bool isActive = state._activePostTab == value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 20, color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
    if (_activePostTab == 'all') return onlyOriginals;
    return onlyOriginals.where((p) {
      switch (_activePostTab) {
        case 'text':
          return p.type == 'text';
        case 'photo':
          return p.type == 'photo';
        case 'video':
          return p.type == 'video';
        default:
          return true;
      }
    }).toList();
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
  centerTitle: true,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _buildHeader(user),
              Transform.translate(
                offset: const Offset(0, -44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMainTabs(),
                    if (_activeMainTab == 'post') _buildPostSubTabs(),
                    _buildBodyContent(user),
                  ],
                ),
              ),
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

  Widget _buildHeader(dynamic user) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final coverUrl = user.coverImage != null && user.coverImage!.isNotEmpty
        ? (ApiConfig.networkImageUrl(user.coverImage!) ?? user.coverImage)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Banner with rounded top corners
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
          child: ClipPath(
            clipper: _BannerCurvedClip(),
            child: Container(
              height: 140,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              child: coverUrl != null
                  ? safeNetworkImage(
                      url: coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                      placeholderIcon: Icons.photo_camera_outlined,
                    )
                  : Center(
                      child: Icon(Icons.add_photo_alternate_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar overlapping banner – centered, blue border
              Transform.translate(
                offset: const Offset(0, -52),
                child: Center(
                  child: GestureDetector(
                    onTap: _pickAvatarImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _localAvatarPreview != null
                              ? CircleAvatar(
                                  radius: 48,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage: FileImage(_localAvatarPreview!),
                                )
                              : (user.avatar != null && user.avatar!.isNotEmpty)
                                  ? safeAvatarNetworkImage(
                                      url: ApiConfig.networkImageUrl(user.avatar!) ?? user.avatar!,
                                      size: 96,
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    )
                                  : CircleAvatar(
                                      radius: 48,
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.scrim,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(color: theme.colorScheme.onSurface, strokeWidth: 2),
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
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Icon(Icons.add, color: theme.colorScheme.onSurface, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name – centered
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Location / Joined – centered
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          (user.location != null && user.location!.isNotEmpty)
                              ? user.location!
                              : 'Add location',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Stats row – centered (Followers, Following, Posts)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatButton(
                          count: _posts.length,
                          label: 'Posts',
                          onTap: () => setState(() => _activeMainTab = 'post'),
                        ),
                        const SizedBox(width: 60),
                        _StatButton(
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
                        const SizedBox(width: 60),
                        _StatButton(
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Edit | Share – blue pill buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          child: FilledButton(
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
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 45),
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            onPressed: () => _showShareProfileSheet(context, user),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: const Text('Share profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ProfileLabelTab(
                label: 'Post',
                icon: Icons.grid_on,
                isActive: _activeMainTab == 'post',
                onTap: () => setState(() => _activeMainTab = 'post'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ProfileLabelTab(
                label: 'Wellness',
                icon: Icons.favorite_border,
                isActive: _activeMainTab == 'wellness',
                onTap: () => setState(() => _activeMainTab = 'wellness'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ProfileLabelTab(
                label: 'Games',
                icon: Icons.sports_esports_outlined,
                isActive: _activeMainTab == 'games',
                onTap: () => setState(() => _activeMainTab = 'games'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
  final theme = Theme.of(context);
  final posts = _filteredPosts;

  if (posts.isEmpty) {
    return const SizedBox(height: 200);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PostSubTab(icon: Icons.apps, value: 'all', onTap: () => setState(() => _activePostTab = 'all')),
          _PostSubTab(icon: Icons.text_fields, value: 'text', onTap: () => setState(() => _activePostTab = 'text')),
          _PostSubTab(icon: Icons.image_outlined, value: 'photo', onTap: () => setState(() => _activePostTab = 'photo')),
          _PostSubTab(icon: Icons.videocam_outlined, value: 'video', onTap: () => setState(() => _activePostTab = 'video')),
          _PostSubTab(icon: Icons.repeat, value: 'repost', onTap: () => setState(() => _activePostTab = 'repost')),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update avatar")),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}