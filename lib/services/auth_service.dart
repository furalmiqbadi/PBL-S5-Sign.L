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
  Future<AuthResponse> login({
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
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }

    AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal masuk: $e');
    }
  }

  /// Mendaftar akun baru dengan email, password, nama, dan username.
  Future<AuthResponse?> register({

    if (response.session == null) {
      throw Exception('Login gagal: sesi tidak terbentuk.');
    }
    return response;
  }

  /// Mendaftar akun baru dengan email, password, nama, dan username.
  Future<AuthResponse> register({
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
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }

    final data = <String, dynamic>{};
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      // Kirim keduanya agar kompatibel dengan trigger lama (name) dan baru (full_name).
      data['name'] = trimmedName;
      data['full_name'] = trimmedName;
    }
    final trimmedUsername = username?.trim();
    if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
      data['username'] = trimmedUsername;
    }

    AuthResponse response;
    try {
      response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: data.isEmpty ? null : data,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }

    if (response.user == null) {
      throw Exception('Pendaftaran gagal. Coba lagi.');
    }
    return response;
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
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }

    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        // Di web, arahkan tautan kembali ke aplikasi ini agar sesi recovery
        // bisa diproses. URL ini harus terdaftar di Redirect URLs Supabase.
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
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
    if (password.isEmpty || confirmation.isEmpty) {
      throw Exception('Kata sandi baru dan konfirmasi wajib diisi.');
    }
    if (password.length < 8) {
      throw Exception('Kata sandi baru minimal 8 karakter.');
    }
    if (password != confirmation) {
      throw Exception('Konfirmasi kata sandi tidak cocok.');
    }

    final client = _safeClient;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
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
