// Allows officers to submit Bible Study or Achievement plans.
// Supports dynamic form fields and optional attachment upload.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SectionalPlanningFormPage extends StatefulWidget {
  const SectionalPlanningFormPage({super.key});

  @override
  State<SectionalPlanningFormPage> createState() => _SectionalPlanningFormPageState();
}

class _SectionalPlanningFormPageState extends State<SectionalPlanningFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _planType = 'Bible Study'; // Default selected plan type

  // Bible Study form fields
  final TextEditingController _bibleStoryController = TextEditingController();
  final TextEditingController _bibleVerseController = TextEditingController();
  final TextEditingController _bibleDetailsController = TextEditingController();
  final TextEditingController _bibleActivityController = TextEditingController();
  final List<DateTime?> _bibleDate = List.filled(1, null);
  String? _selectedBibleOfficer;

  // Achievement form fields
  final TextEditingController _achievementNameController = TextEditingController();
  String _achievementType = 'Physical'; // Default type
  final TextEditingController _achievementDetailsController = TextEditingController();
  final List<DateTime?> _achievementDates = List.filled(4, null);
  String? _selectedAchievementOfficer;

  // File attachment
  PlatformFile? _selectedFile;

  // Officer dropdown list
  List<DropdownMenuItem<String>> _officerDropdownItems = [];
  bool _isLoadingOfficers = true;

  @override
  void initState() {
    super.initState();
    _loadOfficers(); // Load officer list from Firestore
  }

  // Load list of officers for dropdown
  Future<void> _loadOfficers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Officer')
        .get();

    setState(() {
      _officerDropdownItems = snapshot.docs.map<DropdownMenuItem<String>>((doc) {
        final name = doc.data()['name'] ?? 'Unnamed';
        return DropdownMenuItem(
          value: name,
          child: Text(name),
        );
      }).toList();
      _isLoadingOfficers = false;
    });
  }

  // Pick optional file attachment
  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  // Upload attachment to Firebase Storage
  Future<String?> _uploadAttachment(String planId) async {
    if (_selectedFile == null) return null;
    final ref = FirebaseStorage.instance.ref().child('sectional_attachments/$planId/${_selectedFile!.name}');
    await ref.putData(_selectedFile!.bytes!);
    return await ref.getDownloadURL();
  }

  // Save plan to Firestore
  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final planRef = FirebaseFirestore.instance.collection('sectional_planning').doc();
    final attachmentUrl = await _uploadAttachment(planRef.id);

    final data = <String, dynamic>{
      'type': _planType,
      'createdAt': Timestamp.now(),
      'attachmentUrl': attachmentUrl,
    };

    // Add form data based on plan type
    if (_planType == 'Bible Study') {
      data.addAll({
        'bibleStory': _bibleStoryController.text,
        'bibleVerse': _bibleVerseController.text,
        'details': _bibleDetailsController.text,
        'activity': _bibleActivityController.text,
        'date': _bibleDate[0] != null ? DateFormat('yyyy-MM-dd').format(_bibleDate[0]!) : null,
        'officer': _selectedBibleOfficer,
      });
    } else {
      data.addAll({
        'achievementName': _achievementNameController.text,
        'achievementType': _achievementType,
        'details': _achievementDetailsController.text,
        'dates': _achievementDates.whereType<DateTime>().map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
        'officer': _selectedAchievementOfficer,
      });
    }

    // Store data in Firestore
    await planRef.set(data);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan saved successfully')));
    
    // Reset form and clear state
    _formKey.currentState!.reset();
    setState(() {
      _selectedFile = null;
      _selectedBibleOfficer = null;
      _selectedAchievementOfficer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sectional Planning'),
        actions: [
          // Navigate to planning list
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Full List',
            onPressed: () => Navigator.pushNamed(context, '/sectional_planning_list'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan type dropdown
              DropdownButtonFormField<String>(
                value: _planType,
                items: const [
                  DropdownMenuItem(value: 'Bible Study', child: Text('Bible Study')),
                  DropdownMenuItem(value: 'Achievement', child: Text('Achievement')),
                ],
                onChanged: (value) => setState(() => _planType = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),

              // Show fields for Bible Study
              if (_planType == 'Bible Study') ...[
                TextFormField(controller: _bibleStoryController, decoration: const InputDecoration(labelText: 'Bible Story'), validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(controller: _bibleVerseController, decoration: const InputDecoration(labelText: 'Bible Verse'), validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(controller: _bibleDetailsController, decoration: const InputDecoration(labelText: 'Details'), maxLines: 3),
                TextFormField(controller: _bibleActivityController, decoration: const InputDecoration(labelText: 'Activity'), maxLines: 2),
                
                // Date selector
                ListTile(
                  title: const Text('Select Date'),
                  subtitle: Text(
                    _bibleDate[0] == null
                    ? 'No date selected'
                    : DateFormat('dd MMM yyyy').format(_bibleDate[0]!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime(2025, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        _bibleDate[0] = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Officer dropdown
                _isLoadingOfficers
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedBibleOfficer,
                        items: _officerDropdownItems,
                        onChanged: (value) => setState(() => _selectedBibleOfficer = value),
                        decoration: const InputDecoration(labelText: 'Assigned Officer'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
              // Show fields for Achievement
              ] else ...[
                TextFormField(controller: _achievementNameController, decoration: const InputDecoration(labelText: 'Achievement Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                DropdownButtonFormField<String>(
                  value: _achievementType,
                  items: const [
                    DropdownMenuItem(value: 'Physical', child: Text('Physical')),
                    DropdownMenuItem(value: 'Education', child: Text('Education')),
                    DropdownMenuItem(value: 'Social', child: Text('Social')),
                    DropdownMenuItem(value: 'Elective', child: Text('Elective')),
                  ],
                  onChanged: (value) => setState(() => _achievementType = value!),
                  decoration: const InputDecoration(labelText: 'Achievement Type'),
                ),
                TextFormField(controller: _achievementDetailsController, decoration: const InputDecoration(labelText: 'Details'), maxLines: 3),
                const SizedBox(height: 8),

                // 4 dates for Achievement
                ...List.generate(4, (i) => ListTile(
                      title: Text('Select Date ${i + 1}'),
                      subtitle: Text(_achievementDates[i] == null ? 'No date selected' : DateFormat('dd MMM yyyy').format(_achievementDates[i]!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2025, 12, 31),
                        );
                        if (picked != null) setState(() => _achievementDates[i] = picked);
                      },
                    )),
                
                // Officer dropdown
                _isLoadingOfficers
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedAchievementOfficer,
                        items: _officerDropdownItems,
                        onChanged: (value) => setState(() => _selectedAchievementOfficer = value),
                        decoration: const InputDecoration(labelText: 'Assigned Officer'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
              ],
              const SizedBox(height: 16),

              // File upload
              ElevatedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFile?.name ?? 'Add Attachment (Optional)'),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePlan,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}