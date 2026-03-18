import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../services/profile_update_service.dart';
import '../../utils/media_utils.dart';

// Brand orange (used for primary actions and accents)
const _kOrange = Color(0xFFFF6B35);
const _kPurple = Color(0xFF7B2D8B);

const _kInterests = [
  'Wellness', 'Fitness', 'Career', 'Travel', 'Books',
  'Music',    'Art',     'Food',   'Tech',   'Fashion',
  'Mental Health', 'Yoga',
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _picker          = ImagePicker();
  final _uploadService   = UploadService();
  final _profileService  = ProfileUpdateService();

  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl  = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  File? _localAvatar;
  File? _localCover;

  bool _uploadingAvatar = false;
  bool _uploadingCover  = false;
  bool _saving          = false;
  bool _isPrivate       = false;

  final Set<String> _selectedInterests = {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text     = user?.name ?? '';
    _usernameCtrl.text = user?.username ?? '';
    _bioCtrl.text      = user?.bio ?? '';
    _locationCtrl.text = user?.location ?? '';
    _websiteCtrl.text  = user?.website ?? '';
    _phoneCtrl.text    = user?.phone ?? '';
    _isPrivate         = user?.isPrivate ?? false;
    _selectedInterests.addAll(user?.interests ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Image pickers ─────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _localAvatar     = File(picked.path);
      _uploadingAvatar = true;
    });
    try {
      final auth = context.read<AuthProvider>();
      final url  = await _uploadService.uploadMedia(picked.path);
      if (!mounted) return;
      await _profileService.updateAvatar(url, currentUserUid: auth.user?.uid);
      if (!mounted) return;
      await auth.loadUser();
    } catch (e) {
      if (mounted) _showErr(e);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _localCover     = File(picked.path);
      _uploadingCover = true;
    });
    try {
      final auth = context.read<AuthProvider>();
      final url  = await _uploadService.uploadMedia(picked.path);
      if (!mounted) return;
      final res     = await _profileService.updateCover(url, currentUserUid: auth.user?.uid);
      if (!mounted) return;
      final userMap = res?['user'];
      if (userMap is Map<String, dynamic>) {
        auth.updateUserFromMap(userMap);
      } else {
        await auth.loadUser();
      }
    } catch (e) {
      if (mounted) _showErr(e);
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final res  = await _profileService.updateProfile(
        name:      _nameCtrl.text.trim(),
        bio:       _bioCtrl.text.trim(),
        location:  _locationCtrl.text.trim(),
        isPrivate: _isPrivate,
        website:   _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        interests: _selectedInterests.toList(),
        currentUserUid: auth.user?.uid,
      );
      if (!mounted) return;
      final current = auth.user;
      if (current != null) {
        final websiteVal = _websiteCtrl.text.trim();
        auth.updateCurrentUser(current.copyWith(
          name: _nameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          isPrivate: _isPrivate,
          website: websiteVal.isEmpty ? null : websiteVal,
          clearWebsite: websiteVal.isEmpty,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          interests: _selectedInterests.toList(),
        ));
      }
      final userMap = res?['user'];
      if (userMap is Map<String, dynamic>) {
        final fromServer = auth.user;
        final serverUser = _mergeServerResponse(userMap, fromServer);
        if (serverUser != null) auth.updateCurrentUser(serverUser);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  User? _mergeServerResponse(Map<String, dynamic> map, User? current) {
    try {
      final fromServer = User.fromJson(map);
      if (current == null) return fromServer;
      return fromServer.copyWith(
        interests: fromServer.interests.isNotEmpty
            ? fromServer.interests
            : current.interests,
        website: fromServer.website ?? current.website,
      );
    } catch (_) {
      return null;
    }
  }

  void _showErr(Object e) {
    String msg = 'Upload failed';
    if (e is DioException) {
      final d = e.response?.data;
      final s = d is Map && d['message'] is String ? (d['message'] as String).trim() : null;
      if (s != null && s.isNotEmpty) msg = s;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _buildAppBar(scheme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(user, scheme),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Center(child: _buildAvatar(user, scheme)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('DISPLAY NAME', scheme),
                  _input(_nameCtrl, 'Your display name', scheme),
                  const SizedBox(height: 14),

                  _label('USERNAME', scheme),
                  _input(
                    _usernameCtrl,
                    'username',
                    scheme,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Text('@',
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _label('BIO', scheme),
                  _input(_bioCtrl, 'Write something about you…', scheme,
                      maxLines: 4, maxLength: 100),
                  const SizedBox(height: 14),

                  _label('LOCATION', scheme),
                  _input(_locationCtrl, 'City, Country', scheme,
                      prefixIcon: Icons.location_on_outlined),
                  const SizedBox(height: 14),

                  _label('WEBSITE', scheme),
                  _input(_websiteCtrl, 'Add website link', scheme,
                      prefixIcon: Icons.link),
                  const SizedBox(height: 14),

                  _label('MOBILE NUMBER', scheme),
                  _input(_phoneCtrl, 'Add mobile number', scheme,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),

                  _label('INTERESTS', scheme),
                  const SizedBox(height: 10),
                  _buildInterests(scheme),
                  const SizedBox(height: 24),

                  _buildPrivateToggle(scheme),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ColorScheme scheme) {
    return AppBar(
      backgroundColor: scheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.chevron_left,
                    color: scheme.onSurface, size: 22),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: _saving ? null : _save,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kOrange, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20)),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cover image ───────────────────────────────────────────────────────────

  Widget _buildCover(dynamic user, ColorScheme scheme) {
    final coverUrl = user?.coverImage != null &&
            (user!.coverImage as String).isNotEmpty
        ? user.coverImage as String
        : null;

    return GestureDetector(
      onTap: _uploadingCover ? null : _pickCover,
      child: Container(
        height: 140,
        width: double.infinity,
        color: scheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_localCover != null)
              Image.file(_localCover!, fit: BoxFit.cover)
            else if (coverUrl != null)
              safeNetworkImage(url: coverUrl, fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 6),
                  Text(
                    'Add cover photo',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            if (_uploadingCover)
              Container(
                color: Colors.black54,
                child: Center(
                  child:
                      CircularProgressIndicator(color: scheme.primary),
                ),
              ),
            if (_localCover != null || coverUrl != null)
              Positioned(
                right: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar(dynamic user, ColorScheme scheme) {
    return GestureDetector(
      onTap: _uploadingAvatar ? null : _pickAvatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF9B59B6),
                  _kOrange,
                  Color(0xFFFFD700),
                  Color(0xFF9B59B6),
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: ClipOval(
                child: _uploadingAvatar
                    ? Container(
                        color: scheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary),
                        ),
                      )
                    : _localAvatar != null
                        ? Image.file(_localAvatar!, fit: BoxFit.cover)
                        : (user?.avatar != null &&
                                (user!.avatar as String).isNotEmpty)
                            ? safeAvatarNetworkImage(
                                url: user.avatar as String,
                                size: 84,
                                backgroundColor:
                                    scheme.surfaceContainerHighest,
                              )
                            : Container(
                                color: const Color(0xFF7C3AED),
                                child: Center(
                                  child: Text(
                                    user?.name?.isNotEmpty == true
                                        ? (user!.name as String)[0]
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
              ),
            ),
          ),
          // Camera badge — glass style
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kOrange, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: scheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field label ───────────────────────────────────────────────────────────

  Widget _label(String text, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────

  Widget _input(
    TextEditingController ctrl,
    String hint,
    ColorScheme scheme, {
    int maxLines = 1,
    int? maxLength,
    Widget? prefix,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: maxLength != null ? (_) => setState(() {}) : null,
      style: TextStyle(color: scheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        counterText:
            maxLength != null ? '${ctrl.text.length}/$maxLength' : null,
        counterStyle:
            TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon != null || prefix != null ? 0 : 14,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        prefixIcon: prefix != null
            ? prefix
            : prefixIcon != null
                ? Icon(prefixIcon,
                    color: scheme.onSurfaceVariant, size: 18)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
      ),
    );
  }

  // ── Interests ─────────────────────────────────────────────────────────────

  Widget _buildInterests(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kInterests.map((tag) {
        final selected = _selectedInterests.contains(tag);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedInterests.remove(tag);
            } else {
              _selectedInterests.add(tag);
            }
          }),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [_kOrange, _kPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : scheme.outline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _kOrange.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Private toggle ────────────────────────────────────────────────────────

  Widget _buildPrivateToggle(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private account',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Only followers can see your posts',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            activeColor: _kOrange,
          ),
        ],
      ),
    );
  }
}
