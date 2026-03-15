import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/profile_update_service.dart';
import '../../../utils/media_utils.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final ProfileUpdateService _profileUpdateService = ProfileUpdateService();

  late TextEditingController _nameController;
  String? _selectedGender;
  DateTime? _dob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedGender = user?.gender;
    _dob = user?.dob;
    // One-off fix: if account has no gender, set to female so save works (for testing)
    if (user != null && (user.gender == null || user.gender!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fixGenderOnce());
    }
  }

  Future<void> _fixGenderOnce() async {
    final auth = context.read<AuthProvider>();
    try {
      await _profileUpdateService.setMeGender('female');
      await auth.loadUser();
      if (mounted) setState(() => _selectedGender = 'female');
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _genderLabel(String? value) {
    if (value == null || value.isEmpty) return 'Not set';
    switch (value) {
      case 'female':
        return 'Female';
      case 'trans_woman':
        return 'Trans woman';
      case 'male':
        return 'Male';
      default:
        return value;
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: _dob ?? DateTime(2000),
    );
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _save() async {
    if (_saving) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _profileUpdateService.updateUserInfo(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        gender: _selectedGender,
        dob: _dob,
        currentUserUid: null, // use PUT /api/users/me
      );
      await auth.loadUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information updated')),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to update. Try again.';
      if (e is DioException) {
        final code = e.response?.statusCode;
        final serverMsg = e.response?.data is Map && (e.response!.data as Map)['message'] is String
            ? (e.response!.data as Map)['message'] as String
            : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          msg = serverMsg;
        } else if (code == 500) {
          msg = 'Server error. Try again later.';
        } else if (code == 400) {
          msg = 'Invalid request. Check your details.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User information'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _SectionHeader(title: 'Account details'),
              const SizedBox(height: 8),
              _ReadOnlyRow(label: 'Username', value: '@${user.username}'),
              _ReadOnlyRow(label: 'Email', value: user.email),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Editable information'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                  hintText: 'Your display name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Gender'),
                subtitle: Text(_genderLabel(_selectedGender)),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  final choice = await showModalBottomSheet<String>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(title: const Text('Female'), onTap: () => Navigator.pop(ctx, 'female')),
                          ListTile(title: const Text('Trans woman'), onTap: () => Navigator.pop(ctx, 'trans_woman')),
                          ListTile(title: const Text('Male'), onTap: () => Navigator.pop(ctx, 'male')),
                          ListTile(title: const Text('Clear'), onTap: () => Navigator.pop(ctx, '')),
                        ],
                      ),
                    ),
                  );
                  if (choice != null) setState(() => _selectedGender = choice.isEmpty ? null : choice);
                },
              ),
              if (_genderLabel(_selectedGender) == 'Not set')
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: TextButton(
                    onPressed: _saving ? null : () async {
                      setState(() => _saving = true);
                      try {
                        await _profileUpdateService.setMeGender('female');
                        await context.read<AuthProvider>().loadUser();
                        if (mounted) setState(() => _selectedGender = 'female');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gender set to Female')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not set gender: ${e.toString().replaceFirst('Exception: ', '')}')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    child: const Text('Set to Female (testing)'),
                  ),
                ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Date of birth'),
                subtitle: Text(_dob == null ? 'Not set' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: _pickDate,
              ),
              if (user.selfieImage != null && user.selfieImage!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(title: 'Verification selfie'),
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSelfieImage(user.selfieImage!),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelfieImage(String url) {
    final networkUrl = ApiConfig.networkImageUrl(url);
    if (networkUrl != null) {
      return SizedBox(
        width: 120,
        height: 120,
        child: safeNetworkImage(url: networkUrl, fit: BoxFit.cover),
      );
    }
    return const SizedBox(width: 120, height: 120, child: Icon(Icons.person, size: 48));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
