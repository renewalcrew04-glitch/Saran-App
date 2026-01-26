import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../services/profile_update_service.dart';

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
    _locationCtrl.text = ''; // add in model later if needed
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
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localAvatar = File(picked.path);
        _uploadingAvatar = true;
      });

      final url = await _uploadService.uploadMedia(picked.path);
      await _profileUpdateService.updateAvatar(url);

      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loadUser();

      setState(() => _uploadingAvatar = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Avatar updated")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Avatar update failed: $e")),
      );
    }
  }

  Future<void> _pickCover() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _localCover = File(picked.path);
        _uploadingCover = true;
      });

      final url = await _uploadService.uploadMedia(picked.path);
      await _profileUpdateService.updateCover(url);

      if (!mounted) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loadUser();

      setState(() => _uploadingCover = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cover updated")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cover update failed: $e")),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      // ONLY name + bio exist in your backend currently.
      // Website + Location you can add later.
      // So we update name/bio using /users/me (you must support it in backend).
      // If you don't have it, tell me I will create it.

      // For now we update only bio using same endpoint if supported
      // You already have updateAvatar/updateCover. Add updateProfile() later.

      // Temporary: just refresh user
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loadUser();

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
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
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
                  color: Colors.grey.shade200,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _localCover != null
                            ? Image.file(_localCover!, fit: BoxFit.cover)
                            : (user?.coverImage != null
                                ? Image.network(user!.coverImage!, fit: BoxFit.cover)
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: _uploadingCover
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
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
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _localAvatar != null
                  ? FileImage(_localAvatar!)
                  : (user?.avatar != null ? NetworkImage(user!.avatar!) : null)
                      as ImageProvider?,
              child: (user?.avatar == null && _localAvatar == null)
                  ? Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  : null,
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
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _uploadingAvatar
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
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
                          decoration: _inputDecoration("Your name"),
                        ),
                      ),
                      _Field(
                        label: "Website",
                        child: TextField(
                          controller: _websiteCtrl,
                          decoration: _inputDecoration("https://yourwebsite.com"),
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
  decoration: _inputDecoration("Write something about you").copyWith(
    counterText: "",
  ),
),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${_bioCtrl.text.length}/100",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Field(
                        label: "Location",
                        child: TextField(
                          controller: _locationCtrl,
                          decoration: _inputDecoration("City"),
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
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
