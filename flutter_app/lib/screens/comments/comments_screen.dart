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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, comments.length),
        ),
        title: const Text("Comments"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
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
            // Show new comment immediately (optimistic update)
            if (newComment != null) {
              setState(() {
                comments = [newComment, ...comments];
              });
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
}
