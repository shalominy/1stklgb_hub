import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SquadAttendanceListPage extends StatefulWidget {
  const SquadAttendanceListPage({super.key});

  @override
  State<SquadAttendanceListPage> createState() => _SquadAttendanceListPageState();
}

class _SquadAttendanceListPageState extends State<SquadAttendanceListPage> {
  String? userSquad;

  @override
  void initState() {
    super.initState();
    _getUserSquad();
  }

  Future<void> _getUserSquad() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final squad = userDoc.data()?['squad'];

    if (squad != null) {
      debugPrint("Logged in user is part of: Squad $squad");
      setState(() {
        userSquad = 'Squad $squad';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchAttendanceData(String squad) async {
    debugPrint("Fetching attendance data for: $squad");
    final snapshot = await FirebaseFirestore.instance.collection('squad_attendance').get();

    Map<String, Map<String, dynamic>> attendanceRecords = {};
    Map<String, String> takenByMap = {};
    Set<String> allUids = {};
    List<DateTime> allDates = [];

    for (final doc in snapshot.docs) {
      final dateKey = doc.id;
      final parsedDate = DateTime.tryParse(dateKey);
      if (parsedDate == null) {
        debugPrint("Invalid date format: $dateKey");
        continue;
      }

      final squadSub = await FirebaseFirestore.instance
          .collection('squad_attendance')
          .doc(dateKey)
          .collection(squad)
          .get();

      if (squadSub.docs.isEmpty) {
        debugPrint("No data under: squad_attendance/$dateKey/$squad");
        continue;
      }

      allDates.add(parsedDate);

      Map<String, dynamic> uidToAttire = {};
      for (final subdoc in squadSub.docs) {
        final data = subdoc.data();
        final uid = data['uid'];
        final attire = data['attire'];
        final takenBy = data['takenBy'];
        if (uid == null || attire == null) continue;

        uidToAttire[uid] = attire;
        allUids.add(uid);

        if (takenBy != null && !takenByMap.containsKey(dateKey)) {
          takenByMap[dateKey] = takenBy;
        }
      }
      attendanceRecords[dateKey] = uidToAttire;
    }

    Map<String, Map<String, dynamic>> memberData = {};
    for (final uid in allUids) {
      final form = await FirebaseFirestore.instance.collection('membership_forms').doc(uid).get();
      final user = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      memberData[uid] = {
        'name': form.data()?['fullName'] ?? user.data()?['name'] ?? '-',
        'age': form.data()?['age']?.toString() ?? '-',
        'section': form.data()?['section'] ?? '-',
      };
    }

    allDates.sort();
    return {
      'attendanceRecords': attendanceRecords,
      'memberData': memberData,
      'sortedDates': allDates,
      'takenByMap': takenByMap,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Squad Attendance Summary")),
      body: userSquad == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>>(
              future: _fetchAttendanceData(userSquad!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final attendanceRecords = snapshot.data!['attendanceRecords'] as Map<String, Map<String, dynamic>>;
                final memberData = snapshot.data!['memberData'] as Map<String, Map<String, dynamic>>;
                final sortedDates = snapshot.data!['sortedDates'] as List<DateTime>;
                final takenByMap = snapshot.data!['takenByMap'] as Map<String, String>;

                final uids = memberData.keys.toList();

                int no = 1;
                List<DataRow> dataRows = uids.map((uid) {
                  final member = memberData[uid]!;
                  List<DataCell> cells = [
                    DataCell(Text(no.toString())),
                    DataCell(Text(member['name'] ?? '-')),
                    DataCell(Text(member['age'] ?? '-')),
                    DataCell(Text(member['section'] ?? '-')),
                  ];
                  for (final date in sortedDates) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final attire = attendanceRecords[dateKey]?[uid] ?? '-';
                    Color bgColor;
                    switch (attire) {
                      case 'A/10': bgColor = const Color(0xFFD0F0C0); break;
                      case 'B/7': bgColor = const Color(0xFFFFF9C4); break;
                      case 'C/5': bgColor = const Color(0xFFFFE0B2); break;
                      case 'D/0': bgColor = const Color(0xFFFFCDD2); break;
                      case 'Absent': bgColor = const Color(0xFFE0E0E0); break;
                      default: bgColor = Colors.white;
                    }
                    cells.add(DataCell(Container(
                      color: bgColor,
                      padding: const EdgeInsets.all(6),
                      child: Text(attire, style: const TextStyle(fontSize: 13)),
                    )));
                  }
                  no++;
                  return DataRow(cells: cells);
                }).toList();

                Map<String, List<int>> sectionTotals = {
                  'Cadet': List.filled(sortedDates.length, 0),
                  'Junior': List.filled(sortedDates.length, 0),
                  'Senior': List.filled(sortedDates.length, 0),
                  'Pioneer': List.filled(sortedDates.length, 0),
                };

                for (int i = 0; i < sortedDates.length; i++) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(sortedDates[i]);
                  final dateRecord = attendanceRecords[dateKey] ?? {};
                  dateRecord.forEach((uid, attire) {
                    final section = memberData[uid]?['section'] ?? '';
                    int score = 0;
                    if (attire == 'A/10') score = 10;
                    else if (attire == 'B/7') score = 7;
                    else if (attire == 'C/5') score = 5;
                    else score = 0;
                    if (sectionTotals.containsKey(section)) {
                      sectionTotals[section]![i] += score;
                    }
                  });
                }

                List<int> totalPoints = List.generate(sortedDates.length, (i) {
                  return sectionTotals.values.fold(0, (sum, list) => sum + list[i]);
                });

                List<String> takenByList = sortedDates.map((d) {
                  final key = DateFormat('yyyy-MM-dd').format(d);
                  return takenByMap[key] ?? "S";
                }).toList();

                DataRow buildTotalRow(String label, List<int> values) {
                  return DataRow(
                    cells: [
                      DataCell(Text(label)),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      ...values.map((v) => DataCell(Text(v.toString()))),
                    ],
                  );
                }

                DataRow buildTakenByRow(String label, List<String> names) {
                  return DataRow(
                    cells: [
                      DataCell(Text(label)),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      ...names.map((v) => DataCell(Text(v))).toList(),
                    ],
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text("No.")),
                      const DataColumn(label: Text("Name")),
                      const DataColumn(label: Text("Age")),
                      const DataColumn(label: Text("Section")),
                      ...sortedDates.map((d) => DataColumn(
                        label: Text(DateFormat('d MMM').format(d), style: const TextStyle(fontSize: 12)),
                      )),
                    ],
                    rows: [
                      ...dataRows,
                      buildTotalRow("Cadet", sectionTotals['Cadet']!),
                      buildTotalRow("Junior", sectionTotals['Junior']!),
                      buildTotalRow("Senior", sectionTotals['Senior']!),
                      buildTotalRow("Pioneer", sectionTotals['Pioneer']!),
                      buildTotalRow("Total", totalPoints),
                      buildTakenByRow("Taken By", takenByList),
                    ],
                  ),
                );
              },
            ),
    );
  }
}