import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_update_service.dart';
import '../../services/upload_service.dart';

// ── Brand tokens (theme-invariant) ────────────────────────────────────────────
const _kPrimary   = Color(0xFFFF8132);
const _kPrimaryLt = Color(0xFFFF9D5C);

const _kInterests = [
  'Wellness', 'Fitness', 'Career', 'Travel', 'Books',
  'Music',   'Art',     'Food',   'Tech',   'Fashion',
  'Mental Health', 'Yoga',
];

class CreateProfileScreen extends StatefulWidget {
  /// Pre-filled from signup – display name and username
  final String initialName;
  final String initialUsername;

  const CreateProfileScreen({
    super.key,
    required this.initialName,
    required this.initialUsername,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  final TextEditingController _bioCtrl = TextEditingController();

  File? _avatar;
  final Set<String> _selected = {};
  bool _saving = false;

  // ── Theme-aware color getters ──────────────────────────────────────────────
  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg     => _cs.surface;
  Color get _cardBg => _isDark ? const Color(0xFF111827) : _cs.surfaceContainerHighest;
  Color get _border => _cs.outline;
  Color get _text   => _cs.onSurface;
  Color get _muted  => _cs.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.initialName);
    _usernameCtrl = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Pick avatar from camera / gallery ─────────────────────────────────────
  Future<void> _pickAvatar() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kPrimary),
              title: Text('Camera', style: TextStyle(color: _text)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _kPrimary),
              title: Text('Gallery', style: TextStyle(color: _text)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _avatar = File(picked.path));
    }
  }

  // ── Create My Profile handler ─────────────────────────────────────────────
  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();

    try {
      // 1. Upload avatar if chosen
      if (_avatar != null) {
        final url = await UploadService().uploadFile(_avatar!);
        await ProfileUpdateService().updateAvatar(
          url,
          currentUserUid: auth.user?.uid,
        );
      }

      // 2. Save display name + bio
      final bio = _bioCtrl.text.trim();
      final name = _nameCtrl.text.trim();

      await ProfileUpdateService().updateProfile(
        name: name.isNotEmpty ? name : (auth.user?.name ?? ''),
        bio: bio,
        location: auth.user?.location ?? '',
        currentUserUid: auth.user?.uid,
      );

      // 3. Refresh user in provider
      await auth.loadUser();

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _cs.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarPicker(),
                    const SizedBox(height: 28),
                    _buildField(
                      label: 'BIO',
                      child: _bioField(),
                    ),
                    const SizedBox(height: 24),
                    _buildInterestsSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar: title + step indicator ───────────────────────────────────────
  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Create Profile',
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Step 3 of 3',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Orange progress bar (full = step 3/3)
        Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: 1.0,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimaryLt, _kPrimary],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Avatar picker ──────────────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main circle
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _avatar == null
                    ? const LinearGradient(
                        colors: [_kPrimaryLt, _kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: _avatar != null
                    ? DecorationImage(
                        image: FileImage(_avatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40FF8132),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: _avatar == null
                  ? const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 34,
                    )
                  : null,
            ),
            // "+" badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2.5),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Labelled field wrapper ─────────────────────────────────────────────────
  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  // ── Bio multi-line field ──────────────────────────────────────────────────
  Widget _bioField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _bioCtrl,
        maxLines: 3,
        style: TextStyle(color: _text, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Dreamer. Creator. Wellness enthusiast 🌿',
          hintStyle: TextStyle(color: _muted, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Interests section ─────────────────────────────────────────────────────
  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR INTERESTS (PICK ANY)',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kInterests.map(_buildChip).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    final isActive = _selected.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (isActive) {
          _selected.remove(label);
        } else {
          _selected.add(label);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_kPrimaryLt, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : _border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _saving ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimaryLt, _kPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40FF8132),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Create My Profile  ✦',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
