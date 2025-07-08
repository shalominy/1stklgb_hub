import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class GirlParentDashboardPage extends StatefulWidget {
  const GirlParentDashboardPage({super.key});

  @override
  State<GirlParentDashboardPage> createState() => _GirlParentDashboardPageState();
}

class _GirlParentDashboardPageState extends State<GirlParentDashboardPage> {
  String userName = "Welcome";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('name')) {
        setState(() {
          userName = data['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          /// SIDE NAVIGATION
          Container(
            width: 240,
            color: AppColors.darkBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Align(
                    alignment: Alignment.center,
                    child: LogoHeader(
                      imageSize: 80,
                      overlap: 20,
                      isWhite: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _navItem(Icons.dashboard, 'Dashboard', () {
                  Navigator.pushNamed(context, '/girl_parent_dashboard');
                }),
                _navItem(Icons.campaign, 'Announcements', () {
                  Navigator.pushNamed(context, '/announcement');
                }),
                _navItem(Icons.calendar_today, 'Calendar', () {
                  Navigator.pushNamed(context, '/annual_calendar');
                }),
                const Spacer(),
                _navItemWithDropdown(
                  icon: Icons.person,
                  label: 'Profile',
                  dropdownItems: [
                    _dropdownItem(Icons.edit, 'Edit Profile', () {
                      Navigator.pushNamed(context, '/profile');
                    }),
                    _dropdownItem(Icons.logout, 'Log Out', () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }),
                  ],
                ),
              ],
            ),
          ),

          /// MAIN CONTENT + TOP NAV
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  height: 64,
                  color: AppColors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(userName, style: AppTextStyles.title),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 50),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.pushNamed(context, '/profile');
                            } else if (value == 'logout') {
                              FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text("Edit Profile"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 16),
                                  SizedBox(width: 8),
                                  Text("Log Out"),
                                ],
                              ),
                            ),
                          ],
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage('assets/images/Member_Icon.png'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// DASHBOARD PREVIEW
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      children: const [
                        // Add future dashboard preview tiles here if needed
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.title.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _navItemWithDropdown({
    required IconData icon,
    required String label,
    required List<Widget> dropdownItems,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.white,
      itemBuilder: (_) => dropdownItems
          .map((item) => PopupMenuItem<String>(value: '', child: item))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.title.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _dropdownItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}