import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class AnnouncementListPage extends StatelessWidget {
  const AnnouncementListPage({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd/MM/yy').format(timestamp.toDate());
  }

  String _formatDateRange(Timestamp? start, Timestamp? end) {
    if (start == null || end == null) return '-';
    return '${DateFormat('dd/MM/yy').format(start.toDate())} - ${DateFormat('dd/MM/yy').format(end.toDate())}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Past Announcements")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final announcements = snapshot.data!.docs;

            if (announcements.isEmpty) {
              return const Center(child: Text('No announcements found.'));
            }

            return ListView.separated(
              itemCount: announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = announcements[index].data() as Map<String, dynamic>;
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '-', style: AppTextStyles.heading3),
                        const SizedBox(height: 8),
                        Text("Description:", style: AppTextStyles.title),
                        Text(data['description'] ?? '-'),
                        const SizedBox(height: 8),
                        if (data['link'] != null && data['link'].toString().isNotEmpty)
                          InkWell(
                            onTap: () => _launchUrl(data['link']),
                            child: Text(
                              data['link'],
                              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text("Date: ${_formatDate(data['date'])}"),
                        Text("Due Date: ${_formatDate(data['dueDate'])}"),
                        Text("Date Range: ${_formatDateRange(data['dateRangeStart'], data['dateRangeEnd'])}"),
                        const SizedBox(height: 8),
                        if (data['attachmentUrl'] != null)
                          Row(
                            children: [
                              const Icon(Icons.attach_file, size: 20),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _launchUrl(data['attachmentUrl']),
                                child: Text(
                                  data['attachmentName'] ?? 'View Attachment',
                                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}