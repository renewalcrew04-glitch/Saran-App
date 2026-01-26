import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _instructions = TextEditingController();

  DateTime? date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  String category = 'Meetup';
  File? cover;

  final categories = [
    'Meetup',
    'Workshop',
    'Fitness',
    'Art',
    'Wellness',
    'Food',
    'Travel',
    'Learning',
    'Social',
  ];

  Future<void> pickCover() async {
    final res = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (res != null) setState(() => cover = File(res.path));
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> pickTime(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      setState(() => start ? startTime = t : endTime = t);
    }
  }

  void submit() async {
  final data = {
    'title': _title.text.trim(),
    'description': _description.text.trim(),
    'category': category,
    'location': _location.text.trim(),
    'price': int.tryParse(_price.text) ?? 0,
    'instructions': _instructions.text.trim(),
    'date': date?.toIso8601String(),
    'startTime': startTime?.format(context),
    'endTime': endTime?.format(context),
  };

  // TODO (later): upload cover to S3 and attach URL
  // data['coverUrl'] = uploadedUrl;

  // UNCOMMENT WHEN BACKEND IS READY
  // await SpaceService().createEvent(data);

  if (mounted) {
    Navigator.pop(context);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickCover,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: cover == null
                    ? const Center(child: Text('Add cover image'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(cover!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            _input('Title *', _title),
            _dropdown(),
            _input('Description', _description, lines: 4),

            const SizedBox(height: 20),
            _section('Date & Time'),
            _rowButton('Date', date?.toString() ?? 'Select date', pickDate),
            _rowButton('Start Time', startTime?.format(context) ?? '--:--',
                () => pickTime(true)),
            _rowButton('End Time', endTime?.format(context) ?? '--:--',
                () => pickTime(false)),

            const SizedBox(height: 20),
            _input('Location', _location),

            const SizedBox(height: 20),
            _input('Price per slot', _price, number: true),

            const SizedBox(height: 20),
            _input('Instructions', _instructions, lines: 3),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
              ),
              child: const Center(child: Text('Create Event')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w600));

  Widget _input(String label, TextEditingController c,
      {int lines = 1, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField(
      value: category,
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => category = v!),
      decoration: const InputDecoration(labelText: 'Category'),
    );
  }

  Widget _rowButton(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      trailing: Text(value),
      onTap: onTap,
    );
  }
}
