import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/admin_dashboard_page.dart';
import 'pages/announcement_editor_page.dart';
import 'pages/announcement_list_page.dart';
import 'pages/announcement_page.dart';
import 'pages/annual_calendar_editor_page.dart';
import 'pages/annual_calendar_overview_page.dart';
import 'pages/annual_calendar_page.dart';
import 'pages/award_list_page.dart';
import 'pages/award_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/full_attendance_list_page.dart';
import 'pages/girl_parent_dashboard_page.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/membership_form_page.dart';
import 'pages/officer_dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/promotion_list_page.dart';
import 'pages/promotion_page.dart';
import 'pages/recruit_attendance_page.dart';
import 'pages/sectional_attendance_page.dart';
import 'pages/sectional_planning_form_page.dart';
import 'pages/sectional_planning_list_page.dart';
import 'pages/signup_page.dart';
import 'pages/squad_assignment_page.dart';
import 'pages/squad_attendance_list_page.dart';
import 'pages/squad_attendance_page.dart';
import 'pages/squad_leader_assignment_page.dart';
import 'pages/squad_leader_dashboard_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAS4AGzlFq2MIOIXs8PXrcmZFJJqqCH96s",
      authDomain: "firstklgb-hub.firebaseapp.com",
      projectId: "firstklgb-hub",
      storageBucket: "firstklgb-hub.firebasestorage.app",
      messagingSenderId: "203576587844",
      appId: "1:203576587844:web:8b01627970249e4e736e11",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1stKLGB Hub',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/officer_dashboard': (context) => const OfficerDashboardPage(),
        '/squad_leader_dashboard': (context) => const SquadLeaderDashboardPage(),
        '/girl_parent_dashboard': (context) => const GirlParentDashboardPage(),
        '/membership_form': (context) => const MembershipFormPage(),
        '/sectional_attendance': (context) => const SectionalAttendancePage(),
        '/award': (context) => const AwardPage(),
        '/full_attendance_list': (_) => const FullAttendanceListPage(),
        '/squad_attendance': (context) => const SquadAttendancePage(),
        '/squad_attendance_list': (context) => const SquadAttendanceListPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/squad_assignment': (context) => const SquadAssignmentPage(),
        '/recruit_attendance': (context) => const RecruitAttendancePage(),
        '/squad_leader_assignment': (context) => const SquadLeaderAssignmentPage(),
        '/announcement_editor': (context) => const AnnouncementEditorPage(),
        '/announcement_list': (context) => const AnnouncementListPage(),
        '/annual_calendar_overview': (context) => const AnnualCalendarOverviewPage(),
        '/annual_calendar_editor': (context) => const AnnualCalendarEditorPage(),
        '/sectional_planning_form': (context) => const SectionalPlanningFormPage(),
        '/sectional_planning_list': (context) => const SectionalPlanningListPage(),
        '/award_list': (context) => const AwardListPage(),
        '/promotion': (context) => const PromotionPage(),
        '/promotion_list': (context) => const PromotionListPage(),
        '/announcement': (context) => const AnnouncementPage(),
        '/annual_calendar': (context) => const AnnualCalendarPage(),
      },
    );
  }
}