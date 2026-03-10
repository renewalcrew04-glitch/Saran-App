import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_settings_service.dart';
import '../services/sframe_api.dart';
import '../utils/sframe_filters.dart';
import 'camera_settings_screen.dart';

class SFrameCreateScreen extends StatefulWidget {
  const SFrameCreateScreen({super.key});

  @override
  State<SFrameCreateScreen> createState() => _SFrameCreateScreenState();
}

class _SFrameCreateScreenState extends State<SFrameCreateScreen> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _cameraLoading = true;
  bool _cameraError = false;
  File? _media;
  bool _loading = false;
  bool _showTextInput = false;
  bool _flashOn = false;
  bool _toolbarOnLeft = true;
  bool _showFilterPicker = false;
  SFrameFilter _selectedFilter = SFrameFilter.normal;
  final TextEditingController _text = TextEditingController();

  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitCamera();
  }

  Future<void> _loadSettingsAndInitCamera() async {
    _toolbarOnLeft = await CameraSettingsService.getToolbarOnLeft();
    if (mounted) setState(() {});
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final defaultFront = await CameraSettingsService.getDefaultFrontCamera();
      final targetDirection = defaultFront ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraLoading = false;
        _cameraError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraError = true;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final file = await _cameraController!.takePicture();
      if (mounted) setState(() => _media = File(file.path));
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _media = File(picked.path));
  }

  String _filterToApiValue(SFrameFilter f) {
    switch (f) {
      case SFrameFilter.warm:
        return 'warm';
      case SFrameFilter.mono:
        return 'mono';
      case SFrameFilter.contrast:
        return 'contrast';
      default:
        return 'normal';
    }
  }

  Future<void> _share() async {
    if (_text.text.trim().isEmpty && _media == null) return;

    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    try {
      String? mediaUrl;
      if (_media != null) {
        mediaUrl = await SFrameApi.uploadMedia(_media!);
        if (mediaUrl == null && _media != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload failed')),
            );
          }
          return;
        }
      }

      await SFrameApi.createFrame({
        "mediaType": _media != null ? "photo" : "text",
        "mediaUrl": mediaUrl,
        "textContent": _text.text.trim(),
        "filter": _filterToApiValue(_selectedFilter),
        "durationHours": 24,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _text.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    if (_media != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: filterToColor(_selectedFilter) ??
                const ColorFilter.mode(Colors.transparent, BlendMode.dst),
            child: Image.file(_media!, fit: BoxFit.cover),
          ),
          if (_text.text.trim().isNotEmpty)
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _text.text.trim(),
                    style: const TextStyle(
                      color: _white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                        Shadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (_cameraLoading) {
      return Container(color: _black, child: const Center(child: CircularProgressIndicator(color: _white)));
    }
    if (_cameraError || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: _black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_outlined, size: 64, color: _white.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Camera unavailable',
                style: TextStyle(color: _white.withValues(alpha: 0.7), fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, color: _white, size: 20),
                label: const Text('Choose from gallery', style: TextStyle(color: _white)),
                style: OutlinedButton.styleFrom(foregroundColor: _white, side: const BorderSide(color: _white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showTextInput = true),
                icon: const Icon(Icons.text_fields, color: _white, size: 20),
                label: const Text('Text only', style: TextStyle(color: _white)),
                style: OutlinedButton.styleFrom(foregroundColor: _white, side: const BorderSide(color: _white)),
              ),
            ],
          ),
        ),
      );
    }
    return CameraPreview(_cameraController!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildContent(),

          // Top overlay: X, flash/remove, settings – moved upward
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _OverlayIcon(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ),
                    _media != null
                        ? _OverlayIcon(
                            icon: Icons.refresh_rounded,
                            onTap: () => setState(() => _media = null),
                          )
                        : _OverlayIcon(
                            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                            onTap: () => setState(() => _flashOn = !_flashOn),
                          ),
                    _OverlayIcon(
                      icon: Icons.settings_outlined,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraSettingsScreen(),
                          ),
                        );
                        if (mounted) {
                          _toolbarOnLeft = await CameraSettingsService.getToolbarOnLeft();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Vertical toolbar (left or right per settings): text, sparkles
          if (_media != null || (!_cameraLoading && !_cameraError))
            Positioned(
              left: _toolbarOnLeft ? 12 : null,
              right: _toolbarOnLeft ? null : 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OverlayIcon(icon: Icons.text_fields_rounded, onTap: () => setState(() => _showTextInput = true)),
                    const SizedBox(height: 20),
                    _OverlayIcon(
                      icon: Icons.auto_awesome,
                      onTap: () => setState(() => _showFilterPicker = true),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom bar: capture, gallery, share
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 44),
                    // Center: capture or placeholder
                    _media == null && !_cameraError && !_cameraLoading
                        ? GestureDetector(
                            onTap: _capturePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _white, width: 3),
                                color: _white.withValues(alpha: 0.2),
                              ),
                            ),
                          )
                        : const SizedBox(width: 72),
                    // Right: gallery + share
                    Row(
                      children: [
                        _OverlayIcon(icon: Icons.photo_library_outlined, onTap: _pickFromGallery),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: _loading ? null : _share,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _loading ? _white.withValues(alpha: 0.3) : _white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _black),
                                  )
                                : const Text(
                                    'Share',
                                    style: TextStyle(color: _black, fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Text input overlay
          if (_showTextInput) _buildTextOverlay(),
          // Filter picker overlay
          if (_showFilterPicker) _buildFilterPicker(),
        ],
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Container(
      color: _black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showTextInput = false),
                    child: const Text('Cancel', style: TextStyle(color: _white)),
                  ),
                  Text(
                    'Add text',
                    style: TextStyle(color: _white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showTextInput = false),
                    child: const Text('Done', style: TextStyle(color: _white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: const InputDecorationTheme(
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                          textSelectionTheme: const TextSelectionThemeData(
                            cursorColor: Colors.white,
                            selectionColor: Colors.white38,
                            selectionHandleColor: Colors.white,
                          ),
                        ),
                        child: TextField(
                          controller: _text,
                          onChanged: (_) => setState(() {}),
                          autofocus: true,
                          maxLength: 200,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: Colors.white,
                          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                          decoration: InputDecoration(
                            hintText: "Write your story…",
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            border: InputBorder.none,
                            counterText: '',
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_text.text.length}/200',
                        style: TextStyle(color: _white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPicker() {
    return Container(
      color: _black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showFilterPicker = false),
                    child: const Text('Cancel', style: TextStyle(color: _white)),
                  ),
                  const Text('Filter', style: TextStyle(color: _white, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => setState(() => _showFilterPicker = false),
                    child: const Text('Done', style: TextStyle(color: _white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FilterChip(
                    label: 'Normal',
                    isSelected: _selectedFilter == SFrameFilter.normal,
                    onTap: () => setState(() => _selectedFilter = SFrameFilter.normal),
                  ),
                  _FilterChip(
                    label: 'Warm',
                    isSelected: _selectedFilter == SFrameFilter.warm,
                    onTap: () => setState(() => _selectedFilter = SFrameFilter.warm),
                  ),
                  _FilterChip(
                    label: 'Mono',
                    isSelected: _selectedFilter == SFrameFilter.mono,
                    onTap: () => setState(() => _selectedFilter = SFrameFilter.mono),
                  ),
                  _FilterChip(
                    label: 'Contrast',
                    isSelected: _selectedFilter == SFrameFilter.contrast,
                    onTap: () => setState(() => _selectedFilter = SFrameFilter.contrast),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverlayIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayIcon({required this.icon, required this.onTap});

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: _white, size: 26),
        ),
      ),
    );
  }
}
