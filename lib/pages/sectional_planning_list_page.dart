import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SectionalPlanningListPage extends StatelessWidget {
  const SectionalPlanningListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sectional Planning List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sectional_planning')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No planning data found.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isBibleStudy = data['type'] == 'Bible Study';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBibleStudy)
                    Expanded(child: _buildBibleStudyCard(data))
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 16),
                  if (!isBibleStudy)
                    Expanded(child: _buildAchievementCard(data))
                  else
                    const Expanded(child: SizedBox()),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBibleStudyCard(Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📖 Bible Study', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Story: ${data['bibleStory'] ?? '-'}'),
            Text('Verse: ${data['bibleVerse'] ?? '-'}'),
            Text('Date: ${_formatDate(data['date'])}'),
            Text('Details: ${data['details'] ?? '-'}'),
            Text('Activity: ${data['activity'] ?? '-'}'),
            Text('Officer: ${data['officer'] ?? '-'}'),
            if (data['attachmentUrl'] != null)
              TextButton(
                onPressed: () {
                  // Implement attachment preview logic
                },
                child: const Text('View Attachment'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> data) {
    final List<dynamic> dates = data['dates'] ?? [];
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏅 Achievement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Name: ${data['achievementName'] ?? '-'}'),
            Text('Type: ${data['achievementType'] ?? '-'}'),
            Text('Details: ${data['details'] ?? '-'}'),
            Text('Dates: ${dates.map((d) => DateFormat('d MMM').format(DateTime.parse(d))).join(', ')}'),
            Text('Officer: ${data['officer'] ?? '-'}'),
            if (data['attachmentUrl'] != null)
              TextButton(
                onPressed: () {
                  // Implement attachment preview logic
                },
                child: const Text('View Attachment'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}