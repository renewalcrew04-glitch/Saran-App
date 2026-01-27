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

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController(); // ✅ New Link Controller
  final _priceController = TextEditingController(text: '0');
  final _capacityController = TextEditingController(text: '50');
  final _instructionsController = TextEditingController();
  
  // FAQ Controllers
  final _faqQuestionController = TextEditingController();
  final _faqAnswerController = TextEditingController();

  // State
  String _selectedCategory = 'Social';
  bool _isOnlineEvent = false; // ✅ Toggle State
  File? _coverImage;
  File? _videoFile;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  
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
    _linkController.dispose();
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
      String? coverUrl;
      String? videoUrl;

      if (_coverImage != null) {
        coverUrl = await _uploadService.uploadMedia(_coverImage!.path);
      }
      if (_videoFile != null) {
        videoUrl = await _uploadService.uploadMedia(_videoFile!.path);
      }

      final DateTime startDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime.hour, _startTime.minute,
      );
      final DateTime endDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime.hour, _endTime.minute,
      );

      // ✅ Logic: If online, set location to "Online Event" and send link
      final String finalLocation = _isOnlineEvent ? "Online Event" : _locationController.text.trim();
      final String? meetingLink = _isOnlineEvent ? _linkController.text.trim() : null;

      final eventData = {
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "instructions": _instructionsController.text.trim(),
        "startDate": startDateTime.toIso8601String(),
        "endDate": endDateTime.toIso8601String(),
        "location": finalLocation,
        "category": _selectedCategory,
        "price": int.tryParse(_priceController.text) ?? 0,
        "capacity": int.tryParse(_capacityController.text) ?? 50,
        "isPublic": true,
        if (coverUrl != null) "coverUrl": coverUrl,
        if (videoUrl != null) "videoUrl": videoUrl,
        if (meetingLink != null) "meetingLink": meetingLink,
        "faqs": _faqs,
      };

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
                value: _selectedCategory,
                decoration: _inputDeco(),
                dropdownColor: Colors.white,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),

              _inputField(_descController, "Description", maxLines: 4),
              const SizedBox(height: 24),

              // ✅ Event Type Toggle (Online / Physical)
              _label("Event Type"),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isOnlineEvent = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isOnlineEvent ? Colors.black : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: !_isOnlineEvent ? Colors.black : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            "Physical / Offline",
                            style: TextStyle(
                              color: !_isOnlineEvent ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isOnlineEvent = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isOnlineEvent ? Colors.black : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isOnlineEvent ? Colors.black : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            "Online Event",
                            style: TextStyle(
                              color: _isOnlineEvent ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Conditional Input: Location OR Link
              if (_isOnlineEvent)
                _inputField(_linkController, "Meeting Link (Zoom, Meet, etc.)")
              else
                _inputField(_locationController, "Location / Address"),

              const SizedBox(height: 24),
              
              // Date & Time
              _sectionHeader("Date & Time"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _pickerBox(
                      icon: Icons.calendar_today,
                      text: DateFormat('MMM dd, yyyy').format(_selectedDate),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
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
              _sectionHeader("FAQs"),
              const SizedBox(height: 10),
              ..._faqs.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Q: ${e['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (e['answer']!.isNotEmpty) Text("A: ${e['answer']}", style: TextStyle(color: Colors.grey[700])),
                ]),
              )),
              
              // Add FAQ Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    TextField(controller: _faqQuestionController, decoration: const InputDecoration(hintText: "Question", border: InputBorder.none)),
                    const Divider(height: 1),
                    TextField(controller: _faqAnswerController, decoration: const InputDecoration(hintText: "Answer (Optional)", border: InputBorder.none)),
                    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _addFaq, icon: const Icon(Icons.add_circle), label: const Text("Add")))
                  ],
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Publish Event", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 14)));
  
  Widget _inputField(TextEditingController c, String label, {int maxLines = 1, bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      TextFormField(
        controller: c, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (val) => val!.isEmpty ? "Required" : null,
        decoration: _inputDeco(),
      ),
    ]);
  }

  InputDecoration _inputDeco() => InputDecoration(filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)));

  Widget _pickerBox({required IconData icon, required String text, required VoidCallback onTap, String? label}) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (label != null) ...[Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)), const SizedBox(height: 4)], Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))])])));
  }
}