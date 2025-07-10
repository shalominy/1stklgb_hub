import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PromotionListPage extends StatefulWidget {
  const PromotionListPage({super.key});

  @override
  State<PromotionListPage> createState() => _PromotionListPageState();
}

class _PromotionListPageState extends State<PromotionListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sections eligible for promotion display
  final List<String> _sections = ['Senior', 'Pioneer'];

  // Mapping from short promotion name to braid colour description
  final Map<String, String> _braidColourMap = {
    'JLT': 'Purple Braid',
    'YLPT': 'Gold Braid + Black Lanyard',
    'YLRALT': 'Red Braid + Yellow Braid',
    'YLGBSL': 'Blue Braid + Green Braid',
  };

  // Stores promotion records grouped by section
  Map<String, List<Map<String, dynamic>>> _promotionsBySection = {};

  // Maps user ID to full name from membership forms
  Map<String, String> _uidToFullName = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPromotionsAndNames(); // Fetch data on init
  }

  // Retrieves all promotion records and member names
  Future<void> _fetchPromotionsAndNames() async {
    final promoSnapshot = await _firestore.collection('promotions').get();
    final promoData = promoSnapshot.docs.map((doc) => doc.data()).toList();

    final memberSnapshot = await _firestore.collection('membership_forms').get();
    final Map<String, String> uidMap = {
      for (var doc in memberSnapshot.docs) doc.id: doc.data()['fullName'] ?? ''
    };

    // Group promotions by section
    Map<String, List<Map<String, dynamic>>> grouped = {
      'Senior': [],
      'Pioneer': [],
    };

    for (final promo in promoData) {
      final section = (promo['section'] as String?)?.split(' ').first ?? '';
      if (_sections.contains(section)) {
        grouped[section]!.add(promo);
      }
    }

    // Sort members alphabetically within each section
    for (final section in _sections) {
      grouped[section]!.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    }

    setState(() {
      _promotionsBySection = grouped;
      _uidToFullName = uidMap;
      _isLoading = false;
    });
  }

  // Builds a section card showing grouped promotions and members
  Widget _buildPromotionGroup(String section, List<Map<String, dynamic>> promotions) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    // Group promotions by promotion type
    for (final promo in promotions) {
      final promotion = promo['promotion'] ?? 'Unknown';
      grouped.putIfAbsent(promotion, () => []).add(promo);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...grouped.entries.map((entry) {
              final promoName = entry.key;
              final braidDesc = _braidColourMap[promoName] ?? '';

              // Generate member name list with year
              final memberNames = entry.value
                  .map((promo) {
                    final uid = promo['uid'];
                    final fullName = _uidToFullName[uid] ?? 'Unknown';
                    final year = promo['year']?.toString() ?? '';
                    return '$fullName ($year)';
                  })
                  .toList()
                ..sort(); // Alphabetical order

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$promoName Promotion', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (braidDesc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 4),
                      child: Text(braidDesc, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8),
                    child: Text(memberNames.join(', '), style: const TextStyle(color: Colors.black54)),
                  )
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotion List')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: _sections.map((section) {
                  final promos = _promotionsBySection[section] ?? [];
                  return _buildPromotionGroup(section, promos);
                }).toList(),
              ),
            ),
    );
  }
}