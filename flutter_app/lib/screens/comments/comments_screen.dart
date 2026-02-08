import 'package:flutter/material.dart';
import '../../services/comment_service.dart';
import '../../widgets/comment_tile.dart';
import '../../widgets/comment_input_bar.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final service = CommentService();
  List comments = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await service.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        comments = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '').trim();
        loading = false;
        comments = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context, comments.length),
        ),
        title: Text(
          'Comments',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color ?? Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildError(theme)
              : comments.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: comments.length,
                      itemBuilder: (_, i) => CommentTile(
                        postId: widget.postId,
                        comment: comments[i],
                        onReply: _load,
                      ),
                    ),
      bottomSheet: CommentInputBar(
        onSend: (text) async {
          try {
            final newComment = await service.addComment(widget.postId, text);
            if (!mounted) return;
            if (newComment != null) {
              setState(() => comments = [newComment, ...comments]);
            } else {
              await _load();
            }
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
          }
        },
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8), fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: theme.iconTheme.color?.withValues(alpha: 0.4) ?? Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
