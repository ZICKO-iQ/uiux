import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF479442); 
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFFC8E6C9);
  static const Color navigationBarBackground = Colors.white;

  // Accent Colors
  static const Color accent = Color(0xFFFFC107); // Amber

  // Background Colors
  static const Color bg = Color(0xFFcae9d9);
  static const Color bgWhite = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFFffffff);
  static const Color textSecondary = Colors.black; 
  static const Color hypertext = Colors.blue; 

  // Status Colors
  static const Color warning = Color(0xFFFFA726); // Orange
  static const Color failed = Color(0xFFD32F2F); // Red

  // Error Color
  static const Color error = failed; // Use failed color for consistency

  // Buttons Colors
  static const Color notActiveBtn = Color(0xFF757575);
  static const Color activeBtn = Color(0xFF479442);
}
