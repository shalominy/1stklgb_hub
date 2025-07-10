// Allows officers to assign Squad Leaders and Assistant Squad Leaders for each squad.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SquadLeaderAssignmentPage extends StatefulWidget {
  const SquadLeaderAssignmentPage({super.key});

  @override
  State<SquadLeaderAssignmentPage> createState() => _SquadLeaderAssignmentPageState();
}

class _SquadLeaderAssignmentPageState extends State<SquadLeaderAssignmentPage> {
  final List<String> squads = [
    "Faith",
    "Righteousness",
    "Salvation",
    "Truth",
    "Peace"
  ];

  // Holds eligible squad leaders grouped by squad
  Map<String, List<Map<String, dynamic>>> squadLeaderPool = {};

  // Stores selected user ID for leader and assistant per squad
  Map<String, String?> leaderSelection = {};
  Map<String, String?> assistantSelection = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSquadLeaders();
  }

  // Fetch all users with 'Squad Leader' role and categorise them by squad
  Future<void> _loadSquadLeaders() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Squad Leader')
          .get();

      Map<String, List<Map<String, dynamic>>> membersBySquad = {};
      Map<String, String?> leaderMap = {};
      Map<String, String?> assistantMap = {};

      // Initialise empty lists for each squad
      for (final squad in squads) {
        membersBySquad[squad] = [];
      }

      // Process each Squad Leader user
      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final uid = doc.id;

        final formSnap = await FirebaseFirestore.instance
            .collection('membership_forms')
            .doc(uid)
            .get();
        final formData = formSnap.data() ?? {};

        final name = userData['name'];
        final section = formData['section'] ?? '-';
        final squad = userData['squad'];
        final squadRole = userData['squadRole'];

        final member = {
          'id': uid,
          'name': name,
          'section': section,
        };

        // Add to correct squad or all squads if unassigned
        if (squads.contains(squad)) {
          membersBySquad[squad]!.add(member);

          if (squadRole == 'Squad Leader') {
            leaderMap[squad] = uid;
          } else if (squadRole == 'Assistant Squad Leader') {
            assistantMap[squad] = uid;
          }
        } else {
          for (final s in squads) {
            membersBySquad[s]!.add(member);
          }
        }
      }

      setState(() {
        squadLeaderPool = membersBySquad;
        leaderSelection = leaderMap;
        assistantSelection = assistantMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading squad leaders: \$e');
      setState(() => isLoading = false);
    }
  }

  // Save the selected leaders to Firestore
  Future<void> _assignLeaders() async {
    for (final squad in squads) {
      final leaderId = leaderSelection[squad];
      final assistantId = assistantSelection[squad];

      final leaderName = squadLeaderPool[squad]
          ?.firstWhere((m) => m['id'] == leaderId, orElse: () => {})['name'] ?? '';
      final assistantName = squadLeaderPool[squad]
          ?.firstWhere((m) => m['id'] == assistantId, orElse: () => {})['name'] ?? '';

      // Update user documents with squad role
      if (leaderId != null) {
        await FirebaseFirestore.instance.collection('users').doc(leaderId).update({
          'squad': squad,
          'squadRole': 'Squad Leader',
        });
      }

      if (assistantId != null) {
        await FirebaseFirestore.instance.collection('users').doc(assistantId).update({
          'squad': squad,
          'squadRole': 'Assistant Squad Leader',
        });
      }

      // Update the squad document with leader details
      await FirebaseFirestore.instance.collection('squads').doc(squad).set({
        'leader': leaderId ?? '',
        'leaderName': leaderName,
        'assistant': assistantId ?? '',
        'assistantName': assistantName,
      }, SetOptions(merge: true));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Squad Leaders Assigned Successfully')),
    );

    _loadSquadLeaders();  // Reload after saving
  }

  // Build dropdown UI for each squad
  Widget _buildSquadAssignmentCard(String squad) {
    final members = squadLeaderPool[squad] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Squad $squad", style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            const Text("Assign Squad Leader:"),
            DropdownButton<String>(
              isExpanded: true,
              value: leaderSelection[squad],
              hint: const Text("Select Squad Leader"),
              items: members.map<DropdownMenuItem<String>>((member) {
                return DropdownMenuItem<String>(
                  value: member['id'],
                  child: Text("${member['name']} (${member['section']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  leaderSelection[squad] = value;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text("Assign Assistant Squad Leader:"),
            DropdownButton<String>(
              isExpanded: true,
              value: assistantSelection[squad],
              hint: const Text("Select Assistant Squad Leader"),
              items: members.map<DropdownMenuItem<String>>((member) {
                return DropdownMenuItem<String>(
                  value: member['id'],
                  child: Text("${member['name']} (${member['section']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  assistantSelection[squad] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Squad Leaders")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  const Text("Assign Squad Leader & Assistant", style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  for (final squad in squads) _buildSquadAssignmentCard(squad),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _assignLeaders,
                      child: const Text("Confirm Assignments"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}