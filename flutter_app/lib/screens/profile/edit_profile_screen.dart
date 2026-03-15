import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../services/profile_update_service.dart';
import '../../utils/media_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final UploadService _uploadService = UploadService();
  final ProfileUpdateService _profileUpdateService = ProfileUpdateService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  File? _localAvatar;
  File? _localCover;

  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _nameCtrl.text = user?.name ?? '';
    _bioCtrl.text = user?.bio ?? '';
    _websiteCtrl.text = ''; // add in model later if needed
    _locationCtrl.text = user?.location ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localAvatar = File(picked.path);
        _uploadingAvatar = true;
      });

      final url = await _uploadService.uploadMedia(picked.path);
      if (!mounted) return;
      await _profileUpdateService.updateAvatar(url, currentUserUid: auth.user?.uid);
      if (!mounted) return;
      await auth.loadUser();

      setState(() => _uploadingAvatar = false);

      messenger.showSnackBar(
        const SnackBar(content: Text("Avatar updated")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      messenger.showSnackBar(
        SnackBar(content: Text(_shortPhotoError(e))),
      );
    }
  }

  Future<void> _pickCover() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localCover = File(picked.path);
        _uploadingCover = true;
      });

      final url = await _uploadService.uploadMedia(picked.path);
      if (!mounted) return;
      final res = await _profileUpdateService.updateCover(url, currentUserUid: auth.user?.uid);
      if (!mounted) return;
      final userMap = res?['user'];
      if (userMap is Map<String, dynamic>) {
        auth.updateUserFromMap(userMap);
      } else {
        await auth.loadUser();
      }

      setState(() => _uploadingCover = false);

      messenger.showSnackBar(
        const SnackBar(content: Text("Cover updated")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);

      messenger.showSnackBar(
        SnackBar(content: Text(_shortPhotoError(e))),
      );
    }
  }

  static String _shortPhotoError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 500) return 'Server error. Try again later.';
      if (code == 400) return 'Invalid request. Try a different photo.';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'No connection. Check network and try again.';
      }
    }
    return 'Update failed. Try again.';
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await _profileUpdateService.updateProfile(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        currentUserUid: auth.user?.uid,
      );

      if (!mounted) return;
      final userMap = res?['user'];
      if (userMap is Map<String, dynamic>) {
        auth.updateUserFromMap(userMap);
      } else {
        await auth.loadUser();
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COVER
                Container(
                  height: 140,
                  width: double.infinity,
                  color: scheme.surfaceContainerHighest,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _localCover != null
                            ? Image.file(_localCover!, fit: BoxFit.cover)
                            : (user?.coverImage != null
                                ? Image.network(user!.coverImage!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, color: Colors.grey)))
                                : const SizedBox.shrink()),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: InkWell(
                          onTap: _uploadingCover ? null : _pickCover,
                          borderRadius: BorderRadius.circular(20),
                            child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _uploadingCover
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : Icon(Icons.camera_alt, size: 18, color: scheme.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // AVATAR
                Transform.translate(
  offset: const Offset(0, -40),
  child: Center(
    child: SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 3),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 88,
                height: 88,
                child: _localAvatar != null
                    ? Image.file(_localAvatar!, fit: BoxFit.cover)
                    : (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? safeAvatarNetworkImage(url: user.avatar, size: 88)
                        : CircleAvatar(
                            radius: 44,
                            backgroundColor: scheme.surfaceContainerHighest,
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : "U",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: InkWell(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _uploadingAvatar
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.camera_alt,
                        size: 14, color: scheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
),
            
                const SizedBox(height: 18),

                // FORM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _Field(
                        label: "Name",
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: _inputDecoration("Your name", scheme),
                        ),
                      ),
                      _Field(
                        label: "Website",
                        child: TextField(
                          controller: _websiteCtrl,
                          decoration: _inputDecoration("https://yourwebsite.com", scheme),
                        ),
                      ),
                      _Field(
                        label: "Bio",
                        child: Column(
                          children: [
                            TextField(
  controller: _bioCtrl,
  maxLines: 4,
  maxLength: 100,
  onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration("Write something about you", scheme).copyWith(
    counterText: "",
  ),
),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${_bioCtrl.text.length}/100",
                                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Field(
                        label: "Location",
                        child: TextField(
                          controller: _locationCtrl,
                          decoration: _inputDecoration("City", scheme),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // SAVE BUTTON
          Positioned(
            left: 80,
            right: 80,
            bottom: 10 + MediaQuery.of(context).padding.bottom,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        "Save changes",
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          if (_uploadingAvatar || _uploadingCover)
            Positioned.fill(
              child: Container(
                color: scheme.surface.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Uploading photo…',
                        style: TextStyle(
                          fontSize: 15,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ColorScheme scheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
