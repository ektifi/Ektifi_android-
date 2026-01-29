import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color successGreen = Color(0xFF34D399);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color backgroundGray = Color(0xFFF9FAFB);

  // Gradient for CTA buttons
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryIndigo, accentCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Get font family based on locale and platform
  static String _getFontFamily(String? locale) {
    if (locale == 'ar') {
      // Arabic: Use DIN Next LT Arabic
      return 'DIN Next LT Arabic';
    } else {
      // English: Use platform-specific fonts
      if (Platform.isIOS) {
        // iOS: SF Pro Display
        return '.SF Pro Display';
      } else {
        // Android: Roboto (default Material font)
        return 'Roboto';
      }
    }
  }

  static ThemeData getLightTheme({String? locale}) {
    final fontFamily = _getFontFamily(locale);
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIndigo,
        secondary: accentCyan,
        error: errorRed,
        surface: Colors.white,
        background: backgroundGray,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundGray,
      appBarTheme: const AppBarTheme(
        //backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      textTheme: TextTheme(
        // Display styles - use semi-bold (600) for large text
        displayLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        displayMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        // Headline styles - use semi-bold (600)
        headlineLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        // Title styles - use medium (500) for titles
        titleLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
        // Body styles - use regular (400) for body text
        bodyLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.normal),
        // Label styles - use medium (500) for labels
        labelLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Legacy method for backward compatibility
  static ThemeData get lightTheme {
    return getLightTheme(locale: 'en');
  }
}

