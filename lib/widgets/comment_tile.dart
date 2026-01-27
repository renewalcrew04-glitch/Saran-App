import 'package:flutter/material.dart';
import '../services/comment_service.dart';

class CommentTile extends StatelessWidget {
  final Map comment;
  final VoidCallback onReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final replies = comment['replies'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bubble(comment, context),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children:
                    replies.map<Widget>((r) => _bubble(r, context)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bubble(Map c, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c['user']['username'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c['text'],
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await CommentService().likeComment(c['_id']);
                  onReply();
                },
                child: const Text(
                  "Like",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  _replyDialog(context, c['_id']);
                },
                child: const Text(
                  "Reply",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _replyDialog(BuildContext context, String commentId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Reply", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Write a reply...",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await CommentService().replyToComment(commentId, ctrl.text);
              Navigator.pop(context);
              onReply();
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}
