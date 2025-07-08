
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'fullName': TextEditingController(),
    'icNumber': TextEditingController(),
    'age': TextEditingController(),
    'dob': TextEditingController(),
    'address': TextEditingController(),
    'school': TextEditingController(),
    'yearJoined': TextEditingController(),
    'medical': TextEditingController(),
    'emergencyName': TextEditingController(),
    'emergencyIc': TextEditingController(),
    'emergencyPhone': TextEditingController(),
    'emergencyEmail': TextEditingController(),
  };

  String? _section;
  String? _relationship;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('membership_forms').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _controllers.forEach((key, controller) {
        if (data.containsKey(key)) controller.text = data[key] ?? '';
      });
      setState(() {
        _section = data['section'];
        _relationship = data['relationship'];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _controllers[key]!.text = DateFormat('d MMMM y').format(picked);
      });
    }
  }

  Future<void> _selectYear(String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Year Joined',
    );
    if (picked != null) {
      setState(() {
        _controllers[key]!.text = DateFormat('y').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final data = {
          for (var entry in _controllers.entries) entry.key: entry.value.text,
          'section': _section,
          'relationship': _relationship,
        };
        await FirebaseFirestore.instance.collection('membership_forms').doc(uid).set(data, SetOptions(merge: true));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTextField(String label, String key, {
    TextInputType inputType = TextInputType.text,
    bool isDate = false,
    bool isYear = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[key],
            readOnly: isDate || isYear,
            keyboardType: inputType,
            onTap: isDate ? () => _selectDate(key) : isYear ? () => _selectYear(key) : null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Section", style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _section,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text("Select Section"),
            items: const [
              DropdownMenuItem(value: "Cadet (6-9 years old)", child: Text("Cadet (6-9 years old)")),
              DropdownMenuItem(value: "Junior (10-12 years old)", child: Text("Junior (10-12 years old)")),
              DropdownMenuItem(value: "Senior (13-15 years old)", child: Text("Senior (13-15 years old)")),
              DropdownMenuItem(value: "Pioneer (16-21 years old)", child: Text("Pioneer (16-21 years old)")),
            ],
            onChanged: (value) => setState(() => _section = value),
            validator: (value) => value == null ? 'Please select a section' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Relationship with Member", style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _relationship,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text("Select Relationship"),
            items: const [
              DropdownMenuItem(value: "Father", child: Text("Father")),
              DropdownMenuItem(value: "Mother", child: Text("Mother")),
              DropdownMenuItem(value: "Guardian", child: Text("Guardian")),
            ],
            onChanged: (value) => setState(() => _relationship = value),
            validator: (value) => value == null ? 'Please select a relationship' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Edit Profile", style: AppTextStyles.heading2),
                    const SizedBox(height: 32),
                    _buildTextField("Full Name", "fullName"),
                    _buildTextField("Identification Number", "icNumber"),
                    _buildTextField("Age", "age", inputType: TextInputType.number),
                    _buildTextField("Date of Birth", "dob", isDate: true),
                    _buildTextField("Home Address", "address"),
                    _buildDropdownField(),
                    _buildTextField("School", "school"),
                    _buildTextField("Year Joined", "yearJoined", isYear: true),
                    _buildTextField("Medical Attention", "medical"),
                    _buildTextField("Emergency Contact Full Name", "emergencyName"),
                    _buildTextField("Emergency Contact Identification Number", "emergencyIc"),
                    _buildTextField("Emergency Contact Number", "emergencyPhone", inputType: TextInputType.phone),
                    _buildTextField("Emergency Contact Email", "emergencyEmail", inputType: TextInputType.emailAddress),
                    _buildRelationshipDropdown(),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}