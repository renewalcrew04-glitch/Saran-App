import 'package:flutter/material.dart';
import '../services/post_service.dart';

class SaveBottomSheet {
  static void show(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(postId: postId),
    );
  }
}

class _Sheet extends StatefulWidget {
  final String postId;
  const _Sheet({required this.postId});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final service = PostService();
  List collections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    collections = await service.getSaveCollections();
    setState(() {});
  }

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
          const Text(
            "Save to collection",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...collections.map(
            (c) => ListTile(
              title: Text(
                c['name'],
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                await service.toggleSave(widget.postId);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
