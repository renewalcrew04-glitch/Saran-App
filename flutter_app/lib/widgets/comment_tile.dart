import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../utils/media_utils.dart';
import '../models/user_model.dart';
import '../screens/profile/user_profile_screen.dart';
import '../services/comment_service.dart';

class CommentTile extends StatelessWidget {
  final String postId;
  final Map comment;
  final VoidCallback onReply;

  const CommentTile({
    super.key,
    required this.postId,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replies = comment['replies'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bubble(
            comment: comment,
            postId: postId,
            onReply: onReply,
            theme: theme,
          ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Column(
                children: replies.map<Widget>((r) => _Bubble(
                  comment: r,
                  postId: postId,
                  onReply: onReply,
                  theme: theme,
                  isReply: true,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Map comment;
  final String postId;
  final VoidCallback onReply;
  final ThemeData theme;
  final bool isReply;

  const _Bubble({
    required this.comment,
    required this.postId,
    required this.onReply,
    required this.theme,
    this.isReply = false,
  });

  void _openUserProfile(BuildContext context, Map c) {
    final userMap = c['user'] ?? c;
    if (userMap is! Map<String, dynamic>) return;
    try {
      final user = User.fromJson(Map<String, dynamic>.from(userMap));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final username = (comment['user'] ?? comment['uid'])?['username'] ?? 'unknown';
    final text = comment['text']?.toString() ?? '';
    final avatar = (comment['user'] ?? comment['uid']) is Map
        ? ((comment['user'] ?? comment['uid']) as Map)['avatar']?.toString()
        : null;
    final avatarUrl = avatar != null && avatar.isNotEmpty ? ApiConfig.networkImageUrl(avatar) : null;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openUserProfile(context, comment),
            child: avatarUrl != null
                ? safeAvatarNetworkImage(
                    url: avatarUrl,
                    size: 36,
                    backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(context, comment),
                  child: Text(
                    username,
                    style: TextStyle(
                      color: theme.textTheme.titleSmall?.color ?? (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionChip(
                      label: 'Like',
                      icon: Icons.favorite_border,
                      theme: theme,
                      onTap: () async {
                        await CommentService().likeComment(comment['_id']);
                        onReply();
                      },
                    ),
                    const SizedBox(width: 16),
                    _ActionChip(
                      label: 'Reply',
                      icon: Icons.reply_rounded,
                      theme: theme,
                      onTap: () => _replyDialog(context, postId, _commentIdString(comment)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract a string ID from comment map (handles _id as string or {$oid: "..."}).
  String _commentIdString(Map comment) {
    final id = comment['_id'];
    if (id == null) return '';
    if (id is String) return id;
    if (id is Map && id['\$oid'] != null) return id['\$oid'].toString();
    return id.toString();
  }

  void _replyDialog(BuildContext context, String postId, String commentId) {
    if (commentId.isEmpty) return;
    final ctrl = TextEditingController();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reply', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                _ReplySendButton(
                  postId: postId,
                  commentId: commentId,
                  ctrl: ctrl,
                  onSuccess: () {
                    if (ctx.mounted) Navigator.pop(ctx);
                    onReply();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplySendButton extends StatefulWidget {
  final String postId;
  final String commentId;
  final TextEditingController ctrl;
  final VoidCallback onSuccess;

  const _ReplySendButton({
    required this.postId,
    required this.commentId,
    required this.ctrl,
    required this.onSuccess,
  });

  @override
  State<_ReplySendButton> createState() => _ReplySendButtonState();
}

class _ReplySendButtonState extends State<_ReplySendButton> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _sending ? null : () async {
        final text = widget.ctrl.text.trim();
        if (text.isEmpty) return;
        setState(() => _sending = true);
        try {
          await CommentService().replyToComment(widget.postId, widget.commentId, text);
          if (!mounted) return;
          widget.onSuccess();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        } finally {
          if (mounted) setState(() => _sending = false);
        }
      },
      child: _sending ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
