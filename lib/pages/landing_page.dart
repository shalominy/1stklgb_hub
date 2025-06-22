import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_header.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/Landing_Page.JPG',
            fit: BoxFit.cover,
          ),

          // White translucent overlay
          Container(
            color: AppColors.white.withOpacity(0.8),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoHeader(),

                const SizedBox(height: 24),

                const Text(
                  "1stKLGB Hub",
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  "Streamlined Management & Communication Centre",
                  style: AppTextStyles.subheading,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 64),

                const Text(
                  "Welcome",
                  style: AppTextStyles.heading2,
                ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text("Get Started"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}