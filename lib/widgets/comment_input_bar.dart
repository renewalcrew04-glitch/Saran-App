import 'package:flutter/material.dart';

class CommentInputBar extends StatefulWidget {
  final Function(String) onSend;
  const CommentInputBar({super.key, required this.onSend});

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              widget.onSend(ctrl.text.trim());
              ctrl.clear();
            },
          ),
        ],
      ),
    );
  }
}
