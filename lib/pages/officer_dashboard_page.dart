import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class OfficerDashboardPage extends StatefulWidget {
  const OfficerDashboardPage({super.key});

  @override
  State<OfficerDashboardPage> createState() => _OfficerDashboardPageState();
}

class _OfficerDashboardPageState extends State<OfficerDashboardPage> {
  String userName = "Officer";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
                  padding: EdgeInsets.all(16.0),
                  child: LogoHeader(
                    imageSize: 60,
                    overlap: 20,
                    isWhite: true,
                  ),
                ),
                const SizedBox(height: 32),
                _navItem(Icons.dashboard, 'Dashboard'),
                _navItem(Icons.groups, 'Squad'),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/sectional_attendance');
                  },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Sectional Attendance',
                          style: AppTextStyles.title.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                ),

                _navItem(Icons.announcement, 'Announcements'),
                _navItem(Icons.calendar_today, 'Calendar'),
                _navItem(Icons.emoji_events, 'Awards'),
                _navItem(Icons.upgrade, 'Promotions'),
                _navItem(Icons.school, 'Sectional Planning'),
                const Spacer(),
                _navItemWithDropdown(
                  icon: Icons.person,
                  label: 'Profile',
                  dropdownItems: [
                    _dropdownItem(Icons.edit, 'Edit Profile', () {}),
                    _dropdownItem(Icons.logout, 'Log Out', () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
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
                /// TOP BAR
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
                              // TODO: Navigate to edit profile
                            } else if (value == 'logout') {
                              FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
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
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: const AssetImage(
                              'assets/images/Officer_Icon.png',
                            ),
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
                      children: [
                        _dashboardPreviewTile(
                          icon: Icons.check_circle,
                          title: 'Attendance',
                          onTap: () {
                            Navigator.pushNamed(context, '/sectional_attendance');
                          },
                        ),
                        _dashboardPreviewTile(
                          icon: Icons.calendar_today,
                          title: 'Calendar',
                          onTap: () {},
                        ),
                        _dashboardPreviewTile(
                          icon: Icons.school,
                          title: 'Sectional Planning',
                          onTap: () {},
                        ),
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

  Widget _navItem(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // TODO: Handle navigation
      },
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
          .map((item) => PopupMenuItem<String>(
                value: '',
                child: item,
              ))
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

  Widget _dashboardPreviewTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: AppColors.blue),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.heading3),
          ],
        ),
      ),
    );
  }
}