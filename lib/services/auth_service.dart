import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service layer untuk autentikasi menggunakan Supabase Auth.
class AuthService {
  final SupabaseClient? _customClient;

  AuthService({SupabaseClient? client}) : _customClient = client;

  /// Mengambil klien Supabase secara aman (menghindari exception jika belum diinisialisasi, misal saat test).
  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// User yang sedang login saat ini di sesi Supabase.
  User? get currentUser => _safeClient?.auth.currentUser;

  /// Status apakah ada sesi aktif.
  bool get isAuthenticated => currentUser != null;

  /// Stream perubahan status autentikasi (login/logout/token refresh).
  Stream<AuthState>? get authStateChanges => _safeClient?.auth.onAuthStateChange;

  /// Masuk dengan email & password.
  Future<AuthResponse?> login({
    required String email,
    required String password,
  }) async {
    final client = _safeClient;
    if (client == null) {
      // Fallback mock jika Supabase belum terinisialisasi
      debugPrint('[AuthService] Supabase belum terinisialisasi. Menjalankan fallback lokal.');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return null;
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal masuk: $e');
    }
  }

  /// Mendaftar akun baru dengan email, password, nama, dan username.
  Future<AuthResponse?> register({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    final client = _safeClient;
    if (client == null) {
      debugPrint('[AuthService] Supabase belum terinisialisasi. Menjalankan fallback lokal.');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return null;
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (name != null && name.trim().isNotEmpty) 'full_name': name.trim(),
          if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
        },
      );
      return response;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  /// Kirim link reset kata sandi ke email.
  Future<void> sendResetLink(String email) async {
    final client = _safeClient;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mengirim tautan reset: $e');
    }
  }

  /// Perbarui kata sandi baru.
  Future<void> resetPassword({
    required String password,
    required String confirmation,
  }) async {
    if (password != confirmation) {
      throw Exception('Konfirmasi kata sandi tidak cocok.');
    }

    final client = _safeClient;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      await client.auth.updateUser(
        UserAttributes(password: password),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal memperbarui kata sandi: $e');
    }
  }

  /// Keluar dari sesi akun saat ini.
  Future<void> logout() async {
    final client = _safeClient;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }

    try {
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal keluar: $e');
    }
  }
}
