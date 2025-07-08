import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AnnualCalendarPage extends StatefulWidget {
  const AnnualCalendarPage({super.key});

  @override
  State<AnnualCalendarPage> createState() => _AnnualCalendarPageState();
}

class _AnnualCalendarPageState extends State<AnnualCalendarPage> {
  Map<DateTime, List<Map<String, dynamic>>> meetingsByMonth = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('annual_calendar')
        .orderBy('date')
        .get();

    final grouped = <DateTime, List<Map<String, dynamic>>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final key = DateTime(date.year, date.month);
      grouped.putIfAbsent(key, () => []).add({
        ...data,
        'id': doc.id,
        'date': date,
      });
    }

    setState(() {
      meetingsByMonth = grouped;
      _isLoading = false;
    });
  }

  void _showMeetingDetails(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('EEE, dd MMM yyyy').format(meeting['date'])),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Activity: ${meeting['activity']}", style: AppTextStyles.paragraph),
            const SizedBox(height: 8),
            Text("Attire: ${meeting['attire']}", style: AppTextStyles.paragraph),
            if (meeting['remarks'] != null && meeting['remarks'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Remarks: ${meeting['remarks']}", style: AppTextStyles.paragraph),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(DateTime month, List<Map<String, dynamic>> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('MMMM yyyy').format(month), style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: meetings.map((meeting) {
            final date = meeting['date'] as DateTime;
            return GestureDetector(
              onTap: () => _showMeetingDetails(meeting),
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMM').format(date), style: AppTextStyles.heading3),
                    const SizedBox(height: 6),
                    Text(meeting['activity'], style: AppTextStyles.paragraph),
                    const SizedBox(height: 6),
                    Text("Attire: ${meeting['attire']}", style: AppTextStyles.paragraph.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Annual Calendar")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: meetingsByMonth.entries
                    .map((entry) => _buildMonthSection(entry.key, entry.value))
                    .toList(),
              ),
            ),
    );
  }
}