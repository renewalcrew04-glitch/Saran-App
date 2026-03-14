import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../utils/time_formatter.dart';
import '../utils/media_utils.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import '../screens/post/post_analytics_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/comments/comments_screen.dart';
import '../features/settings/services/settings_api.dart';
import '../screens/post/post_detail_screen.dart';
import '../utils/hashtag_utils.dart';
import '../widgets/quote_post_embed.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  /// Called after this post is successfully deleted (e.g. to refresh list or pop screen).
  final VoidCallback? onPostDeleted;
  /// Called after user blocks the post author (removes post from feed).
  final VoidCallback? onBlockedUser;
  /// Called after user successfully undoes a repost (e.g. remove from profile Reposted tab).
  final VoidCallback? onUndoRepostSuccess;
  /// Initial saved state (e.g. true when showing in profile Saved tab).
  final bool? initialIsSaved;
  /// Called when user toggles save/unsave (e.g. to refresh saved list).
  final VoidCallback? onSavedChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onPostDeleted,
    this.onBlockedUser,
    this.onUndoRepostSuccess,
    this.initialIsSaved,
    this.onSavedChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _repostsCount = 0;
  bool _hasReposted = false;
  late bool _isSaved;

  bool _expanded = false;

Widget _buildExpandableText(String text) {
  const limit = 152;

  final shouldTrim = text.length > limit;
  final displayText =
      !_expanded && shouldTrim ? "${text.substring(0, limit).trim()}..." : text;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          children: buildTextSpansWithHashtags(
            displayText,
            textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
            hashtagColor: Colors.blue,
          ),
        ),
      ),
      if (shouldTrim)
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _expanded ? "Show less" : "See more",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        )
    ],
  );
}

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.9,
      upperBound: 1.2,
    );
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _repostsCount = widget.post.repostsCount;
    _isSaved = widget.initialIsSaved ?? false;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _isLiked = widget.post.isLiked;
      _likesCount = widget.post.likesCount;
      _commentsCount = widget.post.commentsCount;
      _repostsCount = widget.post.repostsCount;
      _hasReposted = false;
      _isSaved = widget.initialIsSaved ?? false;
    }
  }

  Future<void> _handleSaveToggle() async {
    final post = widget.post.originalPost ?? widget.post;
    try {
      final nowSaved = await PostService().toggleSave(post.id);
      if (!mounted) return;
      setState(() => _isSaved = nowSaved);
      widget.onSavedChanged?.call();
    } catch (_) {
      // Toggle failed; state unchanged
    }
  }

  Future<void> _handleLike() async {
    _likeController.forward(from: 0.9);
    final post = widget.post.originalPost ?? widget.post;
    try {
      final success = _isLiked
          ? await PostService().unlikePost(post.id)
          : await PostService().likePost(post.id);
      if (!mounted || !success) return;
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    } catch (_) {
      // Like failed; UI state unchanged
    }
  }

  Future<void> _handleRepost() async {
    final post = widget.post.originalPost ?? widget.post;
    try {
      await PostService().repost(post.id);
      if (!mounted) return;
      setState(() {
        _repostsCount = _repostsCount + 1;
        _hasReposted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reposted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  Future<void> _handleUndoRepost() async {
    final post = widget.post.originalPost ?? widget.post;
    try {
      await PostService().undoRepost(post.id);
      if (!mounted) return;
      setState(() {
        _repostsCount = (_repostsCount - 1).clamp(0, _repostsCount);
        _hasReposted = false;
      });
      widget.onUndoRepostSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repost removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

Widget _buildFullWidthMedia(Post post) {
  final media = post.media;
  if (media.isEmpty) return const SizedBox.shrink();

  final screenWidth = MediaQuery.of(context).size.width;

  return SizedBox(
    width: screenWidth,
    child: _buildPostMediaCarousel(media),
  );
}
  /// Same size for all photos. Full image visible with letterboxing (white space) as needed.
  Widget _buildPostMedia(String mediaUrl) {
  final url = ApiConfig.networkImageUrl(mediaUrl);
  if (url == null) return const SizedBox.shrink();

  final screenWidth = MediaQuery.of(context).size.width;

  return ClipRRect(
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    ),
    child: Image.network(
    url,
    width: screenWidth,
    fit: BoxFit.contain,
    loadingBuilder: (_, child, progress) {
      if (progress == null) return child;
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    },
    errorBuilder: (_, __, ___) {
      return const SizedBox(
        height: 250,
        child: Center(child: Icon(Icons.broken_image)),
      );
    },
  ),
  );
}

Widget _buildPostMediaCarousel(List<String> mediaUrls) {
  if (mediaUrls.isEmpty) return const SizedBox.shrink();

  if (mediaUrls.length == 1) {
    return _buildPostMedia(mediaUrls.first);
  }

  return _PostMediaCarousel(
  mediaUrls: mediaUrls,
  buildItem: _buildPostMedia,
);
}

  Widget _buildMediaSection(Post post) {
  final media = post.media;
  if (media.isEmpty) return const SizedBox.shrink();

  return _buildPostMediaCarousel(media);
}

  @override
  Widget build(BuildContext context) {
    final Post post = widget.post;
    final Post? embeddedOriginal = post.quotedPost ?? post.originalPost;
    final bool isRepost = post.type == 'repost' && embeddedOriginal != null;
    final bool isOwnRepost = isRepost &&
        (context.read<AuthProvider>().user?.uid == post.repostedByUid);

    const horizontalPadding = 12.0;

   const cardRadius = 16.0;

   return GestureDetector(
  onTap: widget.onTap,
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                post: post,
                onPostDeleted: widget.onPostDeleted,
                onBlockedUser: widget.onBlockedUser,
                displayPost: isRepost ? embeddedOriginal : null,
                isOwnRepost: isRepost ? isOwnRepost : null,
              ),

              /// REPOST TEXT
              if (isRepost) ...[
                if (embeddedOriginal.text.isNotEmpty ||
                    embeddedOriginal.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildExpandableText(
                    combinedPostText(
  text: embeddedOriginal.text,
  hashtags: embeddedOriginal.hashtags
      .where((h) => h != embeddedOriginal.category)
      .toList(),
),
                  ),
                ],
              ] else ...[

                /// NORMAL POST TEXT
                if (post.text.isNotEmpty || post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: post.media.isEmpty
                        ? const EdgeInsets.only(left: 30)
                        : EdgeInsets.zero,
                    child: _buildExpandableText(
                      combinedPostText(
  text: post.text,
  hashtags: post.hashtags.where((h) => h != post.category).toList(),
),
                    ),
                  ),
                ],

                /// QUOTE POST
                if (post.isQuote && embeddedOriginal != null) ...[
                  const SizedBox(height: 8),
                  QuotePostEmbed(
                    originalPost: embeddedOriginal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(post: embeddedOriginal),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
            if (isRepost && embeddedOriginal.media.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMediaSection(embeddedOriginal),
            ],
           if (!isRepost && post.media.isNotEmpty) ...[
  const SizedBox(height: 8),
  SizedBox(
    width: MediaQuery.of(context).size.width,
    child: _buildPostMediaCarousel(post.media),
  ),
],
            Padding(
  padding: const EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 10),
  child: _Actions(
    post: post,
    likeController: _likeController,
    isLikedOverride: _isLiked,
    likesCountOverride: _likesCount,
    commentsCountOverride: _commentsCount,
    repostsCountOverride: isRepost ? embeddedOriginal.repostsCount : _repostsCount,
    hasRepostedOverride: _hasReposted,
    isSavedOverride: _isSaved,
    onSaveTap: _handleSaveToggle,
    onRepost: _handleRepost,
    onUndoRepost: _handleUndoRepost,
    onLikeTap: _handleLike,
    onCommentsTap: () async {
      final newCount = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (_) => CommentsScreen(postId: post.id),
        ),
      );

      if (newCount != null && mounted) {
        setState(() => _commentsCount = newCount);
      }
    },
  ),
),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Post post;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onBlockedUser;
  /// When set (e.g. for reposts), show this post's author/avatar/time instead of [post].
  final Post? displayPost;
  /// When true, show "You reposted" instead of "X reposted".
  final bool? isOwnRepost;
  const _Header({
    required this.post,
    this.onPostDeleted,
    this.onBlockedUser,
    this.displayPost,
    this.isOwnRepost,
  });

  Widget _buildAvatar(String? avatarUrl) {
    final url = avatarUrl != null && avatarUrl.isNotEmpty
        ? (ApiConfig.networkImageUrl(avatarUrl) ?? avatarUrl)
        : null;
    return safeAvatarNetworkImage(url: url, size: 40);
  }

  void _openUserProfile(BuildContext context, Post targetPost) {
    final user = User(
      uid: targetPost.uid,
      username: targetPost.username,
      email: '',
      name: targetPost.userName ?? targetPost.username,
      avatar: targetPost.userAvatar,
      profileCompleted: true,
      verified: targetPost.userVerified ?? false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Reposter name: explicit repostedByName, or post's author (uid) when this is a repost
    final reposterName = post.repostedByName ?? (displayPost != null ? post.userName ?? post.username : null);
    final showRepostLabel = reposterName != null || isOwnRepost == true;
    final repostLabel = isOwnRepost == true
        ? 'You reposted'
        : (reposterName != null ? '$reposterName reposted' : null);
    final author = displayPost ?? post;

    // For reposts, show reposter's avatar; for own repost use current user's avatar
    String? avatarToShow = author.userAvatar;
    if (displayPost != null && showRepostLabel) {
      if (isOwnRepost == true) {
        final currentUser = context.read<AuthProvider>().user;
        avatarToShow = currentUser?.avatar;
      } else {
        avatarToShow = post.repostedByAvatar ?? author.userAvatar;
      }
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openUserProfile(context, author),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _buildAvatar(avatarToShow),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showRepostLabel && repostLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.repeat_rounded, size: 14, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                repostLabel,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            author.userName ?? author.username,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${TimeFormatter.format(author.createdAt)}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${author.username}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (post.edited)
  Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(
      "Edited",
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 11,
      ),
    ),
  ),

        if (post.isPinned)
  const Padding(
    padding: EdgeInsets.only(right: 6),
    child: Icon(Icons.push_pin, color: Colors.amber, size: 18),
  ),

IconButton(
  icon: Icon(Icons.more_horiz, color: scheme.onSurface),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostOptions(
        post: post,
        displayPost: displayPost,
        onDeleted: onPostDeleted,
        onBlockedUser: onBlockedUser,
      ),
    );
  },
),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final Post post;
  final AnimationController likeController;
  final bool? isLikedOverride;
  final int? likesCountOverride;
  final int? commentsCountOverride;
  final int? repostsCountOverride;
  final bool? hasRepostedOverride;
  final bool? isSavedOverride;
  final VoidCallback? onSaveTap;
  final Future<void> Function()? onRepost;
  final Future<void> Function()? onUndoRepost;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentsTap;

  const _Actions({
    required this.post,
    required this.likeController,
    this.isLikedOverride,
    this.likesCountOverride,
    this.commentsCountOverride,
    this.repostsCountOverride,
    this.hasRepostedOverride,
    this.isSavedOverride,
    this.onSaveTap,
    this.onRepost,
    this.onUndoRepost,
    this.onLikeTap,
    this.onCommentsTap,
  });

  bool get _isLiked => isLikedOverride ?? post.isLiked;
  int get _likesCount => likesCountOverride ?? post.likesCount;

  bool _isRepostedByMe(BuildContext context) {
    if (hasRepostedOverride == true) return true;
    if (post.repostedByUid != null && post.repostedByUid!.isNotEmpty) return true;

    final myUid = context.read<AuthProvider>().user?.uid;
    if (myUid != null && post.type == 'repost' && post.uid == myUid) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isRepostedByMe = _isRepostedByMe(context);

    return Row(
      children: [
        Row(
          children: [
            _IconAction(
              icon: _isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
                  iconSize: 22,
              label: post.hideLikeCount ? "" : _likesCount.toString(),
              color: _isLiked
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface,
              onTap: onLikeTap ?? () => likeController.forward(from: 0.9),
              scale: likeController,
            ),

            const SizedBox(width: 18),

            _IconAction(
  icon: FontAwesomeIcons.comment,
  iconSize: 16,
  label: (commentsCountOverride ?? post.commentsCount).toString(),
  color: Theme.of(context).colorScheme.onSurface,
  onTap: onCommentsTap ?? () {},
),

            const SizedBox(width: 18),

            _IconAction(
              icon: FontAwesomeIcons.retweet,
              iconSize: 15,
              label: (repostsCountOverride ?? post.repostsCount).toString(),
              color: isRepostedByMe
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface,
              onTap: () {
                RepostBottomSheet.show(
                  context: context,
                  alreadyReposted: isRepostedByMe,
                  onRepost: onRepost ?? () async {},
                  onUndo: onUndoRepost ?? () async {},
                  onQuote: () {
                    context.push('/post-create', extra: post);
                  },
                );
              },
            ),

            const SizedBox(width: 18),

            _IconAction(
              icon: FontAwesomeIcons.arrowUpFromBracket,
              iconSize: 15,
              label: '',
              color: Theme.of(context).colorScheme.onSurface,
              onTap: () {
                Share.share('https://saran.app/post/${post.id}');
              },
            ),
          ],
        ),

        const Spacer(),
        
        _IconAction(
  icon: (isSavedOverride ?? false)
      ? FontAwesomeIcons.solidBookmark
      : FontAwesomeIcons.bookmark,
  iconSize: 15,
  label: '',
  color: (isSavedOverride ?? false)
      ? Colors.black87
      : Theme.of(context).colorScheme.onSurface,
  onTap: onSaveTap ?? () {},
),
      ],
    );
  }
}

class _PostOptions extends StatelessWidget {
  final Post post;
  final Post? displayPost;
  final VoidCallback? onDeleted;
  final VoidCallback? onBlockedUser;

  const _PostOptions({
    required this.post,
    this.displayPost,
    this.onDeleted,
    this.onBlockedUser,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().user?.uid ?? '';
    final isOwnPost = currentUid.isNotEmpty && post.uid == currentUid;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnPost) ...[
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.white),
              title: const Text(
                "View analytics",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostAnalyticsScreen(post: post),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.white),
              title: Text(
                post.hideLikeCount ? "Show like count" : "Hide like count",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await PostService().toggleHideLikeCount(post.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                "Edit post",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/post-edit', extra: post);
              },
            ),
            ListTile(
              leading: Icon(
                post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: Colors.white,
              ),
              title: Text(
                post.isPinned ? "Unpin post" : "Pin post",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // backend hook later
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                "Delete post",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () => _confirmAndDeletePost(context),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text(
                "Report",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _showReportPostDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text(
                "Block user",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _blockAuthorAndDismiss(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showReportPostDialog(BuildContext context) async {
    Navigator.pop(context);
    final reasonCtrl = TextEditingController();
    String? selectedReason;
    const quickReasons = [
      'Spam',
      'Harassment or bullying',
      'Hate speech or symbols',
      'Violence or dangerous content',
      'Nudity or sexual content',
      'Self-harm or suicide',
      'Scam or fraud',
      'Other',
    ];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Report post"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Help us understand the problem. Reports are reviewed within 24 hours.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...quickReasons.map((r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) => setDialogState(() => selectedReason = v),
                  )),
                  const SizedBox(height: 4),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Additional details (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if ((selectedReason ?? '').trim().isNotEmpty) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final extra = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    final reason = (selectedReason ?? 'Other').trim();
    if (reason.isEmpty) return;
    final fullReason = extra.isNotEmpty ? '$reason: $extra' : reason;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    final api = SettingsApi();
    api.setToken(auth.token!);
    try {
      await api.reportPost(postId: post.id, reason: fullReason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted. We'll review within 24 hours.")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _blockAuthorAndDismiss(BuildContext context) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Block user?"),
        content: const Text(
          "Their content will be removed from your feed. They won't be able to see your profile or contact you.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Block"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    final api = SettingsApi();
    api.setToken(auth.token!);
    final targetUid = (displayPost ?? post).uid;
    try {
      await api.blockUser(targetUid);
      if (!context.mounted) return;
      onBlockedUser?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User blocked. Their content has been removed from your feed.")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _confirmAndDeletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete post?"),
        content: const Text(
          "This post will be permanently deleted. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await PostService().deletePost(post.id);
      if (!context.mounted) return;
      Navigator.pop(context); // close options sheet
      onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}

class _PostMediaCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final Widget Function(String url) buildItem;

  const _PostMediaCarousel({
  required this.mediaUrls,
  required this.buildItem,
});

  @override
  State<_PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<_PostMediaCarousel> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
  AspectRatio(
  aspectRatio: 1,
  child: PageView.builder(
    controller: _pageController,
    itemCount: widget.mediaUrls.length,
    onPageChanged: (i) => _currentPage.value = i,
    itemBuilder: (_, index) => widget.buildItem(widget.mediaUrls[index]),
  ),
),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (_, page, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.mediaUrls.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == page ? Colors.black54 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final Animation<double>? scale;
  final double iconSize;

  const _IconAction({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.scale,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
    color ?? Theme.of(context).colorScheme.onSurface;
final iconWidget = FaIcon(icon, color: iconColor, size: iconSize);

final labelColor =
    color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          scale != null
              ? ScaleTransition(scale: scale!, child: iconWidget)
              : iconWidget,
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}
