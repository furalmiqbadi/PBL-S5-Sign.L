import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi Sign.L menggunakan font **Plus Jakarta Sans**, sesuai
/// `docs/prd/design.md`.
///
/// Skala dibagi menjadi tiga kelompok seperti pada style guide Figma:
/// Headline, Body, dan Label.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double height = 1.35,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // --- Headline ---
  static TextStyle get headlineLarge => _base(
        size: 28,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );
  static TextStyle get headlineMedium => _base(
        size: 24,
        weight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.35,
      );
  static TextStyle get headlineSmall => _base(
        size: 20,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
      );

  // --- Title ---
  static TextStyle get titleLarge => _base(
        size: 18,
        weight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.15,
      );
  static TextStyle get titleMedium => _base(
        size: 16,
        weight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
      );
  static TextStyle get titleSmall =>
      _base(size: 14, weight: FontWeight.w600, height: 1.35);

  // --- Body ---
  static TextStyle get bodyLarge =>
      _base(size: 16, weight: FontWeight.w400, height: 1.45);
  static TextStyle get bodyMedium =>
      _base(size: 14, weight: FontWeight.w400, height: 1.45);
  static TextStyle get bodySmall => _base(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // --- Label ---
  static TextStyle get labelLarge => _base(
        size: 14,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      );
  static TextStyle get labelMedium => _base(
        size: 12,
        weight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0.1,
      );
  static TextStyle get labelSmall => _base(
        size: 11,
        weight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0.1,
        color: AppColors.textMuted,
      );

  /// Label sangat kecil untuk metadata rapat (badge, caption kartu, dsb.).
  static TextStyle get labelXSmall =>
      _base(size: 10, weight: FontWeight.w600, height: 1.2);

  // --- Varian warna siap pakai ---
  static TextStyle muted(TextStyle style) =>
      style.copyWith(color: AppColors.textSecondary);
  static TextStyle onPrimary(TextStyle style) =>
      style.copyWith(color: AppColors.textOnPrimary);
}
