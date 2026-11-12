import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service layer untuk autentikasi menggunakan Supabase Auth.
class AuthService {
  final SupabaseClient? _customClient;

  /// Tautan kembali ke aplikasi setelah pengguna mengeklik email reset.
  /// Harus terdaftar di Supabase > Authentication > URL Configuration.
  static const String resetRedirect = 'signl://reset';

  AuthService({SupabaseClient? client}) : _customClient = client;

  /// Mengubah pesan bawaan Supabase (Inggris) menjadi pesan yang ramah.
  static String friendlyMessage(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau username atau kata sandi salah.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Buka tautan verifikasi di inbox kamu.';
    }
    if (m.contains('user not found')) {
      return 'Akun tidak ditemukan.';
    }
    if (m.contains('too many requests') || m.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    if (m.contains('password should be at least')) {
      return 'Kata sandi terlalu pendek.';
    }
    if (m.contains('failed host lookup') ||
        m.contains('socketexception') ||
        m.contains('connection')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.';
    }
    return raw;
  }

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

  /// Masuk dengan email & password. Nilai tanpa `@` dianggap username dan
  /// diubah menjadi email lewat fungsi RPC `get_email_by_username`.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final client = _safeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }

    final identifier = email.trim();
    final loginEmail = identifier.contains('@')
        ? identifier
        : await _resolveEmailFromUsername(client, identifier);

    AuthResponse response;
    try {
      response = await client.auth.signInWithPassword(
        email: loginEmail,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(friendlyMessage(e.message));
    } catch (e) {
      throw Exception(friendlyMessage(e.toString()));
    }

    if (response.session == null) {
      throw Exception('Login gagal: sesi tidak terbentuk.');
    }
    return response;
  }

  /// Mengambil role akun dari tabel `profiles` (`user` atau `admin`).
  /// Bila tabel/policy belum siap, dianggap pengguna biasa.
  Future<String> fetchRole() async {
    final client = _safeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return 'user';
    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = row?['role'];
      return role is String && role.isNotEmpty ? role : 'user';
    } catch (e) {
      debugPrint('[Auth] Gagal membaca role: $e');
      return 'user';
    }
  }

  /// Mencari email terdaftar dari username (disimpan di metadata saat daftar).
  Future<String> _resolveEmailFromUsername(
    SupabaseClient client,
    String username,
  ) async {
    Object? result;
    try {
      result = await client.rpc(
        'get_email_by_username',
        params: {'uname': username},
      );
    } on PostgrestException catch (e) {
      debugPrint('[Auth] RPC get_email_by_username gagal: ${e.message}');
      throw Exception(
        'Login memakai username belum tersedia di server. Silakan masuk memakai email.',
      );
    } catch (e) {
      debugPrint('[Auth] RPC get_email_by_username gagal: $e');
      throw Exception(
        'Tidak dapat memeriksa username. Periksa koneksi lalu coba lagi.',
      );
    }

    final email = result is String ? result.trim() : '';
    if (email.isEmpty) {
      throw Exception(
        'Username tidak ditemukan. Periksa kembali atau masuk memakai email.',
      );
    }
    return email;
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
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }

    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        // Web: kembali ke origin aplikasi. Android/iOS: kembali lewat deep
        // link yang terdaftar di Supabase Redirect URLs.
        redirectTo: kIsWeb ? Uri.base.origin : resetRedirect,
      );
    } on AuthException catch (e) {
      throw Exception(friendlyMessage(e.message));
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
