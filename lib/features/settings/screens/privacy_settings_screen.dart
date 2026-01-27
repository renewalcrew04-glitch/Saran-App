import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final api = SettingsApi();

  bool isPrivate = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    // load current value from AuthProvider user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        setState(() {
          isPrivate = auth.user!.isPrivate ?? false; // if your model has it
        });
      }
    });
  }

  Future<void> _save(bool value) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null || auth.token == null) return;

    api.setToken(auth.token!);

    setState(() {
      isPrivate = value;
      saving = true;
    });

    try {
      await api.updatePrivacy(uid: auth.user!.uid, isPrivate: value);

      // refresh user from backend
      await auth.loadUser();

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
    setState(() => saving = false);
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
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: isPrivate,
            onChanged: saving ? null : _save,
            title: const Text("Private Account"),
            subtitle: const Text("Only approved users can follow you"),
          ),
          if (saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
