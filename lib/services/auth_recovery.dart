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

  /// Mengembalikan `true` jika halaman ini dibuka dari tautan recovery.
  ///
  /// Mendukung dua bentuk tautan Supabase:
  /// - implicit: `#access_token=...&type=recovery`
  /// - PKCE: `?code=...` dengan tipe recovery tersimpan di code verifier
  static Future<bool> detectInitialRecovery() async {
    final uri = Uri.base;
    final fragment = Uri.splitQueryString(uri.fragment);

    if (uri.queryParameters['type'] == 'recovery' ||
        fragment['type'] == 'recovery') {
      return true;
    }

    final hasCode = uri.queryParameters.containsKey('code') ||
        fragment.containsKey('code');
    if (!hasCode) return false;

    // Pada alur PKCE tipe redirect (mis. passwordRecovery / signup) ikut
    // disimpan bersama code verifier. Hanya recovery yang boleh membuka
    // halaman kata sandi baru.
    try {
      final prefs = await SharedPreferences.getInstance();
      final verifier = prefs.getString(_codeVerifierKey);
      return verifier != null && verifier.endsWith('/passwordRecovery');
    } catch (e) {
      debugPrint('[AuthRecovery] Gagal membaca code verifier: $e');
      return false;
    }
  }
}
