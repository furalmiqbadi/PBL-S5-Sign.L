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
    if (m.contains('auth session missing') ||
        m.contains('session not found') ||
        m.contains('refresh_token_not_found') ||
        m.contains('refresh token not found') ||
        m.contains('invalid refresh token') ||
        m.contains('jwt expired') ||
        m.contains('user signed out') ||
        m.contains('session expired')) {
      return 'Sesi akun tidak tersedia. Silakan masuk lagi.';
    }
    if (m.contains('too many requests') || m.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    if (m.contains('password should be at least')) {
      return 'Kata sandi terlalu pendek.';
    }
    if (m.contains('database error saving new user')) {
      return 'Pendaftaran gagal karena profil akun tidak dapat dibuat. Kemungkinan username sudah dipakai — coba username lain.';
    }
    if (m.contains('user already registered') ||
        m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Coba masuk atau gunakan email lain.';
    }
    if (m.contains('signups not allowed') || m.contains('signup is disabled')) {
      return 'Pendaftaran akun sedang dinonaktifkan. Coba lagi nanti.';
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return 'Format email tidak valid.';
    }
    if (m.contains('weak password') || m.contains('password is too weak')) {
      return 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.';
    }
    if (m.contains('duplicate key') || m.contains('unique constraint')) {
      return 'Username sudah dipakai. Pilih username lain.';
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

  Session? get currentSession => _safeClient?.auth.currentSession;

  Future<AuthResponse> setSession(String session) async {
    final client = _safeClient;
    if (client == null) throw Exception('Autentikasi belum tersedia.');
    try {
      return await client.auth.setSession(session);
    } on AuthException catch (e) {
      throw Exception(friendlyMessage(e.message));
    } catch (e) {
      throw Exception(friendlyMessage(e.toString()));
    }
  }

  /// Status apakah ada sesi aktif.
  bool get isAuthenticated => currentUser != null;

  /// Stream perubahan status autentikasi (login/logout/token refresh).
  Stream<AuthState>? get authStateChanges =>
      _safeClient?.auth.onAuthStateChange;

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
    // Role bisa berubah sejak sesi terakhir; baca ulang setelah masuk.
    _roleCache = null;
    _roleCacheUserId = null;
    _roleInFlight = null;
    return response;
  }

  /// Role yang sudah dibaca, dipakai ulang agar startup tidak menembak
  /// `profiles` dua kali (AuthController & layar awal).
  static String? _roleCache;
  static String? _roleCacheUserId;
  static Future<String>? _roleInFlight;

  /// Mengambil role akun dari tabel `profiles` (`user` atau `admin`).
  /// Bila tabel/policy belum siap, dianggap pengguna biasa.
  Future<String> fetchRole({bool force = false}) async {
    final client = _safeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return 'user';
    if (!force && _roleCache != null && _roleCacheUserId == user.id) {
      return _roleCache!;
    }
    if (!force && _roleInFlight != null) return _roleInFlight!;

    final future = _bacaRole(client, user.id).whenComplete(
      () => _roleInFlight = null,
    );
    _roleInFlight = future;
    return future;
  }

  Future<String> _bacaRole(SupabaseClient client, String userId) async {
    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final role = row?['role'];
      final hasil = role is String && role.isNotEmpty ? role : 'user';
      _roleCache = hasil;
      _roleCacheUserId = userId;
      return hasil;
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

    final trimmedName = name?.trim();
    final trimmedUsername = username?.trim();
    final hasUsername = trimmedUsername != null && trimmedUsername.isNotEmpty;

    // Trigger `handle_new_user` biasanya menulis profiles.full_name (NOT NULL).
    // Tanpa name/full_name pendaftaran gagal "Database error saving new user",
    // jadi selalu isi dengan fallback username atau prefix email.
    final namaFinal = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName
        : (hasUsername ? trimmedUsername : email.trim().split('@').first);
    final data = <String, dynamic>{
      'name': namaFinal,
      'full_name': namaFinal,
    };
    if (hasUsername) {
      data['username'] = trimmedUsername;
    }

    AuthResponse response;
    try {
      response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: data,
      );
    } on AuthException catch (e) {
      throw Exception(friendlyMessage(e.message));
    } catch (e) {
      throw Exception(friendlyMessage(e.toString()));
    }

    if (response.user == null) {
      throw Exception('Pendaftaran gagal. Coba lagi.');
    }
    return response;
  }

  /// URL kembali ke aplikasi web saat ini, termasuk base path-nya
  /// (mis. `https://furalmiqbadi.my.id/pbl/signl/`). Jangan memakai
  /// `Uri.base.origin` karena membuang path sehingga tautan reset mendarat
  /// di halaman utama situs, bukan di aplikasi.
  String get webRedirectUrl {
    final base = Uri.base;
    final path = base.path.isEmpty ? '/' : base.path;
    return '${base.origin}${path.endsWith('/') ? path : '$path/'}';
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
        // Web: kembali ke path aplikasi (bukan origin saja). Android/iOS:
        // kembali lewat deep link yang terdaftar di Supabase Redirect URLs.
        redirectTo: kIsWeb ? webRedirectUrl : resetRedirect,
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
      throw Exception(friendlyMessage(e.message));
    } catch (e) {
      throw Exception(friendlyMessage(e.toString()));
    }
  }

  /// Keluar dari sesi akun saat ini.
  Future<void> logout() async {
    _roleCache = null;
    _roleCacheUserId = null;
    _roleInFlight = null;
    final client = _safeClient;
    if (client == null) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }

    try {
      await client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(friendlyMessage(e.message));
    } catch (e) {
      throw Exception(friendlyMessage(e.toString()));
    }
  }
}
