// Import Firebase and Flutter UI components
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';         // Custom app theme styles
import '../widgets/logo_header.dart';     // Logo displayed at the top of the page

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Global key for form validation
  final _formKey = GlobalKey<FormState>();

  // Controller for the email text field
  final TextEditingController _emailController = TextEditingController();

  // Validates the email format using regular expressions
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Sends a password reset email using Firebase Authentication
  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        if (!mounted) return;

        // Display success message and return to login page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset link sent! Check your email.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error sending reset email')),
        );
      }
    }
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

              // Application title
              const Text("1stKLGB Hub", style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              const Text(
                "Streamlined Management & Communication Centre",
                style: AppTextStyles.subheading,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 64),
              const Text("Forgot Password", style: AppTextStyles.heading2),
              const SizedBox(height: 24),

              // Email input form
              Form(
                key: _formKey,
                child: FractionallySizedBox(
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

                      const SizedBox(height: 12),

                      // Instruction message
                      const Text(
                        "Enter your email and we’ll send you a link to reset your password.",
                        style: AppTextStyles.paragraph,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Send Reset Link button
              FractionallySizedBox(
                widthFactor: 0.6,
                child: ElevatedButton(
                  onPressed: _sendResetLink,
                  child: const Text("SEND LINK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}