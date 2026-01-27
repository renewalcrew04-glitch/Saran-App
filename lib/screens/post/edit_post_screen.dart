import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final service = PostService();
  final controller = TextEditingController();
  bool saving = false;
  late Post post;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    post = ModalRoute.of(context)!.settings.arguments as Post;
    controller.text = post.text;
  }

  Future<void> _save() async {
    if (controller.text.trim().isEmpty) return;

    setState(() => saving = true);

    try {
      await service.editPost(
        postId: post.id,
        text: controller.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Edit failed")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Edit Post"),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: const Text("Save"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Edit your post...",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
