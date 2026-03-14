import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/space_categories.dart';
import '../../config/api_config.dart';
import '../../features/space/space_provider_riverpod.dart';
import '../../services/upload_service.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  /// If set, screen is in edit mode and will load/update this event.
  final String? eventId;

  const CreateEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final UploadService _uploadService = UploadService();

  // Text Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _capacityController = TextEditingController(text: '50');
  final _instructionsController = TextEditingController();
  
  // FAQ Controllers
  final _faqQuestionController = TextEditingController();
  final _faqAnswerController = TextEditingController();

  // State
  String _selectedCategory = 'Social';
  File? _coverImage;
  String? _existingCoverUrl; // existing cover URL when editing (so we can show/send it)
  File? _videoFile; // ✅ Video State
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isOnline = false; // false = offline (physical address), true = online (meeting link)
  
  // ✅ FAQs List
  final List<Map<String, String>> _faqs = [];

  bool _isLoading = false;
  bool _isLoadingEvent = false;

  final List<String> _categories = SpaceCategories.createEvent;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvent());
    }
  }

  Future<void> _loadEvent() async {
    if (widget.eventId == null) return;
    setState(() => _isLoadingEvent = true);
    final service = ref.read(spaceServiceProvider);
    final data = await service.getEventById(widget.eventId!);
    if (!mounted || data == null) {
      if (mounted) setState(() => _isLoadingEvent = false);
      return;
    }
    _titleController.text = data['title']?.toString() ?? '';
    _descController.text = data['description']?.toString() ?? '';
    _locationController.text = (data['location'] is Map
            ? (data['location']['address'] ?? '')
            : data['location']?.toString()) ??
        '';
    _priceController.text = (data['price'] ?? 0).toString();
    _capacityController.text = (data['capacity'] ?? 50).toString();
    _instructionsController.text = data['instructions']?.toString() ?? '';
    if (data['category'] != null && _categories.contains(data['category'])) {
      _selectedCategory = data['category'] as String;
    }
    if (data['startDate'] != null) {
      final start = DateTime.parse(data['startDate'].toString());
      _selectedDate = start;
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    }
    if (data['endDate'] != null) {
      final end = DateTime.parse(data['endDate'].toString());
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }
    if (data['faqs'] is List) {
      for (final faq in data['faqs'] as List) {
        if (faq is Map && faq['question'] != null) {
          _faqs.add({
            'question': faq['question'].toString(),
            'answer': (faq['answer'] ?? '').toString(),
          });
        }
      }
    }
    _existingCoverUrl = data['coverUrl']?.toString();
    _isOnline = data['isOnline'] == true;
    _meetingLinkController.text = data['meetingLink']?.toString() ?? '';
    if (mounted) setState(() => _isLoadingEvent = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _instructionsController.dispose();
    _faqQuestionController.dispose();
    _faqAnswerController.dispose();
    super.dispose();
  }

  // --- Pickers ---

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _coverImage = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  void _addFaq() {
    if (_faqQuestionController.text.isNotEmpty) {
      setState(() {
        _faqs.add({
          "question": _faqQuestionController.text.trim(),
          "answer": _faqAnswerController.text.trim(),
        });
        _faqQuestionController.clear();
        _faqAnswerController.clear();
      });
    }
  }

  // --- Submit ---

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isOnline && _meetingLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting / joining link for online events.')),
      );
      return;
    }
    if (!_isOnline && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a physical address for offline events.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      // 1. Upload Media (new cover image when editing)
      String? coverUrl;
      String? videoUrl;

      if (_coverImage != null) {
        try {
          coverUrl = await _uploadService.uploadMedia(_coverImage!.path);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cover image upload failed. Please try again.')),
            );
          }
          return;
        }
      }
      if (_videoFile != null) {
        videoUrl = await _uploadService.uploadMedia(_videoFile!.path);
      }

      // 2. Dates
      final DateTime startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime.hour, _startTime.minute,
      );
      final DateTime endDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime.hour, _endTime.minute,
      );

      // 3. Payload – on edit without new image, keep existing coverUrl
      final String? coverToSend = coverUrl ?? (widget.eventId != null ? _existingCoverUrl : null);
      final eventData = {
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "instructions": _instructionsController.text.trim(),
        "startDate": startDateTime.toIso8601String(),
        "endDate": endDateTime.toIso8601String(),
        "isOnline": _isOnline,
        "location": _isOnline ? null : _locationController.text.trim(),
        "meetingLink": _isOnline ? _meetingLinkController.text.trim() : null,
        "category": _selectedCategory,
        "price": int.tryParse(_priceController.text) ?? 0,
        "capacity": int.tryParse(_capacityController.text) ?? 50,
        "isPublic": true,
        if (coverToSend != null && coverToSend.isNotEmpty) "coverUrl": coverToSend,
        if (videoUrl != null) "videoUrl": videoUrl,
        "faqs": _faqs, // ✅ Send FAQs
      };

      // 4. API Call
      final service = ref.read(spaceServiceProvider);
      final isEdit = widget.eventId != null;
      if (isEdit) {
        final errorMsg = await service.updateEvent(widget.eventId!, eventData);
        if (!context.mounted) return;
        final ctx = context;
        if (errorMsg == null) {
          ref.read(spaceProvider.notifier).reset();
          ref.read(spaceProvider.notifier).load();
          // Evict cover image cache so list/details show the new image after refetch
          if (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty) {
            final oldUrl = ApiConfig.networkImageUrl(_existingCoverUrl!) ?? _existingCoverUrl!;
            await CachedNetworkImage.evictFromCache(oldUrl);
          }
          if (coverToSend != null && coverToSend.isNotEmpty) {
            final newUrl = ApiConfig.networkImageUrl(coverToSend) ?? coverToSend;
            await CachedNetworkImage.evictFromCache(newUrl);
          }
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text("Event updated successfully!")),
          );
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else {
        final success = await service.createEvent(eventData);
        if (mounted) {
          if (success) {
            ref.read(spaceProvider.notifier).reset();
            ref.read(spaceProvider.notifier).load();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Event created successfully!")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to create event.")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          widget.eventId != null ? "Edit Event" : "Create Event",
          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: _isLoadingEvent
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image (new file, existing URL, or placeholder)
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.outlineVariant),
                    image: _coverImage != null
                        ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverImage != null
                      ? null
                      : (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ApiConfig.networkImageUrl(_existingCoverUrl!) ?? _existingCoverUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180,
                              placeholder: (_, __) => Center(child: CircularProgressIndicator(color: scheme.primary)),
                              errorWidget: (_, __, ___) => _coverPlaceholder(),
                            )
                          : _coverPlaceholder()),
                ),
              ),
              const SizedBox(height: 24),

              _inputField(_titleController, "Event Title"),
              const SizedBox(height: 20),
              
              _label("Category"),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDeco(),
                dropdownColor: scheme.surface,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              _descriptionField(),
              const SizedBox(height: 20),

              // --- Online / Offline ---
              _sectionHeader("Location"),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _locationTypeChip("Offline", Icons.location_on_outlined, !_isOnline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _locationTypeChip("Online", Icons.link, _isOnline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isOnline)
                _inputField(_meetingLinkController, "Meeting / Joining link", maxLines: 1)
              else
                _inputField(_locationController, "Physical address", maxLines: 2),
              const SizedBox(height: 20),

              // --- Video Section ---
              _sectionHeader("Video (Optional)"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam_outlined, color: scheme.onSurface),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _videoFile != null ? "Video Selected: ${_videoFile!.path.split('/').last}" : "Add Video",
                          style: TextStyle(fontWeight: FontWeight.w600, color: _videoFile != null ? scheme.primary : scheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_videoFile != null) Icon(Icons.check_circle, color: scheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Date & Time ---
              _sectionHeader("Date & Time"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _pickerBox(
                      icon: Icons.calendar_today,
                      text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context, initialDate: _selectedDate, 
                          firstDate: DateTime.now(), lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _pickerBox(
                      icon: Icons.access_time, label: "Start",
                      text: _startTime.format(context),
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _startTime);
                        if (t != null) setState(() => _startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickerBox(
                      icon: Icons.access_time_filled, label: "End",
                      text: _endTime.format(context),
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _endTime);
                        if (t != null) setState(() => _endTime = t);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _inputField(_priceController, "Price (₹)", isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _inputField(_capacityController, "Capacity", isNumber: true)),
                ],
              ),

              const SizedBox(height: 20),
              _inputField(_instructionsController, "Instructions for attendees", maxLines: 2),

              const SizedBox(height: 30),

              // --- FAQs Section ---
              _sectionHeader("FAQs"),
              const SizedBox(height: 10),
              ..._faqs.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Q: ${e.value['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (e.value['answer']!.isNotEmpty) Text("A: ${e.value['answer']}", style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _faqQuestionController,
                      decoration: const InputDecoration(hintText: "Question", border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _faqAnswerController,
                      decoration: const InputDecoration(hintText: "Answer (Optional)", border: InputBorder.none),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _addFaq,
                        icon: Icon(Icons.add_circle, color: scheme.primary),
                        label: Text("Add FAQ", style: TextStyle(color: scheme.primary)),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: scheme.onPrimary, strokeWidth: 2))
                      : Text(
                          widget.eventId != null ? "Update Event" : "Publish Event",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _coverPlaceholder() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: scheme.onSurfaceVariant),
        const SizedBox(height: 8),
        Text("Add Cover Image", style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _descriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Description"),
        TextFormField(
          controller: _descController,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: _inputDeco(),
        ),
      ],
    );
  }

  Widget _locationTypeChip(String label, IconData icon, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _isOnline = (label == 'Online')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? scheme.onPrimary : scheme.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController c, String label, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
          validator: (val) => val!.isEmpty ? "Required" : null,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: _inputDeco(),
        ),
      ],
    );
  }

  InputDecoration _inputDeco() {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: scheme.primary, width: 1.5)),
    );
  }

  Widget _pickerBox({required IconData icon, required String text, required VoidCallback onTap, String? label}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.onSurface),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}