import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'section_header.dart';
import 'stat_pill.dart';

/// Header halaman Materi: judul di kiri, empat pill statistik di kanan
/// (streak, heart, diamond, EXP).
///
/// Dipakai sebagai bilah atas halaman Materi. Tinggi dan gayanya sengaja
/// ringkas agar konten materi tetap jadi fokus.
class MateriHeader extends StatelessWidget {
  /// Judul halaman.
  final String title;

  /// Jumlah hari berturut-turut belajar.
  final int streak;

  /// Jumlah nyawa (heart) yang tersisa.
  final int hearts;

  /// Jumlah diamond (gems) yang dimiliki.
  final int diamonds;

  /// Jumlah poin pengalaman (EXP) yang dimiliki.
  final int exp;

  const MateriHeader({
    super.key,
    this.title = 'Materi',
    this.streak = 7,
    this.hearts = 420,
    this.diamonds = 420,
    this.exp = 350,
  });

  // Warna aksen tiap statistik.
  static const Color streakAccent = AppColors.tertiary; // oranye
  static const Color heartAccent = AppColors.danger; // merah
  static const Color diamondAccent = AppColors.secondary; // toska
  static const Color expAccent = AppColors.primary; // biru

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: title,
      actions: [
        StatPill(
          svgAsset: 'assets/images/streak_fix.svg',
          value: '$streak',
          accent: streakAccent,
          semanticLabel: 'Streak $streak hari',
        ),
        const SizedBox(width: 6),
        StatPill(
          svgAsset: 'assets/images/heart_fix.svg',
          value: '$hearts',
          accent: heartAccent,
          semanticLabel: '$hearts nyawa',
        ),
        const SizedBox(width: 6),
        StatPill(
          svgAsset: 'assets/images/diamond_fix.svg',
          value: '$diamonds',
          accent: diamondAccent,
          semanticLabel: '$diamonds diamond',
        ),
        const SizedBox(width: 6),
        StatPill(
          icon: Icons.bolt_rounded,
          value: '$exp',
          accent: expAccent,
          semanticLabel: '$exp EXP',
        ),
      ],
    );
  }
}
