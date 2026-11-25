import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Katalog lencana yang bisa dipilih sebagai pencapaian unggulan.
///
/// Dipakai bersama oleh halaman Profil dan Edit Profil agar label, ikon,
/// dan warna tetap konsisten. `isUnlocked` masih statis karena backend
/// pencapaian belum ada; yang disimpan ke database hanya `id` lencana.
const List<Map<String, dynamic>> kFeaturedBadges = [
  {
    'id': 'perfect_100',
    'title': 'Perfect 100',
    'desc': 'Akurasi 100% pada 10 sesi evaluasi isyarat berturut-turut',
    'icon': Icons.stars_rounded,
    'color': AppColors.primary,
    'bg': AppColors.pinkSoft,
    'isUnlocked': true,
    'category': 'Evaluasi',
  },
  {
    'id': 'streak_7',
    'title': '7-Day Streak',
    'desc': 'Berlatih isyarat minimal 15 menit setiap hari selama 7 hari',
    'icon': Icons.local_fire_department_rounded,
    'color': AppColors.secondary,
    'bg': AppColors.purpleSoft,
    'isUnlocked': true,
    'category': 'Konsistensi',
  },
  {
    'id': 'fast_signer',
    'title': 'Fast Signer',
    'desc': 'Kecepatan respon isyarat di bawah 1.2 detik saat kuis',
    'icon': Icons.bolt_rounded,
    'color': AppColors.tertiary,
    'bg': AppColors.orangeSoft,
    'isUnlocked': true,
    'category': 'Kecepatan',
  },
  {
    'id': 'kamus_explorer',
    'title': 'Kamus Explorer',
    'desc': 'Mempelajari dan mempraktikkan lebih dari 50 kosakata kamus',
    'icon': Icons.auto_stories_rounded,
    'color': AppColors.info,
    'bg': AppColors.infoSoft,
    'isUnlocked': true,
    'category': 'Eksplorasi',
  },
  {
    'id': 'komunitas_bintang',
    'title': 'Komunitas Bintang',
    'desc': 'Aktif berkontribusi di 20 diskusi tanya jawab komunitas',
    'icon': Icons.forum_rounded,
    'color': AppColors.success,
    'bg': AppColors.successSoft,
    'isUnlocked': false,
    'category': 'Komunitas',
  },
  {
    'id': 'master_signer',
    'title': 'Master Isyarat L3',
    'desc': 'Menyelesaikan seluruh modul kurikulum tingkat mahir',
    'icon': Icons.workspace_premium_rounded,
    'color': AppColors.secondary,
    'bg': AppColors.purpleSoft,
    'isUnlocked': false,
    'category': 'Kurikulum',
  },
];

/// Mencari entri katalog berdasarkan [id]; `null` jika tidak dikenal.
Map<String, dynamic>? featuredBadgeById(String id) {
  for (final badge in kFeaturedBadges) {
    if (badge['id'] == id) return badge;
  }
  return null;
}
