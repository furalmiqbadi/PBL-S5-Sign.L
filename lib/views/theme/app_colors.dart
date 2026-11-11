import 'package:flutter/material.dart';

/// Palet warna resmi Sign.L, diambil dari logo aplikasi:
/// biru (tangan kiri dan buku), toska (tangan kanan), kuning (balon bicara).
///
/// Catatan nama: `pinkSoft`/`pinkSofter`/`purpleSoft` dipertahankan agar kode
/// lama tidak berubah, tetapi nilainya kini biru muda, toska muda, dan seterusnya.
class AppColors {
  AppColors._();

  // --- Warna inti brand ---
  static const Color primary = Color(0xFF0062EE); // Biru logo; kontras putih 5.3:1
  static const Color secondary = Color(0xFF0BB59E); // Toska (diamond, aksen kedua)
  static const Color tertiary = Color(0xFFF59E0B); // Kuning-amber (streak)
  static const Color neutral = Color(0xFF334155); // Slate (ikon nonaktif)

  // --- Permukaan & latar ---
  static const Color background = Color(0xFFFFFFFF); // Putih (Soft UI)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color fieldFill = Color(0xFFF3F6FB); // Isi kolom input di atas latar putih
  static const Color surfaceMuted = Color(0xFFF1F4F9);
  static const Color border = Color(0xFFE5EAF2);

  // --- Aksen lembut ---
  static const Color pinkSoft = Color(0xFFE6F0FF); // Biru muda (bubble / chip aktif)
  static const Color pinkSofter = Color(0xFFF3F8FF); // Biru sangat muda (kartu)
  static const Color purpleSoft = Color(0xFFDDF6F1); // Toska muda
  static const Color orangeSoft = Color(0xFFFFF1D6); // Kuning muda

  // --- Aksen tambahan (kamera AI & status) ---
  static const Color info = Color(0xFF0284C7); // Biru (panduan kamera AI)
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color successSoft = Color(0xFFD1FAE5);

  // --- Teks ---
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF5B6676);
  static const Color textMuted = Color(0xFF8A94A3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Status ---
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFE53950); // Merah (heart)

  /// Gradasi khas Sign.L (biru → toska, seperti logo) — dipakai tombol tengah navbar.
  static const Color brandGradientStart = Color(0xFF0062EE);
  static const Color brandGradientEnd = Color(0xFF0BB59E);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandGradientStart, brandGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
