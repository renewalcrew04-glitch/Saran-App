import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class CommentsControlScreen extends StatefulWidget {
  const CommentsControlScreen({super.key});

  @override
  State<CommentsControlScreen> createState() => _CommentsControlScreenState();
}

class _CommentsControlScreenState extends State<CommentsControlScreen> {
  final api = SettingsApi();

  String commentValue = "everyone";
  bool saving = false;

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    setState(() => saving = true);

    try {
      // ✅ Only update Comments (leave dmSettings unchanged by sending null)
      await api.updateMessagingSettings(
        dmSettings: null,
        commentSettings: commentValue,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment settings updated")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update comment settings")),
      );
    }

    if (!mounted) return;
    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Comments Controls"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? "Saving..." : "Save"),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Who can comment on your posts?",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: commentValue,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "everyone", child: Text("Everyone")),
              DropdownMenuItem(value: "followers", child: Text("Followers only")),
              DropdownMenuItem(value: "no_one", child: Text("No one")),
            ],
            onChanged: (v) => setState(() => commentValue = v ?? "everyone"),
          ),
        ],
      ),
    );
  }
}
