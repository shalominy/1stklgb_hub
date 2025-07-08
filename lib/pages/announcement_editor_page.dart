import 'dart:html' as html; // For Flutter Web file picker
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AnnouncementEditorPage extends StatefulWidget {
  const AnnouncementEditorPage({super.key});

  @override
  State<AnnouncementEditorPage> createState() => _AnnouncementEditorPageState();
}

class _AnnouncementEditorPageState extends State<AnnouncementEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _date;
  DateTime? _dueDate;
  DateTimeRange? _dateRange;

  html.File? _attachment;
  String? _attachmentName;
  bool _isUploading = false;

  Future<void> _pickAttachment() async {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.pdf,image/*,video/*,.doc,.docx,.ppt,.pptx,.gif'
      ..click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files!.first;
      setState(() {
        _attachment = file;
        _attachmentName = file.name;
      });
    });
  }

  Future<String?> _uploadAttachment() async {
    if (_attachment == null) return null;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(_attachment!);
    await reader.onLoad.first;
    final bytes = reader.result as List<int>;

    final ref = FirebaseStorage.instance.ref('announcement_attachments/${_attachment!.name}');
    final uploadTask = await ref.putData(Uint8List.fromList(bytes));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate() || _date == null) return;

    setState(() => _isUploading = true);
    final attachmentUrl = await _uploadAttachment();

    await FirebaseFirestore.instance.collection('announcements').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      'date': _date,
      'dueDate': _dueDate,
      'dateRangeStart': _dateRange?.start,
      'dateRangeEnd': _dateRange?.end,
      'attachmentUrl': attachmentUrl,
      'attachmentName': _attachmentName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Created')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Announcement"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/announcement_list');
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('View Past Announcements'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Announcement Details", style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'Link (optional)'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_date != null ? 'Date: ${DateFormat('dd/MM/yy').format(_date!)}' : 'Select Date *'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              ListTile(
                title: Text(_dueDate != null ? 'Due Date: ${DateFormat('dd/MM/yy').format(_dueDate!)}' : 'Select Due Date (optional)'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
              ListTile(
                title: Text(
                  _dateRange != null
                      ? 'Range: ${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}'
                      : 'Select Date Range (optional)',
                ),
                trailing: const Icon(Icons.date_range),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _dateRange = picked);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: Text(_attachmentName ?? 'Attach File (optional)'),
              ),
              const SizedBox(height: 24),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitAnnouncement,
                      child: const Text('Submit Announcement'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}