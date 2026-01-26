import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  final api = SettingsApi();

  bool privateAccount = false;
  bool hideFromExplore = false;
  bool loading = false;

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null || auth.token == null) return;

    api.setToken(auth.token!);

    setState(() => loading = true);

    try {
      await api.updateUserProfile(
        uid: auth.user!.uid,
        body: {
          "privacy": {
            "privateAccount": privateAccount,
            "hideFromExplore": hideFromExplore,
          }
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Privacy updated")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update privacy")),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Account Privacy"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: loading ? null : _save,
            child: Text(
              loading ? "Saving..." : "Save",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: privateAccount,
            onChanged: (v) => setState(() => privateAccount = v),
            title: const Text("Private Account"),
            subtitle: const Text("Only approved users can follow you"),
          ),
          SwitchListTile(
            value: hideFromExplore,
            onChanged: (v) => setState(() => hideFromExplore = v),
            title: const Text("Hide from Explore"),
            subtitle: const Text("Your profile will not appear in explore suggestions"),
          ),
        ],
      ),
    );
  }
}
