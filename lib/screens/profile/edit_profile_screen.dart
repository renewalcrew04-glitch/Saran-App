import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Controllers
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  File? _localAvatar;
  File? _localCover;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  String? _newAvatarUrl;
  String? _newCoverUrl;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final json = user?.toJson() ?? {};

    _nameCtrl.text = user?.name ?? '';
    _bioCtrl.text = user?.bio ?? '';
    _websiteCtrl.text = json['website'] ?? '';
    _locationCtrl.text = json['locationString'] ?? '';
    _phoneCtrl.text = json['phone'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
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
      _newAvatarUrl = url;

      setState(() => _uploadingAvatar = false);
    } catch (e) {
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Avatar upload failed: $e")));
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
      _newCoverUrl = url;

      setState(() => _uploadingCover = false);
    } catch (e) {
      setState(() => _uploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cover upload failed: $e")));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? uid = auth.user?.uid;

      if (uid == null) throw Exception("User not found. Please log in.");

      final Map<String, dynamic> updateData = {
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'locationString': _locationCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      if (_newAvatarUrl != null) updateData['avatar'] = _newAvatarUrl;
      if (_newCoverUrl != null) updateData['coverImage'] = _newCoverUrl;

      await _profileUpdateService.updateUserProfile(updateData, explicitUid: uid);
      await auth.loadUser();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userData = auth.user?.toJson() ?? {}; 

    final String? currentCover = _newCoverUrl ?? userData['coverImage'];
    final String? currentAvatar = _newAvatarUrl ?? userData['avatar'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_saving || _uploadingAvatar || _uploadingCover) ? null : _save,
            child: _saving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
              : const Text("Save", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER IMAGES ---
            SizedBox(
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Cover Image
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: _localCover != null 
                          ? DecorationImage(image: FileImage(_localCover!), fit: BoxFit.cover)
                          : (currentCover != null && currentCover.isNotEmpty
                              ? DecorationImage(image: NetworkImage(currentCover), fit: BoxFit.cover)
                              : null),
                      ),
                      child: _uploadingCover 
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                    ),
                  ),

                  // 2. Avatar Image
                  Positioned(
                    bottom: 0, 
                    left: 20,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.grey.shade400,
                              image: _localAvatar != null
                                ? DecorationImage(image: FileImage(_localAvatar!), fit: BoxFit.cover)
                                : (currentAvatar != null && currentAvatar.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(currentAvatar), fit: BoxFit.cover)
                                    : null),
                            ),
                            child: (currentAvatar == null && _localAvatar == null)
                                ? const Center(child: Icon(Icons.person, size: 50, color: Colors.white))
                                : null,
                          ),
                          if (_uploadingAvatar)
                            const Positioned.fill(child: CircularProgressIndicator(color: Colors.black)),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- FORM FIELDS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _PremiumTextField(label: "Name", controller: _nameCtrl),
                  _PremiumTextField(label: "Bio", controller: _bioCtrl, maxLines: 3),
                  _PremiumTextField(label: "Location", controller: _locationCtrl, icon: Icons.location_on_outlined),
                  _PremiumTextField(label: "Website", controller: _websiteCtrl, icon: Icons.link),
                  
                  // ✅ Mobile Number with +91
                  _PremiumTextField(
                    label: "Mobile Number",
                    controller: _phoneCtrl,
                    isPhone: true,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool isPhone;

  const _PremiumTextField({
    required this.label, 
    required this.controller, 
    this.maxLines = 1,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                if (icon != null && !isPhone) 
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(icon, color: Colors.grey, size: 20),
                  ),
                
                // ✅ Fixed +91 Prefix
                if (isPhone)
                  Container(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: const Text(
                      "+91",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                  ),

                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    // ✅ Limit to 10 digits for Phone
                    inputFormatters: isPhone 
                        ? [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.digitsOnly] 
                        : null,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      hintText: isPhone ? "Enter 10 digit number" : "Add $label",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}