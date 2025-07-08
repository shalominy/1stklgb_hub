import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'award_list_page.dart';

class AwardPage extends StatefulWidget {
  const AwardPage({super.key});

  @override
  State<AwardPage> createState() => _AwardPageState();
}

class _AwardPageState extends State<AwardPage> {
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedSection;
  int? _selectedYear;

  String? _selectedServiceAward;
  String? _selectedCoreAward;
  String? _selectedElectiveAward;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _userAward = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEligibleUsers();
  }

  Future<void> _fetchEligibleUsers() async {
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['Girl/Parent', 'Squad Leader'])
        .get();
    
    final List<Map<String, dynamic>> tempMembers = [];

    for (final doc in userDocs.docs) {
      final uid = doc.id;

      final memberDoc = await FirebaseFirestore.instance
          .collection('membership_forms')
          .doc(uid)
          .get();
      
      if (memberDoc.exists) {
        final memberData = memberDoc.data()!;
        tempMembers.add({
          'id': uid,
          'name': memberData['fullName'] ?? 'Unnamed',
          'section': memberData['section'] ?? '',
        });
      }
    }

    setState(() {
      _members = tempMembers;
      _isLoading = false;
    });
  }

  Future<void> _fetchUserAward() async {
    if (_selectedUserId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('awards')
        .where('uid', isEqualTo: _selectedUserId)
        .get();

    setState(() {
      _userAward = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  String extractSectionName(String? fullSection) {
    if (fullSection == null) return '';
    return fullSection.split(' ').first; // Gets 'Cadet' from 'Cadet (6-9 years old)'
  }

  List<String> getServiceAward(String section) {
    switch (extractSectionName(section)) {
      case 'Cadet':
        return ['White Bar (Year 1)', 'White Bar (Year 2)', 'White Bar (Year 3)'];
      case 'Junior':
        return ['Navy Blue Bar (Year 1)', 'Navy Blue Bar (Year 2)', 'Navy Blue Bar (Year 3)'];
      case 'Senior':
        return ['Red Bar (Year 1)', 'Red Bar (Year 2)', 'Red Bar (Year 3)'];
      case 'Pioneer':
        return ['Saxe Blue Bar (Year 1)', 'Saxe Blue Bar (Year 2)', 'Saxe Blue Bar (Year 3)'];
      default:
        return [];
    }
  }

  List<String> getCoreAward(String section) {
    switch (extractSectionName(section)) {
      case 'Cadet':
        return ['Blue Star', 'Green Star', 'Red Star', 'Gold Star'];
      case 'Junior':
        return ['Blue Circle', 'Green Circle', 'Red Circle', 'Gold Circle'];
      case 'Senior':
        return ['Blue Rectangle', 'Green Rectangle', 'Red Rectangle', 'Gold Rectangle'];
      case 'Pioneer':
        return ['Blue Triangle', 'Green Triangle', 'Red Triangle', 'Gold Triangle'];
      default:
        return [];
    }
  }

  List<String> getElectiveAward(String section) {
    switch (extractSectionName(section)) {
      case 'Cadet':
        return [
          'Art', 'Camp', 'Christian Education', 'Cooking', 'Drama', 'Environment',
          'First Aid', 'Gardening', 'Healthy', 'Music', 'Needlecraft', 'Prayer',
          'Scripture Memory', 'Sports Girl', 'Swimming', 'Tell Me A Story'
        ];
      case 'Junior':
        return [
          'Art', 'Camp', 'Christian Education', 'Drama', 'Environment', 'First Aid',
          'Floral Art', 'Gardening', 'Music', 'Needlecraft', 'Prayer', 'Public Speaking',
          'Scholastic', 'Scripture Memory', 'Sports Girl', 'Swimming', 'Tell Me A Story'
        ];
      case 'Senior':
        return [
          'Art', 'Camp', 'Christian Education', 'Cosmetology', 'Drama', 'Environment',
          'First Aid', 'Floral Art', 'Gardening', 'Gotong-Royong', 'Music', 'Mission',
          'National Drill Camp', 'Needlecraft', 'Olympism', 'Photography', 'Prayer',
          'Public Speaking', 'Regional Drill Camp', 'Scholastic', 'Scripture Memory',
          'Sports Girl', 'Swimming'
        ];
      case 'Pioneer':
        return [
          'Art', 'Camp', 'Christian Education', 'Cooking', 'Drama', 'First Aid',
          'Floral Art', 'Gotong-Royong', 'Music', 'Mission', 'National Drill Camp',
          'Needlecraft', 'Olympism', 'Photography', 'Prayer', 'Public Speaking',
          'Regional Drill Camp', 'Scholastic', 'Scripture Memory', 'Sports Girl',
          'Social Problem', 'Swimming'
        ];
      default:
        return [];
    }
  }

  Future<void> _assignAward(String type, String name) async {
    if (_selectedUserId == null || _selectedYear == null || name.isEmpty) return;
    final alreadyHas = _userAward.any((a) => a['type'] == type && a['name'] == name);
    if (alreadyHas) return;

    final doc = FirebaseFirestore.instance.collection('awards').doc();
    await doc.set({
      'uid': _selectedUserId,
      'fullName': _selectedUserName,
      'section': _selectedSection,
      'type': type,
      'name': name,
      'year': _selectedYear,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _submitAward() async {
    if (_selectedUserId == null || _selectedYear == null) return;
    setState(() => _isSubmitting = true);

    await _assignAward('Service', _selectedServiceAward ?? '');
    await _assignAward('Core', _selectedCoreAward ?? '');
    await _assignAward('Elective', _selectedElectiveAward ?? '');
    await _fetchUserAward();

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Awards assigned successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Awards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Award List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AwardListPage()),
              );
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
                        _selectedServiceAward = null;
                        _selectedCoreAward = null;
                        _selectedElectiveAward = null;
                        _selectedYear = null;
                      });
                      _fetchUserAward();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedSection != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          hint: const Text('Select Year Achieved'),
                          value: _selectedYear,
                          items: List.generate(5, (i) {
                            final year = DateTime.now().year - i;
                            return DropdownMenuItem(value: year, child: Text('$year'));
                          }),
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedServiceAward,
                          hint: const Text('Service Award'),
                          items: getServiceAward(_selectedSection!).map((award) {
                            return DropdownMenuItem(value: award, child: Text(award));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedServiceAward = val),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCoreAward,
                          hint: const Text('Core Award'),
                          items: getCoreAward(_selectedSection!).map((award) {
                            return DropdownMenuItem(value: award, child: Text(award));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCoreAward = val),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedElectiveAward,
                          hint: const Text('Elective Award'),
                          items: getElectiveAward(_selectedSection!).map((award) {
                            return DropdownMenuItem(value: award, child: Text(award));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedElectiveAward = val),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAward,
                          icon: const Icon(Icons.check),
                          label: const Text('Assign Awards'),
                        )
                      ],
                    )
                ],
              ),
            ),
    );
  }
}