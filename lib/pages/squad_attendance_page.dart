import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class SquadAttendancePage extends StatefulWidget {
  const SquadAttendancePage({super.key});

  @override
  State<SquadAttendancePage> createState() => _SquadAttendancePageState();
}

class _SquadAttendancePageState extends State<SquadAttendancePage> {
  DateTime selectedDate = DateTime.now();
  String? selectedSquad;
  String? leaderUid;
  bool isSquadLeader = false;

  final List<String> attireOptions = ['A/10', 'B/7', 'C/5', 'D/0', 'Absent'];
  Map<String, String> attireSelections = {};

  @override
  void initState() {
    super.initState();
    _initialiseUserSquad();
  }

  Future<void> _initialiseUserSquad() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    final userData = userDoc.data();

    if (userData != null && userData['squad'] != null) {
      final squadName = userData['squad'];
      final squadDoc = await FirebaseFirestore.instance.collection('squads').doc(squadName).get();
      final squadData = squadDoc.data();
      setState(() {
        selectedSquad = 'Squad $squadName';
        leaderUid = squadData?['leader'];
        isSquadLeader = userData['role'] == 'Squad Leader';
      });
    }
  }

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
        attireSelections.clear();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSquadMembers() async {
    if (selectedSquad == null) return [];

    final squadName = selectedSquad!.split(' ').last;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('squad', isEqualTo: squadName)
        .where('role', whereIn: ['Girl/Parent', 'Squad Leader'])
        .get();

    List<Map<String, dynamic>> members = [];

    for (final doc in userQuery.docs) {
      final user = doc.data();
      final uid = doc.id;

      final formDoc = await FirebaseFirestore.instance.collection('membership_forms').doc(uid).get();
      final form = formDoc.data();

      members.add({
        'uid': uid,
        'name': form?['fullName'] ?? user['name'] ?? 'Unnamed',
        'age': form?['age'] ?? '-',
        'section': form?['section'] ?? '-',
        'role': user['role'] ?? 'Girl/Parent',
      });
    }

    return members;
  }

  Future<void> _submitAttendance() async {
    if (selectedSquad == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final docRef = FirebaseFirestore.instance
        .collection('squad_attendance')
        .doc(formattedDate)
        .collection(selectedSquad!);

    for (final entry in attireSelections.entries) {
      final uid = entry.key;
      final attire = entry.value;

      await docRef.doc(uid).set({
        'uid': uid,
        'attire': attire,
        'timestamp': Timestamp.fromDate(selectedDate),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Squad attendance saved successfully')),
    );
  }

  void _navigateToAttendanceList() {
    Navigator.pushNamed(context, '/squad_attendance_list');
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Squad Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Attendance List',
            onPressed: _navigateToAttendanceList,
          ),
        ],
      ),
      body: selectedSquad == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                      DropdownButton<String>(
                        value: selectedSquad,
                        items: [selectedSquad!].map((squad) {
                          return DropdownMenuItem<String>(
                            value: squad,
                            child: Text(squad),
                          );
                        }).toList(),
                        onChanged: isSquadLeader
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedSquad = value;
                                    attireSelections.clear();
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchSquadMembers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final members = snapshot.data!;
                        if (members.isEmpty) {
                          return const Center(child: Text('No members found.'));
                        }

                        return ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final uid = member['uid'];
                            final name = member['name'];
                            final age = member['age'];
                            final section = member['section'];
                            final role = member['role'] ?? 'Girl/Parent';

                            String displayName = name;
                            if (role == 'Squad Leader') {
                              if (uid == leaderUid) {
                                displayName += ' [Squad Leader]';
                              } else {
                                displayName += ' [Assistant Squad Leader]';
                              }
                            }

                            attireSelections.putIfAbsent(uid, () => 'Absent');

                            return ListTile(
                              leading: Text('${index + 1}', style: AppTextStyles.paragraph),
                              title: Text(displayName, style: AppTextStyles.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Age: $age | Section: $section'),
                                  DropdownButton<String>(
                                    value: attireSelections[uid],
                                    items: attireOptions.map((option) {
                                      return DropdownMenuItem<String>(
                                        value: option,
                                        child: Text(option),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          attireSelections[uid] = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
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