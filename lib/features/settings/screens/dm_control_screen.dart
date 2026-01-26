import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class DMControlScreen extends StatefulWidget {
  const DMControlScreen({super.key});

  @override
  State<DMControlScreen> createState() => _DMControlScreenState();
}

class _DMControlScreenState extends State<DMControlScreen> {
  final api = SettingsApi();

  String dmValue = "everyone";
  bool saving = false;

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    setState(() => saving = true);

    try {
      // ✅ Only update DM (leave commentSettings unchanged by sending null)
      await api.updateMessagingSettings(
        dmSettings: dmValue,
        commentSettings: null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DM settings updated")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update DM settings")),
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
        title: const Text("DM Controls"),
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
            "Who can message you?",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: dmValue,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: "everyone", child: Text("Everyone")),
              DropdownMenuItem(value: "followers", child: Text("Followers only")),
              DropdownMenuItem(value: "no_one", child: Text("No one")),
            ],
            onChanged: (v) => setState(() => dmValue = v ?? "everyone"),
          ),
        ],
      ),
    );
  }
}
