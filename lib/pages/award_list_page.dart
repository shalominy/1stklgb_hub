import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AwardListPage extends StatefulWidget {
  const AwardListPage({super.key});

  @override
  State<AwardListPage> createState() => _AwardListPageState();
}

class _AwardListPageState extends State<AwardListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _sections = ['Cadet', 'Junior', 'Senior', 'Pioneer'];
  final List<String> _awardTypes = ['Service', 'Core', 'Elective'];

  String? _selectedType;
  Map<String, Map<String, List<Map<String, dynamic>>>> _awardBySection = {};
  Map<String, String> _uidToFullName = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAwardsAndNames();
  }

  Future<void> _fetchAwardsAndNames() async {
    final awardSnapshot = await _firestore.collection('awards').get();
    final awardData = awardSnapshot.docs.map((doc) => doc.data()).toList();

    final memberSnapshot = await _firestore.collection('membership_forms').get();
    final Map<String, String> uidMap = {
      for (var doc in memberSnapshot.docs) doc.id: doc.data()['fullName'] ?? ''
    };

    Map<String, Map<String, List<Map<String, dynamic>>>> result = {};

    for (final section in _sections) {
      result[section] = {'Service': [], 'Core': [], 'Elective': []};
    }

    for (final award in awardData) {
      final section = (award['section'] as String?)?.split(' ').first ?? '';
      final type = award['type'] ?? '';
      if (_sections.contains(section) && _awardTypes.contains(type)) {
        result[section]![type]!.add(award);
      }
    }

    setState(() {
      _awardBySection = result;
      _uidToFullName = uidMap;
      _isLoading = false;
    });
  }

  Widget _buildAwardGroup(String type, List<Map<String, dynamic>> awards) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final award in awards) {
      final name = award['name'] ?? '';
      grouped.putIfAbsent(name, () => []).add(award);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('$type Awards', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ...grouped.entries.map((entry) {
          final awardName = entry.key;
          final memberNames = entry.value
              .map((award) {
                final uid = award['uid'];
                final year = award['year']?.toString() ?? '';
                final fullName = _uidToFullName[uid] ?? 'Unknown';
                return '$fullName ($year)';
              })
              .toList()
            ..sort(); // Alphabetical

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(awardName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                child: Text(memberNames.join(', '), style: const TextStyle(color: Colors.black54)),
              )
            ],
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Award List')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    hint: const Text('Filter by Award Type'),
                    items: [null, ..._awardTypes].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type ?? 'All Types'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: _sections.map((section) {
                        final service = _awardBySection[section]?['Service'] ?? [];
                        final core = _awardBySection[section]?['Core'] ?? [];
                        final elective = _awardBySection[section]?['Elective'] ?? [];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(section, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                if (_selectedType == null || _selectedType == 'Service')
                                  _buildAwardGroup('Service', service),
                                if (_selectedType == null || _selectedType == 'Core')
                                  _buildAwardGroup('Core', core),
                                if (_selectedType == null || _selectedType == 'Elective')
                                  _buildAwardGroup('Elective', elective),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}