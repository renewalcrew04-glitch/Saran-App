import 'package:flutter/material.dart';
import '../../../services/post_service.dart';

class MutedContentScreen extends StatefulWidget {
  const MutedContentScreen({super.key});

  @override
  State<MutedContentScreen> createState() => _MutedContentScreenState();
}

class _MutedContentScreenState extends State<MutedContentScreen> {
  final service = PostService();

  List<String> words = [];
  List<String> hashtags = [];

  final wordCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await service.getMutedContent();
    words = res['words']!;
    hashtags = res['hashtags']!;
    setState(() {});
  }

  Future<void> _save() async {
    await service.updateMutedContent(
      words: words,
      hashtags: hashtags,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Muted content updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Muted Content"),
        actions: [
          TextButton(onPressed: _save, child: const Text("Save"))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section("Muted Words", wordCtrl, words),
          const SizedBox(height: 20),
          _section("Muted Hashtags", tagCtrl, hashtags),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    TextEditingController controller,
    List<String> list,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Add and press enter",
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (v) {
            if (v.trim().isEmpty) return;
            setState(() {
              list.add(v.trim());
              controller.clear();
            });
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: list
              .map(
                (e) => Chip(
                  label: Text(e),
                  onDeleted: () => setState(() => list.remove(e)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
