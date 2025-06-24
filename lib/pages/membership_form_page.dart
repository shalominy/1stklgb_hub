import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  };

  String? _section;
  String? _relationship;
  String? _receiptUrl;
  String? _receiptPath;
  bool _isUploading = false;
  String? _uploadedFileName;
  int? _uploadedFileSize;

  @override
  void initState() {
    super.initState();
    _populateUserInfo();
    _loadDraftData();
    _controllers.forEach((key, controller) {
      controller.addListener(_autoSaveForm);
    });
  }

  Future<void> _populateUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _controllers['fullName']?.text = data['name'] ?? '';
        _controllers['email']?.text = data['email'] ?? '';
      });
    }
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
        _relationship = data['relationship'];
        _receiptUrl = data['receiptUrl'];
        _receiptPath = data['receiptPath'];
      });
    }
  }

  Future<void> _autoSaveForm() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = {
      for (var entry in _controllers.entries) entry.key: entry.value.text,
      'section': _section,
      'relationship': _relationship,
      'receiptUrl': _receiptUrl,
      'receiptPath': _receiptPath,
    };
    await FirebaseFirestore.instance.collection('membership_forms').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> _pickFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected or file has no data.")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");

    setState(() => _isUploading = true); // start loading

    // Delete previous receipt if any
    if (_receiptPath != null) {
      try {
        await FirebaseStorage.instance.ref(_receiptPath!).delete();
      } catch (e) {
        debugPrint('Error deleting old receipt: $e');
      }
    }

    final file = result.files.single;
    final fileBytes = file.bytes!;
    final fileName = file.name;
    final fileSize = file.size; // in bytes
    final newPath = 'receipts/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final ref = FirebaseStorage.instance.ref(newPath);
    final uploadTask = ref.putData(fileBytes);

    await uploadTask.whenComplete(() => null); // wait for upload to finish
    final downloadUrl = await ref.getDownloadURL();

    setState(() {
      _receiptUrl = downloadUrl;
      _receiptPath = newPath;
      _uploadedFileName = fileName;
      _uploadedFileSize = fileSize;
      _isUploading = false;
    });

    await _autoSaveForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File uploaded successfully.")),
    );
  } catch (e) {
      debugPrint('File upload failed: $e');
      setState(() => _isUploading = false); // stop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload file: $e")),
      );
    }
  }

  Future<void> _selectDate(String fieldKey) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _controllers[fieldKey]!.text = DateFormat('d MMMM y').format(picked);
      });
      _autoSaveForm();
    }
  }

  Future<void> _selectYear(String fieldKey) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Year Joined',
    );
    if (picked != null) {
      setState(() {
        _controllers[fieldKey]!.text = DateFormat('y').format(picked);
      });
      _autoSaveForm();
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _section != null &&
        _relationship != null &&
        _receiptUrl != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final formData = {
        for (var entry in _controllers.entries) entry.key: entry.value.text,
        'section': _section,
        'relationship': _relationship,
        'receiptUrl': _receiptUrl,
        'receiptPath': _receiptPath,
        'submittedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('membership_forms').doc(uid).set(formData);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'membershipFormSubmitted': true,
      });

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userDoc.data()?['role'];

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

  Widget _buildTextField(String label, String key, {
    TextInputType inputType = TextInputType.text,
    bool isDate = false,
    bool isYear = false,
    bool readOnly = false,
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
            readOnly: readOnly || isDate || isYear,
            keyboardType: inputType,
            onTap: isDate
                ? () => _selectDate(key)
                : isYear
                    ? () => _selectYear(key)
                    : null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required field';
              if (inputType == TextInputType.emailAddress &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Enter a valid email';
              }
              if (inputType == TextInputType.phone &&
                  !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                return 'Enter a valid phone number';
              }
              if (inputType == TextInputType.number &&
                  !RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Enter a valid number';
              }
              return null;
            },
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
              setState(() => _section = value);
              _autoSaveForm();
            },
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
            onChanged: (value) {
              setState(() => _relationship = value);
              _autoSaveForm();
            },
            validator: (value) => value == null ? 'Please select a relationship' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Receipt", style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickFile,
          icon: const Icon(Icons.attach_file),
          label: const Text("Attach Receipt (PDF/Image)"),
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text("Uploading... Please wait"),
              ],
            ),
          ),
        if (_uploadedFileName != null && _uploadedFileSize != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("Uploaded: $_uploadedFileName (${(_uploadedFileSize! / 1024).toStringAsFixed(2)} KB)"),
          ),
        if (_receiptUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(_receiptUrl!)),
              icon: const Icon(Icons.visibility),
              label: const Text("View Uploaded Receipt"),
            ),
          ),
      ],
    );
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
                "Please complete the membership form before proceeding to the dashboard.",
                style: AppTextStyles.subheading,
              ),
              const SizedBox(height: 32),
              _buildTextField("Full Name", "fullName"),
              _buildTextField("Identification Number", "icNumber"),
              _buildTextField("Age", "age", inputType: TextInputType.number),
              _buildTextField("Date of Birth", "dob", isDate: true),
              _buildTextField("Home Address", "address"),
              _buildDropdownField(),
              _buildTextField("Email", "email", inputType: TextInputType.emailAddress, readOnly: true),
              _buildTextField("School", "school"),
              _buildTextField("Year Joined", "yearJoined", isYear: true),
              _buildTextField("Medical Attention", "medical"),
              _buildTextField("Emergency Contact Full Name", "emergencyName"),
              _buildTextField("Emergency Contact Identification Number", "emergencyIc"),
              _buildTextField("Emergency Contact Number", "emergencyPhone", inputType: TextInputType.phone),
              _buildTextField("Emergency Contact Email", "emergencyEmail", inputType: TextInputType.emailAddress),
              _buildRelationshipDropdown(),
              const SizedBox(height: 24),
              _buildReceiptSection(),
              const SizedBox(height: 16),
              const Text(
                "Please pay your fees via bank transfer or DuitNow to MAYBANK 0123456789 (Shalominy Phang) and attach the receipt.",
                style: AppTextStyles.paragraph,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Submit Form"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}