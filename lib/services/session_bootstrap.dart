import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hasil pemeriksaan sesi saat aplikasi dibuka.
enum StatusSesi {
  /// Sesi masih berlaku (atau hanya gagal karena jaringan) — lanjut ke beranda.
  masuk,

  /// Tidak ada sesi, atau token ditolak server — tampilkan halaman login.
  keluar,
}

/// Memeriksa sesi tersimpan sebelum aplikasi menampilkan beranda.
///
/// Token akses berumur pendek; bila sudah kedaluwarsa, sesi diperbarui dengan
/// refresh token. Bila server menolak refresh token (mis. sesi dicabut),
/// sesi dibersihkan dan pengguna diminta masuk lagi. Bila gagal karena
/// jaringan, pengguna tetap dianggap masuk agar aplikasi bisa dipakai lagi
/// saat koneksi pulih.
class SessionBootstrap {
  SessionBootstrap._();

  static Future<StatusSesi> periksa({
    Duration batas = const Duration(seconds: 10),
  }) async {
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return StatusSesi.keluar;
    }

    final sesi = client.auth.currentSession;
    if (sesi == null) return StatusSesi.keluar;
    if (!sesi.isExpired) return StatusSesi.masuk;

    try {
      final hasil = await client.auth.refreshSession().timeout(batas);
      return hasil.session == null ? StatusSesi.keluar : StatusSesi.masuk;
    } catch (e) {
      // gotrue menghapus sesi sendiri saat refresh token ditolak; bila sesi
      // masih ada berarti kegagalannya sementara (mis. tidak ada internet).
      final masihAda = client.auth.currentSession != null;
      debugPrint('[Sesi] Perbarui sesi gagal: $e');
      return masihAda ? StatusSesi.masuk : StatusSesi.keluar;
    }
  }
}
