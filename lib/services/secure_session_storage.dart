import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Menyimpan sesi Supabase di penyimpanan terenkripsi perangkat
/// (Android Keystore / iOS Keychain) agar token tidak tersimpan sebagai
/// teks biasa seperti `SharedPreferences`.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    FlutterSecureStorage? storage,
    this.key = defaultKey,
    this.legacyKey,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const String defaultKey = 'signl.auth.session';

  final FlutterSecureStorage _storage;

  /// Kunci penyimpanan sesi.
  final String key;

  /// Kunci `SharedPreferences` versi lama, dipindahkan sekali agar pengguna
  /// yang sudah masuk tidak perlu login ulang setelah pembaruan aplikasi.
  final String? legacyKey;

  @override
  Future<void> initialize() async {
    final legacy = legacyKey;
    if (legacy == null || await accessToken() != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesiLama = prefs.getString(legacy);
      if (sesiLama == null) return;
      await persistSession(sesiLama);
      await prefs.remove(legacy);
    } catch (e) {
      debugPrint('[Sesi] Gagal memindahkan sesi lama: $e');
    }
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Data tidak terbaca setelah restore backup atau keystore direset:
      // anggap belum masuk agar pengguna diarahkan ke halaman login.
      debugPrint('[Sesi] Sesi tersimpan tidak bisa dibaca: $e');
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: key, value: persistSessionString);
    } catch (e) {
      debugPrint('[Sesi] Gagal menyimpan sesi: $e');
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[Sesi] Gagal menghapus sesi: $e');
    }
  }
}
