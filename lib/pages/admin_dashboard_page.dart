import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String userName = "Admin";

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
                /// Logo Header
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

                _navItem(Icons.dashboard, 'Dashboard'),
                _navItem(Icons.people, 'Users List'),
                _navItem(Icons.article, 'Membership Forms'),

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
                            // ignore: prefer_const_constructors
                            PopupMenuItem(
                              value: 'edit',
                              // ignore: prefer_const_constructors
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text("Edit Profile"),
                                ],
                              ),
                            ),
                            // ignore: prefer_const_constructors
                            PopupMenuItem(
                              value: 'logout',
                              // ignore: prefer_const_constructors
                              child: Row(
                                children: const [
                                  Icon(Icons.logout, size: 16),
                                  SizedBox(width: 8),
                                  Text("Log Out"),
                                ],
                              ),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(
                              _getProfileImageByRole(),
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
                            icon: Icons.people,
                            title: 'Users List',
                            onTap: () {}),
                        _dashboardPreviewTile(
                            icon: Icons.article,
                            title: 'Membership Forms',
                            onTap: () {}),
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

  /// SIDEBAR NAV ITEM
  Widget _navItem(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // TODO: handle navigation
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

  /// SIDEBAR NAV ITEM WITH DROPDOWN (for Profile)
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

  /// DROPDOWN MENU ITEM
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

  /// PREVIEW TILE WIDGET
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

  /// PROFILE IMAGE SELECTOR BASED ON ROLE
  String _getProfileImageByRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'assets/images/Member_Icon.png';
    // You can enhance this by checking from Firestore if needed
    // For now, assume Admin uses Officer_Icon.png
    return 'assets/images/Officer_Icon.png';
  }
}