import 'package:flutter/material.dart';

/// Palet warna resmi Sign.L berdasarkan design system Figma.
///
/// Warna inti (Primary, Secondary, Tertiary, Neutral) diambil langsung dari
/// halaman style guide, sedangkan warna turunannya (background, card, dsb.)
/// diturunkan agar konsisten dengan tampilan beranda.
class AppColors {
  AppColors._();

  // --- Warna inti brand (diselaraskan dengan AppBottomNavBar teman) ---
  static const Color primary = Color(0xFFC2185B); // Pink aktif navbar
  static const Color secondary = Color(0xFF7C3AED); // Ungu (diamond)
  static const Color tertiary = Color(0xFFF97316); // Oranye (streak)
  static const Color neutral = Color(0xFF3B2231); // Cokelat gelap (ikon nonaktif)

  // --- Permukaan & latar ---
  static const Color background = Color(0xFFFBF7F0); // Cream hangat
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4EEE4);
  static const Color border = Color(0xFFEDE4D6);

  // --- Aksen lembut ---
  static const Color pinkSoft = Color(0xFFFCE4EE); // Bubble / kartu pink muda
  static const Color pinkSofter = Color(0xFFFBEFF5);
  static const Color purpleSoft = Color(0xFFF1E6F7);
  static const Color orangeSoft = Color(0xFFFDEBD9);

  // --- Aksen tambahan (kamera AI & status) ---
  static const Color info = Color(0xFF0284C7); // Biru (panduan kamera AI)
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color successSoft = Color(0xFFD1FAE5);

  // --- Teks ---
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF6E6A66);
  static const Color textMuted = Color(0xFF9E9891);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Status ---
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFE53950); // Merah (heart)

  /// Gradasi khas Sign.L (oranye → pink) — sama dengan tombol tengah navbar.
  static const Color brandGradientStart = Color(0xFFF57C00);
  static const Color brandGradientEnd = Color(0xFFD81B60);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandGradientStart, brandGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
