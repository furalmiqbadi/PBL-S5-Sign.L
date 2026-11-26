import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTheme {
  static const Color primaryBlue = Color(0xFF2D62ED);
  static const Color secondaryBlue = Color(0xFFE8EFFF);
  static const Color bgGray = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF1A1D1E);
  static const Color textGray = Color(0xFF6A6A6A);

  static ThemeData get light {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: bgGray,
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textGray, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
}
