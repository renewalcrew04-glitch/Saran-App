import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/time_formatter.dart';
import '../utils/media_utils.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import '../screens/post/post_analytics_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/comments/comments_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../widgets/quote_post_embed.dart';

List<TextSpan> _buildTextSpansWithHashtags(String text) {
  if (text.isEmpty) return [];
  final regex = RegExp(r'(#\w+)');
  final spans = <TextSpan>[];
  int lastEnd = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
      ));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w600),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
    ));
  }
  return spans;
}

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  /// Called after this post is successfully deleted (e.g. to refresh list or pop screen).
  final VoidCallback? onPostDeleted;
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

  static const double _mediaHeight = 320.0;
  static const double _mediaSectionHeight = 348.0; // _mediaHeight + 8 gap + ~20 dots

  /// Same size for all photos. Full image visible with letterboxing (white space) as needed.
  Widget _buildPostMedia(String mediaUrl) {
    final url = ApiConfig.networkImageUrl(mediaUrl);
    if (url == null) {
      return Container(
        width: double.infinity,
        height: _mediaHeight,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    }
    return Container(
      width: double.infinity,
      height: _mediaHeight,
      color: Colors.grey.shade100,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade100,
            child: const Center(child: Icon(Icons.image_outlined, color: Colors.black45)),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade100,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
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
      itemHeight: _mediaHeight,
    );
  }

  Widget _buildMediaSection(Post post) {
    final media = post.media;
    if (media.isEmpty) return const SizedBox.shrink();
    final sectionHeight =
        media.length == 1 ? _mediaHeight : _mediaSectionHeight;
    return _buildFullBleedMedia(
      _buildPostMediaCarousel(media),
      height: sectionHeight,
    );
  }

  Widget _buildFullBleedMedia(Widget child, {double? height}) {
    final sectionHeight = height ?? _mediaSectionHeight;
    return SizedBox(
      height: sectionHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final extendAmount = (screenWidth - constraints.maxWidth) / 2;
          if (extendAmount <= 0) {
            return child;
          }
          return OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: screenWidth,
            maxHeight: sectionHeight,
            child: Transform.translate(
              offset: Offset(-extendAmount, 0),
              child: SizedBox(
                width: screenWidth,
                height: sectionHeight,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Post post = widget.post;
    final Post? embeddedOriginal = post.quotedPost ?? post.originalPost;
    final bool isRepost = post.type == 'repost' && embeddedOriginal != null;
    final bool isOwnRepost = isRepost &&
        (context.read<AuthProvider>().user?.uid == post.repostedByUid);

    const horizontalPadding = 14.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    post: post,
                    onPostDeleted: widget.onPostDeleted,
                    displayPost: isRepost ? embeddedOriginal : null,
                    isOwnRepost: isRepost ? isOwnRepost : null,
                  ),
                  if (isRepost) ...[
                    if (embeddedOriginal.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          children: _buildTextSpansWithHashtags(embeddedOriginal.text),
                        ),
                      ),
                    ],
                  ] else ...[
                    if (post.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          children: _buildTextSpansWithHashtags(post.text),
                        ),
                      ),
                    ],
                    if (post.isQuote && embeddedOriginal != null) ...[
                      const SizedBox(height: 12),
                      QuotePostEmbed(
                        originalPost: embeddedOriginal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: embeddedOriginal),
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
              const SizedBox(height: 12),
              _buildMediaSection(embeddedOriginal),
            ],
            if (!isRepost && post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaSection(post),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 14),
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
  /// When set (e.g. for reposts), show this post's author/avatar/time instead of [post].
  final Post? displayPost;
  /// When true, show "You reposted" instead of "X reposted".
  final bool? isOwnRepost;
  const _Header({
    required this.post,
    this.onPostDeleted,
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
                              Icon(Icons.repeat_rounded, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                repostLabel,
                                style: TextStyle(
                                  color: Colors.grey[700],
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
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${TimeFormatter.format(author.createdAt)}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${author.username}',
                        style: const TextStyle(
                          color: Colors.black54,
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
  const Padding(
    padding: EdgeInsets.only(left: 6),
    child: Text(
      "Edited",
      style: TextStyle(
        color: Colors.black45,
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
  icon: const Icon(Icons.more_horiz, color: Colors.black87),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostOptions(post: post, onDeleted: onPostDeleted),
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
    if (myUid != null && post.type == 'repost' && post.uid == myUid) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isRepostedByMe = _isRepostedByMe(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _IconAction(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.hideLikeCount ? "" : _likesCount.toString(),
          color: _isLiked ? Colors.red : Colors.black87,
          onTap: onLikeTap ?? () => likeController.forward(from: 0.9),
          scale: likeController,
        ),
        _IconAction(
          icon: Icons.mode_comment_outlined,
          label: (commentsCountOverride ?? post.commentsCount).toString(),
          color: Colors.black87,
          onTap: onCommentsTap ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentsScreen(postId: post.id),
              ),
            );
          },
        ),
        _IconAction(
          icon: Icons.repeat,
          label: (repostsCountOverride ?? post.repostsCount).toString(),
          color: isRepostedByMe ? Colors.green : Colors.black87,
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
        _IconAction(
          icon: Icons.share_outlined,
          label: '',
          color: Colors.black87,
        ),
        _IconAction(
          icon: (isSavedOverride ?? false) ? Icons.bookmark : Icons.bookmark_border,
          label: '',
          color: Colors.black87,
          onTap: onSaveTap ?? () {},
        ),
      ],
    );
  }
}

class _PostOptions extends StatelessWidget {
  final Post post;
  final VoidCallback? onDeleted;

  const _PostOptions({required this.post, this.onDeleted});

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
              onTap: () {
                Navigator.pop(context);
                // report flow
              },
            ),
          ],
        ],
      ),
    );
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
  final double itemHeight;

  const _PostMediaCarousel({
    required this.mediaUrls,
    required this.buildItem,
    this.itemHeight = 500,
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
        SizedBox(
          height: widget.itemHeight,
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

  const _IconAction({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Colors.black87;
    final iconWidget = Icon(icon, color: iconColor, size: 20);
    final labelColor = color ?? Colors.black54;

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
