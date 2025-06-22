import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  String? _selectedRole;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'role': _selectedRole,
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign up failed')),
        );
      }
    }
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < 8) return 'Must be at least 8 characters';
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Must contain at least one number';
    }
    if (!RegExp(r'[!@#\$&*~%^_+=-]').hasMatch(password)) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoHeader(),
                const SizedBox(height: 24),
                const Text("1stKLGB Hub", style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                const Text("Streamlined Management & Communication Centre",
                    style: AppTextStyles.subheading,
                    textAlign: TextAlign.center),
                const SizedBox(height: 64),
                const Text("Welcome!", style: AppTextStyles.heading2),
                const SizedBox(height: 24),

                // Name
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Name", style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your name' : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your name',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Role
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Role", style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14, color: AppColors.black),
                        hint: const Text("Select your role"),
                        items: const [
                          DropdownMenuItem(
                              value: 'Girl/Parent', child: Text("Girl/Parent")),
                          DropdownMenuItem(
                              value: 'Young Leader', child: Text("Young Leader")),
                          DropdownMenuItem(
                              value: 'Officer', child: Text("Officer")),
                        ],
                        onChanged: (value) => setState(() => _selectedRole = value),
                        validator: (value) =>
                            value == null ? 'Please select a role' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your email',
                        ),
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
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Use at least 8 characters with 1 number, and one special character.",
                        style: AppTextStyles.paragraph,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Confirm Password",
                          style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Re-enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // SIGN UP Button
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: ElevatedButton(
                    onPressed: _signUp,
                    child: const Text("SIGN UP"),
                  ),
                ),
                const SizedBox(height: 24),

                // Already have an account
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Already have an account? ",
                            style: AppTextStyles.paragraph),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text(
                              "Login Here",
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}