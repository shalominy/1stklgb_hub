import 'package:flutter/material.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkBlue = Color(0xFF201e76);
  static const Color blue = Color(0xFF4348b2);
  static const Color sidebarBackground = AppColors.darkBlue; // Optional alias
  static const Color iconWhite = AppColors.white;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  );

  static const TextStyle titleWhite = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static const TextStyle paragraph = TextStyle(
    fontSize: 12,
    color: AppColors.black,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.darkBlue,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBlue,
      foregroundColor: AppColors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.darkBlue,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.heading1,
      titleLarge: AppTextStyles.heading2,
      titleMedium: AppTextStyles.subheading,
      bodyMedium: AppTextStyles.paragraph,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.white,
        textStyle: AppTextStyles.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      ),
    ),
  );
}