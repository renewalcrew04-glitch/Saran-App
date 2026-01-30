import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/post_model.dart';
import '../utils/time_formatter.dart';
import '../services/post_service.dart';
import 'repost_bottom_sheet.dart';
import 'save_bottom_sheet.dart';
import '../screens/comments/comments_screen.dart';
import '../screens/post/post_analytics_screen.dart';
import 'quote_post_embed.dart'; 

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() async {
    _likeController.forward().then((_) => _likeController.reverse());
    if (widget.post.isLiked) {
      await PostService().unlikePost(widget.post.id);
    } else {
      await PostService().likePost(widget.post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost Context
            if (post.repostedByName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.retweet, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${post.repostedByName} reposted',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: post.userAvatar == null
                      ? Icon(Icons.person, color: Colors.grey.shade400)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.userName ?? post.username,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (post.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Colors.blue),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            TimeFormatter.format(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${post.username}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showOptions(context, post),
                  child: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                ),
              ],
            ),

            // Content
            if (post.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  post.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

            // Media
            if (post.media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // ✅ FIXED: Moved constraints to Container wrapper
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: CachedNetworkImage(
                      imageUrl: post.media.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image, 
                        color: Colors.grey
                      ),
                    ),
                  ),
                ),
              ),

            // Quote Post
            if (post.quotedPost != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuotePostEmbed(post: post.quotedPost!),
              ),

            // Actions
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionButton(
                  icon: FontAwesomeIcons.comment,
                  count: post.commentsCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: post.id),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: FontAwesomeIcons.retweet,
                  count: post.repostsCount,
                  activeColor: Colors.green,
                  isActive: post.repostedByUid != null,
                  onTap: () {
                    RepostBottomSheet.show(
                      context: context,
                      alreadyReposted: post.repostedByUid != null,
                      onRepost: () async => await PostService().repost(post.id),
                      onUndo: () {},
                      onQuote: () {
                        Navigator.pushNamed(context, '/post-create', arguments: post);
                      },
                    );
                  },
                ),
                _ActionButton(
                  icon: post.isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                  count: post.likesCount,
                  activeColor: Colors.red,
                  isActive: post.isLiked,
                  onTap: _handleLike,
                  controller: _likeController,
                ),
                _ActionButton(
                  icon: FontAwesomeIcons.bookmark,
                  count: null, // Usually simplified
                  onTap: () => SaveBottomSheet.show(context, post.id),
                ),
                _ActionButton(
                  icon: FontAwesomeIcons.share,
                  count: null,
                  onTap: () {}, // Implement system share
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text("View Analytics"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PostAnalyticsScreen(post: post)));
              },
            ),
            // Add more options here
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final VoidCallback onTap;
  final Color? activeColor;
  final bool isActive;
  final AnimationController? controller;

  const _ActionButton({
    required this.icon,
    this.count,
    required this.onTap,
    this.activeColor,
    this.isActive = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? Colors.black) : Colors.grey.shade500;
    
    Widget iconWidget = Icon(icon, size: 18, color: color);
    
    if (controller != null && isActive) {
      iconWidget = ScaleTransition(scale: controller!, child: iconWidget);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            iconWidget,
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}