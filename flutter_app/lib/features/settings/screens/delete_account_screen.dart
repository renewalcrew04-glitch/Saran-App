import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/settings_api.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final api = SettingsApi();
  bool loading = false;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete account?"),
        content: const Text(
          "This will permanently delete your account and all your data. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    api.setToken(auth.token!);

    setState(() => loading = true);

    try {
      await api.deleteAccount();
      await auth.logout();

      if (!mounted) return;
      context.go('/login');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      final data = e.response?.data;
      final message = data is Map ? (data['message'] ?? data['error'])?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? "Failed to delete account"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Delete Account"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "This will permanently delete your account.",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : _delete,
                child: Text(loading ? "Deleting..." : "Delete My Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
