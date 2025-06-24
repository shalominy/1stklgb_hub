import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoHeader(),
              const SizedBox(height: 24),
              const Text("1stKLGB Hub", style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              const Text(
                "Streamlined Management & Communication Centre",
                style: AppTextStyles.subheading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              const Text("Welcome back!", style: AppTextStyles.heading2),
              const SizedBox(height: 24),

              /// FORM START
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Email", style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your email',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              } else if (!isValidEmail(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Password", style: AppTextStyles.heading3),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              /// FORM END

              const SizedBox(height: 12),

              // Sign Up
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Row(
                  children: [
                    const Text("Don't have an account? ",
                        style: AppTextStyles.paragraph),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Log In Button
              FractionallySizedBox(
                widthFactor: 0.6,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;

                        final userCredential = await FirebaseAuth.instance
                            .signInWithEmailAndPassword(
                                email: email, password: password);

                        final uid = userCredential.user?.uid;
                        if (uid == null) {
                          throw FirebaseAuthException(
                              code: 'no-uid', message: 'User ID not found');
                        }

                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get();
                        final userData = userDoc.data();

                        if (!mounted) return;

                        if (userData != null) {
                          final role = userData['role'];
                          final hasSubmittedForm =
                              userData['membershipFormSubmitted'] == true;

                          if (!hasSubmittedForm) {
                            Navigator.pushReplacementNamed(
                                context, '/membership_form');
                            return;
                          }

                          if (role == 'Admin') {
                            Navigator.pushReplacementNamed(
                                context, '/admin_dashboard');
                          } else if (role == 'Officer') {
                            Navigator.pushReplacementNamed(
                                context, '/officer_dashboard');
                          } else if (role == 'Squad Leader') {
                            Navigator.pushReplacementNamed(
                                context, '/squad_leader_dashboard');
                          } else {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User data not found.')),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        if (!mounted) return;
                        String message;
                        if (e.code == 'user-not-found') {
                          message = 'No user found for that email.';
                        } else if (e.code == 'wrong-password') {
                          message = 'Incorrect password.';
                        } else {
                          message = 'Login failed. Please try again.';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    }
                  },
                  child: const Text("LOG IN"),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot Password
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Forgot password? ",
                        style: AppTextStyles.paragraph),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/forgot_password');
                        },
                        child: const Text(
                          "Reset Here",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}