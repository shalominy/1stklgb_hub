import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SquadAssignmentPage extends StatefulWidget {
  const SquadAssignmentPage({super.key});

  @override
  State<SquadAssignmentPage> createState() => _SquadAssignmentPageState();
}

class _SquadAssignmentPageState extends State<SquadAssignmentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined list of squad names
  final List<String> squads = ['Faith', 'Peace', 'Righteousness', 'Salvation', 'Truth'];
  
  // Squad summary data, unassigned recruits, and tracking of changes
  Map<String, Map<String, dynamic>> summary = {};     // Squad stats: section counts, leaders
  Map<String, dynamic> recruits = {};                 // Recruits needing squad assignment
  Map<String, int> attendanceCount = {};              // Recruit attendance record count
  Map<String, String?> selectedSquad = {};            // Selected assignment per recruit
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ensureSquadsExist(); // Make sure squads are initialized in Firestore
    _loadData();          // Load all users and squad details
  }

  /// Load squad summaries and identify unassigned recruits
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    summary.clear();
    recruits.clear();
    attendanceCount.clear();
    selectedSquad.clear();

    // Initialise squad summary structure
    for (final squad in squads) {
      summary[squad] = {
        'cadet': 0,
        'junior': 0,
        'senior': 0,
        'pioneer': 0,
        'total': 0,
        'leader': '',
        'assistant': '',
      };
    }

    // Get current squad leader and assistant info
    final squadDocs = await _firestore.collection('squads').get();
    for (var doc in squadDocs.docs) {
      final data = doc.data();
      final squad = doc.id;
      if (summary.containsKey(squad)) {
        summary[squad]?['leader'] = data['leaderName'] ?? '';
        summary[squad]?['assistant'] = data['assistantName'] ?? '';
      }
    }

    // Get all Girl/Parent users and classify them
    final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'Girl/Parent').get();
    for (var doc in usersSnapshot.docs) {
      final uid = doc.id;
      final squad = doc.data()['squad'];
      final formSnap = await _firestore.collection('membership_forms').doc(uid).get();
      final form = formSnap.data() ?? {};

      final name = form['fullName'] ?? '-';
      final section = form['section'] ?? '-';
      final age = form['age']?.toString() ?? '-';

      // Count weekly attendance (for recruit status)
      final attSnap = await _firestore.collection('recruit_attendance').doc(uid).get();
      final att = List<String>.from(attSnap.data()?['records'] ?? []);
      final count = att.length;

      if (squad != null && squad != '') {
        // Update existing squad summary
        summary[squad]?['total'] = (summary[squad]?['total'] ?? 0) + 1;
        switch (section) {
          case 'Cadet (6-9 years old)':
            summary[squad]?['cadet'] = (summary[squad]?['cadet'] ?? 0) + 1;
            break;
          case 'Junior (10-12 years old)':
            summary[squad]?['junior'] = (summary[squad]?['junior'] ?? 0) + 1;
            break;
          case 'Senior (13-15 years old)':
            summary[squad]?['senior'] = (summary[squad]?['senior'] ?? 0) + 1;
            break;
          case 'Pioneer (16-21 years old)':
            summary[squad]?['pioneer'] = (summary[squad]?['pioneer'] ?? 0) + 1;
            break;
        }
      } else {
        // Mark as unassigned recruit
        recruits[uid] = {
          'name': name,
          'section': section,
          'age': age,
        };
        attendanceCount[uid] = count;
      }
    }

    setState(() => _isLoading = false);
  }

  /// Assign selected squad to a user and update Firestore
  Future<void> _assignSquad(String uid, String? squad) async {
    await _firestore.collection('users').doc(uid).update({'squad': squad});
    setState(() {
      selectedSquad.remove(uid);
    });
    _loadData(); // Reload to refresh UI
  }

  /// Render the squad summary table
  Widget _buildSquadTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        const TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text("Squad")),
          Padding(padding: EdgeInsets.all(8), child: Text("Cadet")),
          Padding(padding: EdgeInsets.all(8), child: Text("Junior")),
          Padding(padding: EdgeInsets.all(8), child: Text("Senior")),
          Padding(padding: EdgeInsets.all(8), child: Text("Pioneer")),
          Padding(padding: EdgeInsets.all(8), child: Text("Total")),
          Padding(padding: EdgeInsets.all(8), child: Text("Leader")),
          Padding(padding: EdgeInsets.all(8), child: Text("Assistant")),
        ]),
        ...summary.entries.map((entry) {
          final s = entry.value;
          return TableRow(children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(entry.key)),
            Padding(padding: const EdgeInsets.all(8), child: Text("${s['cadet']}")),
            Padding(padding: const EdgeInsets.all(8), child: Text("${s['junior']}")),
            Padding(padding: const EdgeInsets.all(8), child: Text("${s['senior']}")),
            Padding(padding: const EdgeInsets.all(8), child: Text("${s['pioneer']}")),
            Padding(padding: const EdgeInsets.all(8), child: Text("${s['total']}")),
            Padding(padding: const EdgeInsets.all(8), child: Text(s['leader'] ?? '-')),
            Padding(padding: const EdgeInsets.all(8), child: Text(s['assistant'] ?? '-')),
          ]);
        }),
      ],
    );
  }

  /// UI rendering for the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Squad Assignment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: "Squad Leader Assignment",
            onPressed: () {
              Navigator.pushNamed(context, '/squad_leader_assignment');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Squad Distribution Overview", style: AppTextStyles.heading2),
                  const SizedBox(height: 12),
                  _buildSquadTable(), // Show summary table
                  const SizedBox(height: 24),
                  const Text("Recruits List", style: AppTextStyles.heading2),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(flex: 1, child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text("Age", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text("Section", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 3, child: Text("Attendance", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 4, child: Text("Assign Squad", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(),

                  /// Display list of unassigned recruits
                  Expanded(
                    child: ListView.separated(
                      itemCount: recruits.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final uid = recruits.keys.elementAt(index);
                        final r = recruits[uid];
                        final weeks = attendanceCount[uid] ?? 0;
                        return Row(
                          children: [
                            Expanded(flex: 1, child: Text("${index + 1}")),
                            Expanded(flex: 3, child: Text("${r['name']}")),
                            Expanded(flex: 2, child: Text("${r['age']}")),
                            Expanded(flex: 3, child: Text("${r['section']}")),
                            Expanded(flex: 3, child: Text("$weeks/6")), // 6 = required minimum
                            Expanded(
                              flex: 4,
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Select Squad"),
                                value: selectedSquad[uid],
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("Unassign")),
                                  ...squads.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedSquad[uid] = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Button to confirm assignment
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        for (final uid in selectedSquad.keys) {
                          await _assignSquad(uid, selectedSquad[uid]);
                        }
                      },
                      child: const Text("Confirm Assignments"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Initialise squad docs if not already created in Firestore
  Future<void> _ensureSquadsExist() async {
    final List<String> squadNames = ['Faith', 'Peace', 'Righteousness', 'Salvation', 'Truth'];
    for (final squad in squadNames) {
      final docRef = _firestore.collection('squads').doc(squad);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        await docRef.set({
          'leader': '',
          'assistant': '',
          'members': [],
          'counts': {
            'total': 0,
            'cadet': 0,
            'junior': 0,
            'senior': 0,
            'pioneer': 0,
          },
        });
      }
    }
  }
}