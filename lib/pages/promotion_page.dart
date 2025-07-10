import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'promotion_list_page.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of eligible members (Senior or Pioneer section)
  List<Map<String, dynamic>> _members = [];

  // Tracks which promotion requirements are checked
  Map<String, bool> _requirements = {};

  // Selected promotion info
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedSection;
  String? _selectedPromotion;
  int? _selectedYear;

  // Loading states
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Fixed promotion types
  final List<String> _promotions = [
    'JLT (Purple Braid)',
    'YLPT (Gold Braid + Black Lanyard)',
    'YLRALT (Red + Yellow Braids)',
    'YLGBSL (Blue + Green Braids)'
  ];

  // Checklist for each promotion
  final Map<String, List<String>> _promotionRequirements = {
    'JLT (Purple Braid)': [
      'Completed Training',
      'Led Games, Singing, Drill',
      '6-Month Observation (Captain + OIC)'
    ],
    'YLPT (Gold Braid + Black Lanyard)': [
      'Completed Training',
      '6-Month Officer Evaluation',
    ],
    'YLRALT (Red + Yellow Braids)': [
      'Completed Training',
      'Practical Assessment',
      '6-Month Observation (OIC)'
    ],
    'YLGBSL (Blue + Green Braids)': [
      'Completed Training',
      'Practical Assessment',
      '6-Month Observation (OIC)'
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchEligibleMembers(); // Load eligible members on startup
  }

  // Retrieves eligible users (Senior and Pioneer) and their full names
  Future<void> _fetchEligibleMembers() async {
    final users = await _firestore
        .collection('users')
        .where('role', whereIn: ['Girl/Parent', 'Squad Leader'])
        .get();

    List<Map<String, dynamic>> temp = [];

    for (final doc in users.docs) {
      final uid = doc.id;
      final membership = await _firestore.collection('membership_forms').doc(uid).get();
      final data = membership.data();

      if (data != null &&
          (data['section']?.startsWith('Senior') == true || data['section']?.startsWith('Pioneer') == true)) {
        temp.add({
          'id': uid,
          'name': data['fullName'] ?? 'Unnamed',
          'section': data['section'] ?? ''
        });
      }
    }

    temp.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    setState(() {
      _members = temp;
      _isLoading = false;
    });
  }

  // Submits promotion to Firestore
  Future<void> _assignPromotion() async {
    if (_selectedUserId == null || _selectedPromotion == null || _selectedYear == null) return;
    setState(() => _isSubmitting = true);

    await _firestore.collection('promotions').add({
      'uid': _selectedUserId,
      'name': _selectedUserName,
      'section': _selectedSection,
      'promotion': _selectedPromotion,
      'year': _selectedYear,
      'requirements': _requirements.entries.where((e) => e.value).map((e) => e.key).toList(),
      'timestamp': FieldValue.serverTimestamp()
    });

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion assigned successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Promotion'),
        actions: [
          // Navigate to the Promotion List page
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Promotion List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PromotionListPage()),
              );
            }
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select member from dropdown
                  DropdownButtonFormField<String>(
                    hint: const Text('Select Member'),
                    value: _selectedUserId,
                    items: _members.map((member) {
                      return DropdownMenuItem<String>(
                        value: member['id'],
                        child: Text(member['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final member = _members.firstWhere((m) => m['id'] == value);
                      setState(() {
                        _selectedUserId = value;
                        _selectedUserName = member['name'];
                        _selectedSection = member['section'];
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Select promotion type
                  DropdownButtonFormField<String>(
                    hint: const Text('Select Promotion Type'),
                    value: _selectedPromotion,
                    items: _promotions.map((promo) {
                      return DropdownMenuItem(value: promo, child: Text(promo));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPromotion = val;
                        _requirements.clear();
                        if (val != null && _promotionRequirements[val] != null) {
                          for (var r in _promotionRequirements[val]!) {
                            _requirements[r] = false;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Show checklist of promotion requirements
                  if (_requirements.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _requirements.entries.map((entry) {
                        return CheckboxListTile(
                          value: entry.value,
                          title: Text(entry.key),
                          onChanged: (val) {
                            setState(() => _requirements[entry.key] = val ?? false);
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),

                  // Select promotion year
                  DropdownButtonFormField<int>(
                    hint: const Text('Select Year'),
                    value: _selectedYear,
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(value: year, child: Text('$year'));
                    }),
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                  const SizedBox(height: 12),

                  // Submit button to assign promotion
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _assignPromotion,
                    icon: const Icon(Icons.check),
                    label: const Text('Assign Promotion'),
                  )
                ],
              ),
            ),
    );
  }
}