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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    comments = await service.getComments(widget.postId);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Comments"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: comments.length,
              itemBuilder: (_, i) => CommentTile(
                comment: comments[i],
                onReply: _load,
              ),
            ),
      bottomSheet: CommentInputBar(
        onSend: (text) async {
          await service.addComment(widget.postId, text);
          _load();
        },
      ),
    );
  }
}
