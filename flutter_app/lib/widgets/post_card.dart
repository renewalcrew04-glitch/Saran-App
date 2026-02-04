import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/time_formatter.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import '../screens/post/post_analytics_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/comments/comments_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  /// Called after this post is successfully deleted (e.g. to refresh list or pop screen).
  final VoidCallback? onPostDeleted;
  /// Initial saved state (e.g. true when showing in profile Saved tab).
  final bool? initialIsSaved;
  /// Called when user toggles save/unsave (e.g. to refresh saved list).
  final VoidCallback? onSavedChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onPostDeleted,
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
    final post = widget.post;
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
    final post = widget.post;
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
    final post = widget.post;
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
    final post = widget.post;
    try {
      await PostService().undoRepost(post.id);
      if (!mounted) return;
      setState(() {
        _repostsCount = (_repostsCount - 1).clamp(0, _repostsCount);
        _hasReposted = false;
      });
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

  Widget _buildPostMedia(String mediaUrl) {
    final url = ApiConfig.networkImageUrl(mediaUrl);
    if (url == null) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(post: post, onPostDeleted: widget.onPostDeleted),
                  if (post.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (post.media.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _buildPostMedia(post.media.first),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Actions(
                    post: post,
                    likeController: _likeController,
                    isLikedOverride: _isLiked,
                    likesCountOverride: _likesCount,
                    commentsCountOverride: _commentsCount,
                    repostsCountOverride: _repostsCount,
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
                ],
              ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Post post;
  final VoidCallback? onPostDeleted;
  const _Header({required this.post, this.onPostDeleted});

  Widget _buildAvatar(String? avatarUrl) {
    final url = avatarUrl != null && avatarUrl.isNotEmpty
        ? (ApiConfig.networkImageUrl(avatarUrl) ?? avatarUrl)
        : null;
    if (url == null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.black45),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Container(
          width: 40,
          height: 40,
          color: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.black45),
        ),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    final user = User(
      uid: post.uid,
      username: post.username,
      email: '',
      name: post.userName ?? post.username,
      avatar: post.userAvatar,
      profileCompleted: true,
      verified: post.userVerified ?? false,
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
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openUserProfile(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _buildAvatar(post.userAvatar),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (post.repostedByName != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      '${post.repostedByName} reposted',
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
              Row(
                children: [
                  Text(
                    post.userName ?? post.username,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${TimeFormatter.format(post.createdAt)}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '@${post.username}',
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _IconAction(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.hideLikeCount ? "" : _likesCount.toString(),
          color: _isLiked ? Colors.red : Colors.black54,
          onTap: onLikeTap ?? () => likeController.forward(from: 0.9),
          scale: likeController,
        ),
        _IconAction(
  icon: Icons.mode_comment_outlined,
  label: (commentsCountOverride ?? post.commentsCount).toString(),
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
  color: (hasRepostedOverride ?? post.repostedByUid != null) ? Colors.green : Colors.black54,
  onTap: () {
    RepostBottomSheet.show(
      context: context,
      alreadyReposted: hasRepostedOverride ?? post.repostedByUid != null,
      onRepost: onRepost ?? () async {},
      onUndo: onUndoRepost ?? () async {},
      onQuote: () {
        Navigator.pushNamed(
          context,
          '/post-create',
          arguments: post,
        );
      },
    );
  },
),
        _IconAction(
          icon: Icons.share_outlined,
          label: '',
        ),
        _IconAction(
          icon: (isSavedOverride ?? false) ? Icons.bookmark : Icons.bookmark_border,
          label: '',
          color: (isSavedOverride ?? false) ? Colors.black87 : Colors.black54,
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
                Navigator.pushNamed(
                  context,
                  '/post-edit',
                  arguments: post,
                );
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
    final iconWidget = Icon(icon, color: color ?? Colors.black87, size: 20);

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
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}
