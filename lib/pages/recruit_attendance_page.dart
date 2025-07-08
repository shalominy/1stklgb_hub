
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecruitAttendancePage extends StatefulWidget {
  const RecruitAttendancePage({super.key});

  @override
  State<RecruitAttendancePage> createState() => _RecruitAttendancePageState();
}

class _RecruitAttendancePageState extends State<RecruitAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  Map<String, dynamic> _recruits = {};
  Map<String, List<String>> _attendance = {};
  Map<String, String> _sections = {};

  @override
  void initState() {
    super.initState();
    _loadRecruits();
  }

  Future<void> _loadRecruits() async {
    setState(() => _isLoading = true);
    final usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Girl/Parent')
        .get();

    final recruits = <String, dynamic>{};
    final attendance = <String, List<String>>{};
    final sections = <String, String>{};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final uid = doc.id;

      if (!(data.containsKey('squad'))) {
        recruits[uid] = data;

        final attSnap =
            await _firestore.collection('recruit_attendance').doc(uid).get();
        final attData = attSnap.data();
        attendance[uid] = List<String>.from(attData?['records'] ?? []);

        final memSnap = await _firestore.collection('membership_forms').doc(uid).get();
        if (memSnap.exists) {
          sections[uid] = memSnap.data()?['section'] ?? '-';
        } else {
          sections[uid] = '-';
        }
      }
    }

    setState(() {
      _recruits = recruits;
      _attendance = attendance;
      _sections = sections;
      _isLoading = false;
    });
  }

  Future<void> _markAttendance(String uid) async {
    final dateStr = _dateFormat.format(_selectedDate);
    final List<String> records = List<String>.from(_attendance[uid] ?? []);

    if (!records.contains(dateStr)) {
      records.add(dateStr);
      await _firestore
          .collection('recruit_attendance')
          .doc(uid)
          .set({'records': records}, SetOptions(merge: true));
      setState(() {
        _attendance[uid] = records;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruit Attendance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Select Date: "),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Text(_dateFormat.format(_selectedDate)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _recruits.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final uid = _recruits.keys.elementAt(index);
                        final data = _recruits[uid];
                        final records = _attendance[uid] ?? [];
                        final section = _sections[uid] ?? '-';
                        final name = data['name'] ?? '-';
                        final hasAttended =
                            records.contains(_dateFormat.format(_selectedDate));
                        return ListTile(
                          leading: Text("${index + 1}."),
                          title: Text(name),
                          subtitle: Text("Section: $section, Attendance: ${records.length} times"),
                          trailing: hasAttended
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _markAttendance(uid),
                                  child: const Text('Mark Present'),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}