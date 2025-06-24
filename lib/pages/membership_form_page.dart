import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MembershipFormPage extends StatefulWidget {
  const MembershipFormPage({super.key});

  @override
  State<MembershipFormPage> createState() => _MembershipFormPageState();
}

class _MembershipFormPageState extends State<MembershipFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'fullName': TextEditingController(),
    'icNumber': TextEditingController(),
    'age': TextEditingController(),
    'dob': TextEditingController(),
    'address': TextEditingController(),
    'email': TextEditingController(),
    'school': TextEditingController(),
    'yearJoined': TextEditingController(),
    'medical': TextEditingController(),
    'emergencyName': TextEditingController(),
    'emergencyIc': TextEditingController(),
    'emergencyPhone': TextEditingController(),
    'emergencyEmail': TextEditingController(),
    'relationship': TextEditingController(),
  };

  String? _section;
  File? _receiptFile;
  String? _receiptUrl;

  @override
  void initState() {
    super.initState();
    _loadDraftData();
    _controllers.forEach((key, controller) {
      controller.addListener(_autoSaveForm);
    });
  }

  Future<void> _loadDraftData() async {
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
        _receiptUrl = data['receiptUrl'];
      });
    }
  }

  Future<void> _autoSaveForm() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = {
      for (var entry in _controllers.entries) entry.key: entry.value.text,
      'section': _section,
      'receiptUrl': _receiptUrl,
    };

    await FirebaseFirestore.instance.collection('membership_forms').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _receiptFile = File(path);
      });

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final ref = FirebaseStorage.instance.ref().child('receipts/$uid/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(_receiptFile!);
      final url = await uploadTask.ref.getDownloadURL();

      setState(() {
        _receiptUrl = url;
      });

      _autoSaveForm();
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _section != null && _receiptUrl != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final formData = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        'section': _section,
        'receiptUrl': _receiptUrl,
        'submittedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('membership_forms').doc(uid).set(formData);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'membershipFormSubmitted': true,
      });

      // Get role
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'];

      // Redirect
      if (!mounted) return;
      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (role == 'Officer') {
        Navigator.pushReplacementNamed(context, '/officer_dashboard');
      } else if (role == 'Squad Leader') {
        Navigator.pushReplacementNamed(context, '/squad_leader_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form and attach a receipt')),
      );
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Membership Form")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Membership Form", style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              const Text(
                "Please pay your membership fees to the account stated and attach the receipt.",
                style: AppTextStyles.subheading,
              ),
              const SizedBox(height: 32),

              _buildTextField("Full Name", "fullName"),
              _buildTextField("Identification Number", "icNumber"),
              _buildTextField("Age", "age", inputType: TextInputType.number),
              _buildTextField("Date of Birth", "dob"),
              _buildTextField("Home Address", "address"),
              _buildDropdownField(),
              _buildTextField("Email", "email", inputType: TextInputType.emailAddress),
              _buildTextField("School", "school"),
              _buildTextField("Year Joined", "yearJoined", inputType: TextInputType.number),
              _buildTextField("Medical Attention", "medical"),
              _buildTextField("Emergency Contact Full Name", "emergencyName"),
              _buildTextField("Emergency Contact Identification Number", "emergencyIc"),
              _buildTextField("Emergency Contact Number", "emergencyPhone", inputType: TextInputType.phone),
              _buildTextField("Emergency Contact Email", "emergencyEmail", inputType: TextInputType.emailAddress),
              _buildTextField("Relationship with Member", "relationship"),

              const SizedBox(height: 24),
              const Text("Receipt", style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text("Attach Receipt (PDF/Image)"),
              ),
              if (_receiptFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Selected: ${_receiptFile!.path.split('/').last}"),
                ),

              const SizedBox(height: 16),
              const Text(
                "Please pay your fees via bank transfer or DuitNow to MAYBANK 0123456789 (Shalominy Phang).",
                style: AppTextStyles.paragraph,
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Submit Form"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[key],
            keyboardType: inputType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
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
            onChanged: (value) {
              setState(() {
                _section = value;
              });
              _autoSaveForm();
            },
            validator: (value) => value == null ? 'Please select a section' : null,
          ),
        ],
      ),
    );
  }
}