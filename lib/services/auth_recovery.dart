import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Membantu mendeteksi tautan recovery (reset kata sandi) yang membuka
/// aplikasi.
///
/// Di web, Supabase memproses parameter URL saat `Supabase.initialize()`
/// sehingga parameter tersebut sudah dibersihkan sebelum widget pertama
/// dibuat. Karena itu deteksi harus dilakukan sebelum inisialisasi.
class AuthRecovery {
  AuthRecovery._();

  /// Kunci penyimpanan code verifier PKCE milik gotrue.
  static const String _codeVerifierKey = 'supabase.auth.token-code-verifier';

  /// Pesan ramah saat tautan recovery ditolak Supabase (`?error=...`),
  /// mis. tautan kedaluwarsa atau sudah dipakai.
  static String? initialErrorMessage;

  /// Mengembalikan `true` jika halaman ini dibuka dari tautan recovery.
  ///
  /// Mendukung dua bentuk tautan Supabase:
  /// - implicit: `#access_token=...&type=recovery`
  /// - PKCE: `?code=...` dengan tipe recovery tersimpan di code verifier
  ///
  /// Bila tautan ditolak (`?error=...&error_description=...`),
  /// [initialErrorMessage] diisi agar UI bisa memberi tahu pengguna.
  static Future<bool> detectInitialRecovery() async {
    final uri = Uri.base;
    final fragment = Uri.splitQueryString(uri.fragment);

    // Tautan ditolak: Supabase mengembalikan `?error=access_denied` /
    // `?error=otp_expired` (atau di fragment) sebelum membuka aplikasi.
    final error = uri.queryParameters['error'] ?? fragment['error'];
    if (error != null && error.isNotEmpty) {
      initialErrorMessage = friendlyRecoveryError(
        error,
        uri.queryParameters['error_description'] ??
            fragment['error_description'],
      );
      return false;
    }

    if (uri.queryParameters['type'] == 'recovery' ||
        fragment['type'] == 'recovery') {
      return true;
    }

    final hasCode =
        uri.queryParameters.containsKey('code') || fragment.containsKey('code');
    if (!hasCode) return false;

    // Pada alur PKCE tipe redirect (mis. passwordRecovery / signup) ikut
    // disimpan bersama code verifier. Hanya recovery yang boleh membuka
    // halaman kata sandi baru.
    try {
      final prefs = await SharedPreferences.getInstance();
      final verifier = prefs.getString(_codeVerifierKey);
      if (verifier == null) {
        // Verifier bisa tidak ada bila tautan dibuka di perangkat/browser
        // berbeda dari tempat permintaan dikirim. Tetap buka halaman reset:
        // bila sesi recovery memang tidak valid, updateUser akan memberi
        // pesan ramah alih-alih menahan pengguna di halaman masuk.
        debugPrint(
          '[AuthRecovery] Code verifier tidak ditemukan; tetap membuka reset.',
        );
        return true;
      }
      return verifier.endsWith('/passwordRecovery');
    } catch (e) {
      debugPrint('[AuthRecovery] Gagal membaca code verifier: $e');
      return true;
    }
  }

  /// Mengubah kode error Supabase menjadi pesan yang bisa dimengerti.
  static String friendlyRecoveryError(String error, String? description) {
    final d = (description ?? '').toLowerCase();
    if (error == 'otp_expired' || d.contains('expired')) {
      return 'Tautan reset sudah kedaluwarsa. Silakan minta tautan baru.';
    }
    if (error == 'access_denied' || d.contains('invalid')) {
      return 'Tautan reset tidak valid atau sudah pernah dipakai. Silakan minta tautan baru.';
    }
    return 'Tautan reset tidak dapat diproses. Silakan minta tautan baru.';
  }
}
