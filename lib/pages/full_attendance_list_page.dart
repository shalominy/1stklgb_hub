import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class FullAttendanceListPage extends StatefulWidget {
  const FullAttendanceListPage({super.key});

  @override
  State<FullAttendanceListPage> createState() => _FullAttendanceListPageState();
}

class _FullAttendanceListPageState extends State<FullAttendanceListPage> {
  late Future<List<Map<String, dynamic>>> _attendanceDataFuture;

  @override
  void initState() {
    super.initState();
    _attendanceDataFuture = _fetchAttendanceData();
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceData() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Girl/Parent')
        .get();

    final members = {for (var doc in usersSnapshot.docs) doc.id: doc.data()};

    final attendanceSnapshot =
        await FirebaseFirestore.instance.collection('attendance').get();

    List<Map<String, dynamic>> result = [];

    for (var doc in attendanceSnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final records = Map<String, dynamic>.from(data['records'] ?? {});
      final year = date.year;

      for (var entry in members.entries) {
        final uid = entry.key;
        final user = entry.value;
        final name = user['name'] ?? 'Unnamed';

        result.add({
          'uid': uid,
          'name': name,
          'year': year,
          'date': date,
          'present': records[uid] ?? false,
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Full Attendance List")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attendanceDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rawData = snapshot.data!;

          final Map<int, Map<String, List<Map<String, dynamic>>>> grouped = {};

          for (var entry in rawData) {
            final year = entry['year'];
            final name = entry['name'];
            grouped.putIfAbsent(year, () => {});
            grouped[year]!.putIfAbsent(name, () => []);
            grouped[year]![name]!.add(entry);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((yearEntry) {
              final year = yearEntry.key;
              final members = yearEntry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$year", style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: AppColors.black.withOpacity(0.2)),
                    columnWidths: const {
                      0: FixedColumnWidth(30),
                      1: FixedColumnWidth(120),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1)),
                        children: [
                          const Padding(padding: EdgeInsets.all(8), child: Text("#")),
                          const Padding(padding: EdgeInsets.all(8), child: Text("Name")),
                          ..._generateDateHeaders(members),
                          const Padding(padding: EdgeInsets.all(8), child: Text("Total")),
                          const Padding(padding: EdgeInsets.all(8), child: Text("%")),
                        ],
                      ),
                      ..._generateRows(members),
                      _generateSectionSummaryRow(members),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<Widget> _generateDateHeaders(Map<String, List<Map<String, dynamic>>> members) {
    final allDates = members.values.expand((e) => e.map((r) => r['date'] as DateTime)).toSet().toList();
    allDates.sort();
    return allDates.map((d) {
      final formatted = DateFormat('d/M').format(d);
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(formatted, textAlign: TextAlign.center),
      );
    }).toList();
  }

  List<TableRow> _generateRows(Map<String, List<Map<String, dynamic>>> members) {
    final allDates = members.values.expand((e) => e.map((r) => r['date'] as DateTime)).toSet().toList();
    allDates.sort();

    int i = 0;
    return members.entries.map((entry) {
      final name = entry.key;
      final records = entry.value;
      final recordMap = {
        for (var r in records) DateFormat('yyyy-MM-dd').format(r['date']): r['present']
      };

      int total = recordMap.values.where((v) => v).length;
      int totalSessions = allDates.length;
      double percent = totalSessions > 0 ? (total / totalSessions) * 100 : 0;

      return TableRow(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Text("${++i}")),
          Padding(padding: const EdgeInsets.all(8), child: Text(name)),
          ...allDates.map((d) {
            final key = DateFormat('yyyy-MM-dd').format(d);
            final present = recordMap[key] ?? false;
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                present ? Icons.check : Icons.close,
                color: present ? Colors.green : Colors.red,
                size: 16,
              ),
            );
          }).toList(),
          Padding(padding: const EdgeInsets.all(8), child: Text("$total")),
          Padding(padding: const EdgeInsets.all(8), child: Text("${percent.toStringAsFixed(1)}%")),
        ],
      );
    }).toList();
  }

  TableRow _generateSectionSummaryRow(Map<String, List<Map<String, dynamic>>> members) {
    final allDates = members.values.expand((e) => e.map((r) => r['date'] as DateTime)).toSet().toList();
    allDates.sort();

    List<int> weeklyTotals = List.generate(allDates.length, (i) => 0);
    for (var member in members.values) {
      for (var r in member) {
        final date = r['date'] as DateTime;
        final index = allDates.indexOf(date);
        if (r['present'] == true) {
          weeklyTotals[index]++;
        }
      }
    }

    final averageAttendance = weeklyTotals.isNotEmpty
        ? weeklyTotals.reduce((a, b) => a + b) / weeklyTotals.length
        : 0;

    return TableRow(
      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.05)),
      children: [
        const Padding(padding: EdgeInsets.all(8), child: Text("")),
        const Padding(padding: EdgeInsets.all(8), child: Text("Total/Avg")),
        ...weeklyTotals.map((total) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text("$total", textAlign: TextAlign.center),
            )),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text("-", textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text("${averageAttendance.toStringAsFixed(1)} avg", textAlign: TextAlign.center),
        ),
      ],
    );
  }
}