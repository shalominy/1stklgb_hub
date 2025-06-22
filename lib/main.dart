import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
// import 'pages/forgot_password_page.dart'; // Optional
// import 'pages/dashboard_page.dart'; // Optional
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAS4AGzlFq2MIOIXs8PXrcmZFJJqqCH96s",
      authDomain: "firstklgb-hub.firebaseapp.com",
      projectId: "firstklgb-hub",
      storageBucket: "firstklgb-hub.appspot.com",
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
        // '/forgot_password': (context) => const ForgotPasswordPage(),
        // '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}