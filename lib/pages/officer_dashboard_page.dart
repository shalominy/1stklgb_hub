import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

/// Officer Dashboard Page - displays sidebar navigation and preview tiles
class OfficerDashboardPage extends StatefulWidget {
  const OfficerDashboardPage({super.key});

  @override
  State<OfficerDashboardPage> createState() => _OfficerDashboardPageState();
}

class _OfficerDashboardPageState extends State<OfficerDashboardPage> {
  String userName = "Officer"; // default name

  /// Fetch logged-in officer's name from Firestore
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

  /// Main build method: sidebar + topbar + dashboard grid
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          /// --- SIDE NAVIGATION BAR ---
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

                // Sidebar Links
                _navItem(Icons.dashboard, 'Dashboard', () {
                  Navigator.pushNamed(context, '/officer_dashboard');
                }),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/squad_assignment');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Squad Assignment', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/recruit_attendance');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist_rtl, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Recruit Attendance',
                        style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
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
                        Text('Sectional Attendance', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/announcement_editor');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.announcement, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Announcements', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/annual_calendar_overview');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Annual Calendar', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/award');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Awards', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/promotion');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Promotions', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/sectional_planning_form');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Sectional Planning', style: AppTextStyles.title.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Profile menu at bottom
                _navItemWithDropdown(
                  icon: Icons.person,
                  label: 'Profile',
                  dropdownItems: [
                    _dropdownItem(Icons.edit, 'Edit Profile', () {
                      Navigator.pushNamed(context, '/profile');
                    }),
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

          /// --- MAIN CONTENT ---
          Expanded(
            child: Column(
              children: [
                /// --- TOP BAR with user avatar and name ---
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

                /// --- DASHBOARD GRID VIEW (Main Tiles) ---
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
                          title: 'Sectional Attendance',
                          onTap: () {
                            Navigator.pushNamed(context, '/sectional_attendance');
                          },
                        ),
                        _dashboardPreviewTile(
                          icon: Icons.calendar_today,
                          title: 'Calendar',
                          onTap: () {
                            Navigator.pushNamed(context, '/annual_calendar_overview');
                          },
                        ),
                        _dashboardPreviewTile(
                          icon: Icons.school,
                          title: 'Sectional Planning',
                          onTap: () {
                            Navigator.pushNamed(context, '/sectional_planning_form');
                          },
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

  /// Reusable sidebar navigation item
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

  /// Profile menu with dropdown (bottom of sidebar)
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

  /// Reusable dropdown item for the Profile menu
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

  /// Dashboard tile UI with icon and label
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