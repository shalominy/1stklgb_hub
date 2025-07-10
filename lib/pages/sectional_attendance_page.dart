import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

// This page allows officers to mark and submit sectional attendance for all girls.
// Users can pick a date, mark attendance via checkboxes, view full member profiles,
// and navigate to a past attendance directory.

class SectionalAttendancePage extends StatefulWidget {
  const SectionalAttendancePage({super.key});

  @override
  State<SectionalAttendancePage> createState() => _SectionalAttendancePageState();
}

class _SectionalAttendancePageState extends State<SectionalAttendancePage> {
  // Stores each girl's UID mapped to a boolean attendance status
  Map<String, bool> attendance = {};

  // Defaults to today's date for attendance
  DateTime selectedDate = DateTime.now();

  // Counts the number of users marked present
  int get totalPresent => attendance.values.where((v) => v).length;

  // Opens a calendar picker to choose an attendance date
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        attendance.clear(); // Reset attendance if date changes
      });
    }
  }

  // Fetches list of all girls with a completed membership form (section is not null)
  Future<List<Map<String, dynamic>>> _fetchGirls() async {
    final query = await FirebaseFirestore.instance
        .collection('membership_forms')
        .where('section', isNotEqualTo: null)
        .get();
    return query.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id; // Attach UID to each record
      return data;
    }).toList();
  }

  // Saves attendance to Firestore under the selected date
  Future<void> _submitAttendance() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final doc = FirebaseFirestore.instance.collection('attendance').doc(formattedDate);

    final Map<String, dynamic> attendanceData = {
      'date': selectedDate,
      'records': attendance,
      'totalPresent': totalPresent,
    };

    await doc.set(attendanceData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully')),
    );
  }

  // Displays detailed profile of the selected girl in a dialog
  void _showDetails(Map<String, dynamic> girl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(girl['fullName'] ?? 'Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${girl['fullName'] ?? '-'}'),
              Text('Email: ${girl['email'] ?? '-'}'),
              Text('Phone: ${girl['phone'] ?? '-'}'),
              Text('IC Number: ${girl['icNumber'] ?? '-'}'),
              Text('Date of Birth: ${girl['dob'] ?? '-'}'),
              Text('Year Joined: ${girl['yearJoined'] ?? '-'}'),
              Text('School: ${girl['school'] ?? '-'}'),
              Text('Section: ${girl['section'] ?? '-'}'),
              Text('Relationship: ${girl['relationship'] ?? '-'}'),
              Text('Emergency Name: ${girl['emergencyName'] ?? '-'}'),
              Text('Emergency Phone: ${girl['emergencyPhone'] ?? '-'}'),
              Text('Emergency Email: ${girl['emergencyEmail'] ?? '-'}'),
              Text('Emergency IC: ${girl['emergencyIc'] ?? '-'}'),
              Text('Address: ${girl['address'] ?? '-'}'),
              Text('Medical Conditions: ${girl['medical'] ?? '-'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Navigates to the full attendance list page
  void _navigateToAttendanceDirectory() {
    Navigator.pushNamed(context, '/full_attendance_list');
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sectional Attendance"),
        actions: [
          /// Button to open the full attendance record directory
          IconButton(
            icon: const Icon(Icons.folder_shared),
            tooltip: 'View Full Attendance List',
            onPressed: _navigateToAttendanceDirectory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date picker and total present counter
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Pick Date"),
                ),
                const SizedBox(width: 12),
                Text(formattedDate, style: AppTextStyles.subheading),
                const Spacer(),
                Text("Total Present: $totalPresent", style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            
            // Attendance list for each girl
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchGirls(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final girls = snapshot.data!;

                  return ListView.separated(
                    itemCount: girls.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final girl = girls[index];
                      final uid = girl['uid'];
                      final name = girl['fullName'] ?? '-';
                      final age = girl['age'] ?? '-';
                      final section = girl['section'] ?? '-';
                      final emergencyPhone = girl['emergencyPhone'] ?? '-';

                      // Initialise attendance value if not already present
                      attendance.putIfAbsent(uid, () => false);

                      return ListTile(
                        tileColor: AppColors.white,
                        leading: Text('${index + 1}', style: AppTextStyles.paragraph),
                        title: Text(name, style: AppTextStyles.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Age: $age | Section: $section', style: AppTextStyles.paragraph),
                            Text('Emergency: $emergencyPhone', style: AppTextStyles.paragraph),
                          ],
                        ),
                        trailing: Checkbox(
                          value: attendance[uid],
                          onChanged: (value) {
                            setState(() {
                              attendance[uid] = value!;
                            });
                          },
                        ),
                        onTap: () => _showDetails(girl), // Tap to view full profile
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Submit attendance button
            ElevatedButton.icon(
              onPressed: _submitAttendance,
              icon: const Icon(Icons.save),
              label: const Text("Save Attendance"),
            ),
          ],
        ),
      ),
    );
  }
}