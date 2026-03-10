import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final api = SettingsApi();
  final TextEditingController reasonController = TextEditingController();

  bool loading = false;

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || auth.token == null) return;

    final reason = reasonController.text.trim();
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid reason")),
      );
      return;
    }

    api.setToken(auth.token!);

    setState(() => loading = true);

    try {
      // report yourself as "app problem" (temporary)
      await api.reportUser(uid: auth.user!.uid, reason: reason);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted")),
      );

      reasonController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit report")),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Report a problem"),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Describe the issue...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: loading ? null : _submit,
                child: Text(loading ? "Submitting..." : "Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
