import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../features/space/space_provider_riverpod.dart';
import '../../services/upload_service.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

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
  final _priceController = TextEditingController(text: '0');
  final _capacityController = TextEditingController(text: '50');
  final _instructionsController = TextEditingController();
  
  // FAQ Controllers
  final _faqQuestionController = TextEditingController();
  final _faqAnswerController = TextEditingController();

  // State
  String _selectedCategory = 'Social';
  File? _coverImage;
  File? _videoFile; // ✅ Video State
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  
  // ✅ FAQs List
  final List<Map<String, String>> _faqs = [];

  bool _isLoading = false;

  final List<String> _categories = [
    'Social', 'Wellness', 'Workshop', 'Tech', 'Art', 'Music', 'Business', 'Food', 'Travel'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
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
    setState(() => _isLoading = true);

    try {
      // 1. Upload Media
      String? coverUrl;
      String? videoUrl;

      if (_coverImage != null) {
        coverUrl = await _uploadService.uploadMedia(_coverImage!.path);
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

      // 3. Payload
      final eventData = {
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "instructions": _instructionsController.text.trim(),
        "startDate": startDateTime.toIso8601String(),
        "endDate": endDateTime.toIso8601String(),
        "location": _locationController.text.trim(),
        "category": _selectedCategory,
        "price": int.tryParse(_priceController.text) ?? 0,
        "capacity": int.tryParse(_capacityController.text) ?? 50,
        "isPublic": true,
        if (coverUrl != null) "coverUrl": coverUrl,
        if (videoUrl != null) "videoUrl": videoUrl,
        "faqs": _faqs, // ✅ Send FAQs
      };

      // 4. API Call
      final service = ref.read(spaceServiceProvider);
      final success = await service.createEvent(eventData);

      if (mounted) {
        if (success) {
          ref.read(spaceProvider.notifier).reset();
          ref.read(spaceProvider.notifier).load();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event Created Successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to create event.")),
          );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Event", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _coverImage != null
                        ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[500]),
                            const SizedBox(height: 8),
                            Text("Add Cover Image", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              _inputField(_titleController, "Event Title"),
              const SizedBox(height: 20),
              
              _label("Category"),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDeco(),
                dropdownColor: Colors.white,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              _inputField(_descController, "Description", maxLines: 4),
              const SizedBox(height: 20),

              // --- Video Section ---
              _sectionHeader("Video (Optional)"),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam_outlined, color: Colors.black87),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _videoFile != null ? "Video Selected: ${_videoFile!.path.split('/').last}" : "Add Video",
                          style: TextStyle(fontWeight: FontWeight.w600, color: _videoFile != null ? Colors.blue : Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_videoFile != null) Icon(Icons.check_circle, color: Colors.blue),
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
              _inputField(_locationController, "Location / Address"),
              const SizedBox(height: 20),

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
                  color: Colors.grey[50], borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Q: ${e.value['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (e.value['answer']!.isNotEmpty) Text("A: ${e.value['answer']}", style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
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
                        icon: const Icon(Icons.add_circle, color: Colors.black),
                        label: const Text("Add FAQ", style: TextStyle(color: Colors.black)),
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
                    backgroundColor: Colors.black, // ✅ Black Button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Publish Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 14),
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: (val) => val!.isEmpty ? "Required" : null,
          style: const TextStyle(color: Colors.black),
          decoration: _inputDeco(),
        ),
      ],
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
    );
  }

  Widget _pickerBox({required IconData icon, required String text, required VoidCallback onTap, String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)), const SizedBox(height: 4)],
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}