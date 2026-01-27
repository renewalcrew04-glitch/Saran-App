import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../utils/time_formatter.dart';
import '../utils/category_gradients.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import '../screens/post/post_analytics_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.9,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: CategoryGradients.forCategories(post.hashtags),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(1.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: post.media.first,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _Actions(
                    post: post,
                    likeController: _likeController,
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

class _Header extends StatelessWidget {
  final Post post;
  const _Header(this.post);

  @override
  Widget build(BuildContext context) {
    return Row(
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

  const _Actions({required this.post, required this.likeController});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _IconAction(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: post.hideLikeCount ? "" : post.likesCount.toString(),
          color: post.isLiked ? Colors.redAccent : Colors.white,
          onTap: () {
            likeController.forward(from: 0.9);
          },
          scale: likeController,
        ),
        _IconAction(
  icon: Icons.mode_comment_outlined,
  label: post.commentsCount.toString(),
  onTap: () {
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
  label: post.repostsCount.toString(),
  onTap: () {
    RepostBottomSheet.show(
      context: context,
      alreadyReposted: post.repostedByUid != null,
      onRepost: () async {
        await PostService().repost(post.id);
      },
      onUndo: () {
        // undo repost (later phase)
      },
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
        color: Colors.black.withOpacity(0.9),
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
