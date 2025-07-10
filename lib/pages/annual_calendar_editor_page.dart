// Allows officers to add or edit a meeting in the annual calendar.
// Supports date selection, activity input, attire dropdown, and remarks.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AnnualCalendarEditorPage extends StatefulWidget {
  final String? meetingId;  // ID for editing an existing meeting (null for new)
  const AnnualCalendarEditorPage({super.key, this.meetingId});

  @override
  State<AnnualCalendarEditorPage> createState() => _AnnualCalendarEditorPageState();
}

class _AnnualCalendarEditorPageState extends State<AnnualCalendarEditorPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final _activityController = TextEditingController();
  final _attireController = TextEditingController();
  final _remarksController = TextEditingController();
  String _status = 'Meeting';
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.meetingId != null;
    if (_isEditing) {
      _loadMeetingData(widget.meetingId!);
    } else {
      _isDataLoaded = true;
    }
  }

  // Load data for editing from Firestore
  Future<void> _loadMeetingData(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('annual_calendar').doc(id).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _selectedDate = (data['date'] as Timestamp).toDate();
          _status = data['status'] ?? 'Meeting';
          _activityController.text = data['activity'] ?? '';
          _attireController.text = data['attire'] ?? '';
          _remarksController.text = data['remarks'] ?? '';
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading meeting: $e')),
      );
    }
  }

  // Submit form and save to Firestore
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() => _isLoading = true);

    final data = {
      'date': _selectedDate,
      'status': _status,
      'activity': _activityController.text.trim(),
      'attire': _status == 'Meeting' ? _attireController.text.trim() : '',
      'remarks': _remarksController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    final collection = FirebaseFirestore.instance.collection('annual_calendar');

    if (_isEditing) {
      await collection.doc(widget.meetingId).update(data);  // Update existing
    } else {
      // Check for duplicate date
      final existing = await collection
          .where('date', isEqualTo: _selectedDate)
          .get();
      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meeting already exists on this date.")),
        );
        setState(() => _isLoading = false);
        return;
      }
      await collection.add(data); // Add new meeting
    }

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _activityController.dispose();
    _attireController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Meeting" : "Add New Meeting")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Meeting Details", style: AppTextStyles.heading2),
              const SizedBox(height: 16),

              // Date selection
              ListTile(
                title: Text(
                  _selectedDate != null
                      ? 'Date: ${DateFormat('EEE, dd MMM yyyy').format(_selectedDate!)}'
                      : 'Select Date *',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Status: Meeting / No Meeting
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: ['Meeting', 'No Meeting'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value ?? 'Meeting';
                    // Adjust fields based on status
                    if (_status == 'No Meeting') {
                      _activityController.text = 'No Meeting';
                      _attireController.clear();
                    } else if (_activityController.text == 'No Meeting') {
                      _activityController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Activity field
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(labelText: 'Activity *'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                readOnly: _status == 'No Meeting',
              ),
              const SizedBox(height: 12),

              // Attire dropdown (only for Meeting)
              if (_status == 'Meeting')
                DropdownButtonFormField<String>(
                  value: _attireController.text.isEmpty ? null : _attireController.text,
                  decoration: const InputDecoration(labelText: 'Attire *'),
                  items: ['Mufti', 'Uniform'].map((attire) {
                    return DropdownMenuItem<String>(
                      value: attire,
                      child: Text(attire),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _attireController.text = value ?? '';
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
              const SizedBox(height: 12),

              // Remarks (mandatory for No Meeting)
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                validator: (val) {
                  if (_status == 'No Meeting' && (val == null || val.isEmpty)) {
                    return 'Remarks required for No Meeting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit button or loader
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Update Meeting' : 'Add Meeting'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}