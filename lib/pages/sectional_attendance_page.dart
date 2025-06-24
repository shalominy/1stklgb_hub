import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SectionalAttendancePage extends StatefulWidget {
  const SectionalAttendancePage({super.key});

  @override
  State<SectionalAttendancePage> createState() => _SectionalAttendancePageState();
}

class _SectionalAttendancePageState extends State<SectionalAttendancePage> {
  Map<String, bool> attendance = {};
  DateTime selectedDate = DateTime.now();
  int get totalPresent => attendance.values.where((v) => v).length;

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
        attendance.clear(); // Reset attendance when new date picked
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGirls() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Girl/Parent')
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _submitAttendance() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final collection = FirebaseFirestore.instance.collection('attendance').doc(formattedDate);

    final Map<String, dynamic> attendanceData = {
      'date': selectedDate,
      'records': attendance,
      'totalPresent': totalPresent,
    };

    await collection.set(attendanceData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully')),
    );
  }

  void _showDetails(Map<String, dynamic> girl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(girl['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age: ${girl['age'] ?? '-'}'),
            Text('Email: ${girl['email'] ?? '-'}'),
            Text('Phone: ${girl['phone'] ?? '-'}'),
            Text('Emergency Contact: ${girl['emergencyName'] ?? '-'}'),
            Text('Emergency Phone: ${girl['emergencyPhone'] ?? '-'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text("Sectional Attendance")),
      body: Padding(
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
                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("Total Present: $totalPresent", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchGirls(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final girls = snapshot.data!;
                  return ListView.builder(
                    itemCount: girls.length,
                    itemBuilder: (context, index) {
                      final girl = girls[index];
                      final name = girl['name'] ?? 'Unnamed';
                      final uid = girl['uid'] ?? name;
                      final age = girl['age'] ?? '?';

                      attendance.putIfAbsent(uid, () => false);

                      return ListTile(
                        title: Text(name),
                        subtitle: Text("Age: $age"),
                        trailing: Checkbox(
                          value: attendance[uid],
                          onChanged: (value) {
                            setState(() {
                              attendance[uid] = value!;
                            });
                          },
                        ),
                        onTap: () => _showDetails(girl),
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