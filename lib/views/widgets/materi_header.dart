import 'package:flutter/material.dart';

import 'section_header.dart';
import 'stat_pill.dart';

/// Header halaman Materi: judul besar di kiri, tiga pill statistik di kanan
/// (streak, heart, diamond).
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

  const MateriHeader({
    super.key,
    this.title = 'Materi',
    this.streak = 7,
    this.hearts = 420,
    this.diamonds = 420,
  });

  // Warna aksen tiap statistik.
  static const Color streakAccent = Color(0xFFF97316); // oranye
  static const Color heartAccent = Color(0xFFE53950); // merah
  static const Color diamondAccent = Color(0xFF7C3AED); // ungu

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
        const SizedBox(width: 8),
        StatPill(
          svgAsset: 'assets/images/heart_fix.svg',
          value: '$hearts',
          accent: heartAccent,
          semanticLabel: '$hearts nyawa',
        ),
        const SizedBox(width: 8),
        StatPill(
          svgAsset: 'assets/images/diamond_fix.svg',
          value: '$diamonds',
          accent: diamondAccent,
          semanticLabel: '$diamonds diamond',
        ),
      ],
    );
  }
}
