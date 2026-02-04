import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../utils/time_formatter.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import '../screens/post/post_analytics_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import 'save_bottom_sheet.dart';
import '../screens/comments/comments_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

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
        color: Colors.grey[800],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(post),
                  if (post.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.text,
                      style: const TextStyle(
                        color: Colors.white,
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
  const _Header(this.post);

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
                CircleAvatar(
                radius: 20,
                backgroundImage:
                    post.userAvatar != null ? NetworkImage(post.userAvatar!) : null,
                backgroundColor: Colors.grey[800],
              ),
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
        color: Colors.white54,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${TimeFormatter.format(post.createdAt)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '@${post.username}',
                style: const TextStyle(
                  color: Colors.white38,
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
        color: Colors.white38,
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
  icon: const Icon(Icons.more_horiz, color: Colors.white70),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostOptions(post: post),
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
          color: _isLiked ? Colors.white : Colors.white70,
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
  color: (hasRepostedOverride ?? post.repostedByUid != null) ? Colors.green : Colors.white,
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
          icon: Icons.bookmark_border,
          label: '',
          onTap: () {
            SaveBottomSheet.show(context, post.id);
          },
        ),
      ],
    );
  }
}

class _PostOptions extends StatelessWidget {
  final Post post;
  const _PostOptions({required this.post});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
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
    final iconWidget = Icon(icon, color: color ?? Colors.white, size: 20);

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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}
