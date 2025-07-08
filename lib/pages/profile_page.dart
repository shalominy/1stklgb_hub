import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? profileImageUrl;
  bool isLoading = true;
  Map<String, String> _profileData = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final formDoc = await FirebaseFirestore.instance.collection('membership_forms').doc(uid).get();

    final userData = userDoc.data() ?? {};
    final formData = formDoc.data() ?? {};

    setState(() {
      profileImageUrl = userData['profileImageUrl'];
      _profileData = {
        'Full Name': formData['fullName'] ?? userData['name'] ?? '',
        'Identification Number': formData['icNumber'] ?? '',
        'Age': formData['age'] ?? '',
        'Date of Birth': formData['dob'] ?? '',
        'Home Address': formData['address'] ?? '',
        'Section': formData['section'] ?? '',
        'Email': formData['email'] ?? userData['email'] ?? '',
        'School': formData['school'] ?? '',
        'Year Joined': formData['yearJoined'] ?? '',
        'Medical Attention': formData['medical'] ?? '',
        'Emergency Contact Full Name': formData['emergencyName'] ?? '',
        'Emergency Contact Identification Number': formData['emergencyIc'] ?? '',
        'Emergency Contact Number': formData['emergencyPhone'] ?? '',
        'Emergency Contact Email': formData['emergencyEmail'] ?? '',
        'Relationship with Member': formData['relationship'] ?? '',
        'Receipt': formData['receiptUrl'] ?? '',
      };
      isLoading = false;
    });
  }

  Future<void> _uploadProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final Uint8List fileBytes = result.files.single.bytes!;
      final String fileName = 'profile_pictures/$uid.png';

      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putData(fileBytes);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        profileImageUrl = downloadUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _profileData.entries.map((entry) {
                            final isReceipt = entry.key == 'Receipt';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${entry.key}: ', style: AppTextStyles.heading3),
                                  Expanded(
                                    child: isReceipt && entry.value.isNotEmpty
                                        ? TextButton.icon(
                                            onPressed: () {
                                              final url = Uri.parse(entry.value);
                                              launchUrl(url);
                                            },
                                            icon: const Icon(Icons.receipt),
                                            label: const Text("View Receipt"),
                                          )
                                        : Text(entry.value, style: AppTextStyles.field),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : const AssetImage('assets/images/Member_Icon.png') as ImageProvider,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _uploadProfilePicture,
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload Picture"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit_profile');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profile"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}