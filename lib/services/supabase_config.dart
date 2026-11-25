import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase untuk aplikasi Sign.L.
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hektdovlqcvtcdywxuqx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_rCzCONkdToqR0_FUMNp-3w_927kQxya',
  );

  /// Menandakan apakah konfigurasi URL dan Key sudah valid.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      supabaseAnonKey.isNotEmpty;

  /// Mengecek apakah klien Supabase telah berhasil diinisialisasi di runtime.
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}
