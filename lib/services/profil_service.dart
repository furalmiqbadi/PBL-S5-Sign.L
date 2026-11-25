import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profil_model.dart';

/// Service data profil pengguna dan papan peringkat, dibaca dari tabel
/// `profiles` di Supabase.
///
/// Profil milik pengguna yang sedang masuk di-cache di memori supaya header
/// Beranda, Materi, dan halaman Profil tidak memanggil server berulang kali.
class ProfilService {
  final SupabaseClient? _customClient;

  ProfilService({SupabaseClient? client}) : _customClient = client;

  static ProfilPengguna? _cache;
  static Future<ProfilPengguna?>? _inFlight;

  /// Cache papan peringkat (diambil sekali, dipakai ulang sampai [force]).
  static List<ProfilPengguna>? _cachePapan;
  static int _cachePapanBatas = 0;

  /// Menghapus cache profil. Dipanggil saat keluar akun agar pengguna
  /// berikutnya tidak melihat sisa data pemilik sesi sebelumnya.
  static void hapusCache() {
    _cache = null;
    _inFlight = null;
    _cachePapan = null;
    _cachePapanBatas = 0;
  }

  /// Kolom wajib yang sudah ada sejak awal.
  static const String _kolomDasar =
      'id, full_name, username, role, avatar_url, xp, points, streak, created_at';

  /// Kolom tambahan hasil patch backend (`supabase/patch_signl_backend.sql`).
  static const String _kolomLengkap =
      '$_kolomDasar, bio, phone, level, motivation, featured_badges';

  static const String bucketAvatar = 'avatars';

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => _safeClient?.auth.currentUser?.id;

  /// Profil pengguna yang sedang masuk, atau `null` bila belum ada sesi.
  Future<ProfilPengguna?> profilSaya({bool force = false}) async {
    final client = _safeClient;
    if (client == null) return null;
    if (_customClient != null) return _queryProfil(client);
    if (force) {
      _cache = null;
      _inFlight = null;
    }
    if (_cache != null) return _cache;
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _queryProfil(client).then((value) {
      _cache = value;
      return value;
    }).whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  /// Seluruh pengguna diurutkan dari poin terbanyak untuk papan peringkat.
  /// Hasil disimpan di cache; kirim [force] `true` untuk memuat ulang
  /// (mis. saat tarik-untuk-menyegarkan).
  Future<List<ProfilPengguna>> fetchLeaderboard({
    int batas = 50,
    bool force = false,
  }) async {
    final client = _safeClient;
    if (client == null) return const [];
    final cached = _cachePapan;
    if (!force && cached != null && _cachePapanBatas == batas) return cached;
    try {
      final rows = await _selectProfil(
        client,
        urutPoin: true,
        batas: batas,
        tanpaAdmin: true,
      );
      final hasil = rows.map(ProfilPengguna.fromRow).toList();
      if (_customClient == null) {
        _cachePapan = hasil;
        _cachePapanBatas = batas;
      }
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Profil] Gagal membaca leaderboard: ${e.message}');
      throw Exception('Gagal memuat papan peringkat. Coba lagi.');
    } catch (e) {
      debugPrint('[Profil] Gagal membaca leaderboard: $e');
      throw Exception(
        'Tidak dapat memuat papan peringkat. Periksa koneksi internet.',
      );
    }
  }

  /// Menyimpan perubahan Edit Profil ke tabel `profiles`.
  ///
  /// Kolom tambahan (bio, phone, level, motivation, featured_badges) hanya
  /// dikirim bila patch backend sudah dijalankan; bila belum, perubahan pada
  /// nama/username/avatar tetap tersimpan.
  Future<ProfilPengguna?> simpanProfil({
    required String nama,
    required String username,
    required String bio,
    required String phone,
    required int level,
    required List<String> motivation,
    required List<String> featuredBadges,
    String? avatarUrl,
  }) async {
    final client = _requireClient();
    final userId = _userId;
    if (userId == null) {
      throw Exception('Sesi berakhir. Silakan masuk lagi.');
    }

    final dasar = <String, dynamic>{
      'full_name': nama.trim(),
      'username': _bersihkanUsername(username),
    };
    if (avatarUrl != null) dasar['avatar_url'] = avatarUrl;

    final tambahan = <String, dynamic>{
      'bio': bio.trim(),
      'phone': phone.trim(),
      'level': level,
      'motivation': motivation,
      'featured_badges': featuredBadges,
    };

    try {
      await client.from('profiles').update({...dasar, ...tambahan}).eq(
        'id',
        userId,
      );
    } on PostgrestException catch (e) {
      // 42703 = kolom belum ada (patch belum dijalankan): simpan bagian dasar.
      if (e.code == '42703') {
        await client.from('profiles').update(dasar).eq('id', userId);
      } else {
        debugPrint('[Profil] Gagal menyimpan profil: ${e.message}');
        throw Exception(_pesanSimpan(e.message));
      }
    } catch (e) {
      debugPrint('[Profil] Gagal menyimpan profil: $e');
      throw Exception('Gagal menyimpan profil. Periksa koneksi internet.');
    }

    _cache = null;
    _inFlight = null;
    final tersimpan = await profilSaya(force: true);
    if (tersimpan != null) return tersimpan;

    // Akun baru bisa belum punya baris profil (trigger belum jalan):
    // buat baris dasar agar nama & foto dari langkah pendaftaran tersimpan.
    try {
      await client.from('profiles').insert({'id': userId, ...dasar});
    } on PostgrestException catch (e) {
      debugPrint('[Profil] Gagal membuat baris profil: ${e.message}');
      throw Exception(_pesanSimpan(e.message));
    }

    _cache = null;
    _inFlight = null;
    return profilSaya(force: true);
  }

  /// Mengunggah foto profil (sudah dikompres ke WebP) ke bucket `avatars`
  /// lalu mengembalikan URL publiknya.
  Future<String> unggahAvatar(String pathLokal) async {
    final client = _requireClient();
    final userId = _userId;
    if (userId == null) {
      throw Exception('Sesi berakhir. Silakan masuk lagi.');
    }

    final berkas = File(pathLokal);
    if (!berkas.existsSync()) {
      throw Exception('Berkas foto tidak ditemukan. Coba pilih ulang.');
    }

    final namaBerkas = 'avatar_${DateTime.now().millisecondsSinceEpoch}.webp';
    final objectPath = '$userId/$namaBerkas';

    try {
      await client.storage.from(bucketAvatar).upload(
            objectPath,
            berkas,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
              upsert: true,
            ),
          );
      return client.storage.from(bucketAvatar).getPublicUrl(objectPath);
    } on StorageException catch (e) {
      debugPrint('[Profil] Gagal mengunggah foto: ${e.message}');
      throw Exception(
        'Gagal mengunggah foto profil. Pastikan bucket "avatars" sudah dibuat.',
      );
    } catch (e) {
      debugPrint('[Profil] Gagal mengunggah foto: $e');
      throw Exception(
          'Gagal mengunggah foto profil. Periksa koneksi internet.');
    }
  }

  Future<ProfilPengguna?> _queryProfil(SupabaseClient client) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      final rows = await _selectProfil(client, userId: userId);
      if (rows.isEmpty) return null;
      return ProfilPengguna.fromRow(rows.first);
    } on PostgrestException catch (e) {
      debugPrint('[Profil] Gagal membaca profil: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Profil] Gagal membaca profil: $e');
      return null;
    }
  }

  /// Membaca `profiles` dengan kolom lengkap, lalu mundur ke kolom dasar bila
  /// kolom tambahan belum ada di server.
  Future<List<Map<String, dynamic>>> _selectProfil(
    SupabaseClient client, {
    String? userId,
    bool urutPoin = false,
    bool tanpaAdmin = false,
    int? batas,
  }) async {
    Future<List<Map<String, dynamic>>> ambil(String kolom) async {
      var query = client.from('profiles').select(kolom);
      if (userId != null) query = query.eq('id', userId);
      if (tanpaAdmin) query = query.neq('role', 'admin');
      final PostgrestTransformBuilder<List<Map<String, dynamic>>> akhir =
          urutPoin
              ? query.order('points', ascending: false)
              : query.order('id');
      return batas == null ? akhir : akhir.limit(batas);
    }

    try {
      return await ambil(_kolomLengkap);
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      debugPrint('[Profil] Kolom tambahan belum ada, memakai kolom dasar.');
      return await ambil(_kolomDasar);
    }
  }

  SupabaseClient _requireClient() {
    final client = _safeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }
    return client;
  }

  static String _bersihkanUsername(String nilai) {
    final bersih = nilai.trim().replaceAll('@', '');
    return bersih;
  }

  static String _pesanSimpan(String pesan) {
    final m = pesan.toLowerCase();
    if (m.contains('duplicate') || m.contains('unique')) {
      return 'Username sudah dipakai pengguna lain.';
    }
    if (m.contains('row-level security') || m.contains('permission')) {
      return 'Tidak diizinkan mengubah profil. Jalankan patch backend lalu coba lagi.';
    }
    return 'Gagal menyimpan profil. Coba lagi.';
  }
}
