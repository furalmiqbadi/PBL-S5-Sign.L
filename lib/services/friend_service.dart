import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friend_model.dart';

/// Pertemanan antar pengguna: cari orang, kirim/terima permintaan,
/// daftar teman, dan saran teman.
///
/// Tabel `friendships` dibuat oleh `supabase/patch_signl_sosial.sql`.
class FriendService {
  FriendService({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;

  static const String _kolomProfil =
      'id, full_name, username, role, avatar_url, points';

  /// Cadangan bila kolom tambahan (`role`, `avatar_url`, `points`) belum ada.
  static const String _kolomDasar = 'id, full_name, username';

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
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

  String? get _userId => _safeClient?.auth.currentUser?.id;

  // ===== Pencarian =====

  /// Cari pengguna berdasarkan nama atau username, kecuali diri sendiri.
  Future<List<Teman>> cariPengguna(String query, {int batas = 20}) async {
    final client = _requireClient();
    final me = _userId;
    // Buang awalan "@" dan karakter yang merusak filter `or`.
    final q = query
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'[,()%_]'), '')
        .trim();
    if (q.isEmpty) return const [];

    try {
      List<dynamic> rows;
      try {
        rows = await _kueriCari(client, me, q, _kolomProfil, batas);
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        debugPrint('[Teman] Kolom profil belum lengkap, memakai kolom dasar.');
        rows = await _kueriCari(client, me, q, _kolomDasar, batas);
      }
      // RLS tanpa policy SELECT membuat hasil kosong, bukan error. Coba RPC.
      if (rows.isEmpty) rows = await _cariRpc(client, me, q, batas);
      return rows.map((row) => Teman.fromProfil(row)).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal mencari pengguna: ${e.message}');
      final cadangan = await _cariRpc(client, me, q, batas);
      if (cadangan.isNotEmpty) {
        return cadangan.map((row) => Teman.fromProfil(row)).toList();
      }
      throw Exception(_pesanError(e, 'Gagal mencari pengguna. Coba lagi.'));
    }
  }

  /// Pencarian lewat RPC security definer, dipakai saat RLS menolak SELECT.
  /// Membutuhkan `public.cari_profil_publik` dari
  /// `supabase/patch_signl_profil_publik.sql`.
  Future<List<dynamic>> _cariRpc(
    SupabaseClient client,
    String? me,
    String q,
    int batas,
  ) async {
    try {
      final data = await client.rpc(
        'cari_profil_publik',
        params: {'q': q, 'kecuali': me, 'batas': batas},
      );
      return (data as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[Teman] RPC cari_profil_publik gagal: ${e.message}');
      return const [];
    }
  }

  Future<List<dynamic>> _kueriCari(
    SupabaseClient client,
    String? me,
    String q,
    String kolom,
    int batas,
  ) {
    var pencarian = client.from('profiles').select(kolom);
    if (me != null) pencarian = pencarian.neq('id', me);
    return pencarian
        .or('username.ilike.%$q%,full_name.ilike.%$q%')
        .order('full_name')
        .limit(batas);
  }

  // ===== Status relasi =====

  /// Status hubungan dengan [otherId] beserta id baris `friendships`.
  Future<Teman?> statusDengan(String otherId) async {
    final client = _requireClient();
    final me = _userId;
    if (me == null || me == otherId) return null;

    try {
      final rows = await client
          .from('friendships')
          .select('id, requester_id, addressee_id, status')
          .or(
            'and(requester_id.eq.$me,addressee_id.eq.$otherId),'
            'and(requester_id.eq.$otherId,addressee_id.eq.$me)',
          )
          .limit(1);
      if (rows.isEmpty) return null;

      final row = rows.first;
      final profilRows = await _profilPeta([otherId]);
      final profil = profilRows[otherId];
      if (profil == null) return null;

      return Teman.fromProfil(
        profil,
        friendshipId: row['id'].toString(),
        status: _statusDari(row, me),
      );
    } on PostgrestException catch (e) {
      debugPrint('[Teman] friendships belum siap: ${e.message}');
      return null;
    }
  }

  /// Status untuk banyak pengguna sekaligus, dipetakan per id pengguna.
  Future<Map<String, StatusTeman>> statusBanyak(List<String> ids) async {
    final client = _requireClient();
    final me = _userId;
    if (me == null || ids.isEmpty) return const {};

    try {
      final rows = await client
          .from('friendships')
          .select('requester_id, addressee_id, status')
          .or('requester_id.eq.$me,addressee_id.eq.$me');
      final hasil = <String, StatusTeman>{};
      for (final row in rows) {
        final lain = row['requester_id'] == me
            ? row['addressee_id']?.toString()
            : row['requester_id']?.toString();
        if (lain == null || !ids.contains(lain)) continue;
        hasil[lain] = _statusDari(row, me);
      }
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal membaca status: ${e.message}');
      return const {};
    }
  }

  // ===== Aksi =====

  Future<void> kirimPermintaan(String targetId) async {
    final client = _requireClient();
    final me = _userId;
    if (me == null) throw Exception('Kamu belum masuk. Silakan login ulang.');
    if (me == targetId) throw Exception('Tidak bisa menambahkan diri sendiri.');

    try {
      // Satu pasangan hanya punya satu baris, apa pun arahnya.
      final ada = await client
          .from('friendships')
          .select('id')
          .or(
            'and(requester_id.eq.$me,addressee_id.eq.$targetId),'
            'and(requester_id.eq.$targetId,addressee_id.eq.$me)',
          )
          .limit(1);

      if (ada.isEmpty) {
        await client.from('friendships').insert({
          'requester_id': me,
          'addressee_id': targetId,
          'status': 'pending',
        });
        return;
      }

      await client.from('friendships').update({
        'requester_id': me,
        'addressee_id': targetId,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ada.first['id']);
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal mengirim permintaan: ${e.message}');
      throw Exception(_pesanError(e, 'Gagal mengirim permintaan pertemanan.'));
    }
  }

  Future<void> terimaPermintaan(String friendshipId) =>
      _ubahStatus(friendshipId, 'accepted');

  Future<void> tolakPermintaan(String friendshipId) =>
      _ubahStatus(friendshipId, 'rejected');

  Future<void> batalkanPermintaan(String friendshipId) =>
      _hapusRelasi(friendshipId);

  Future<void> hapusTeman(String friendshipId) => _hapusRelasi(friendshipId);

  /// Dipakai tombol "Ikuti balik": bila mereka sudah mengirim permintaan,
  /// langsung diterima; bila belum, kita kirim permintaan baru.
  Future<void> ikutiBalik(String otherId) async {
    final relasi = await statusDengan(otherId);
    if (relasi != null && relasi.status == StatusTeman.menungguKita) {
      await terimaPermintaan(relasi.friendshipId!);
      return;
    }
    await kirimPermintaan(otherId);
  }

  Future<void> _ubahStatus(String friendshipId, String status) async {
    final client = _requireClient();
    try {
      await client.from('friendships').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', friendshipId);
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal memperbarui status: ${e.message}');
      throw Exception(_pesanError(e, 'Gagal memperbarui pertemanan.'));
    }
  }

  Future<void> _hapusRelasi(String friendshipId) async {
    final client = _requireClient();
    try {
      await client.from('friendships').delete().eq('id', friendshipId);
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal menghapus relasi: ${e.message}');
      throw Exception(_pesanError(e, 'Gagal menghapus pertemanan.'));
    }
  }

  // ===== Daftar =====

  Future<List<Teman>> daftarTeman() async {
    final client = _requireClient();
    final me = _userId;
    if (me == null) return const [];

    try {
      final rows = await client
          .from('friendships')
          .select('id, requester_id, addressee_id')
          .eq('status', 'accepted')
          .or('requester_id.eq.$me,addressee_id.eq.$me');

      final profil = await _profilPeta(
        rows.map((r) => _lawanBicara(r, me)).whereType<String>().toList(),
      );
      final hasil = <Teman>[];
      for (final row in rows) {
        final lain = _lawanBicara(row, me);
        final data = profil[lain];
        if (data == null) continue;
        hasil.add(
          Teman.fromProfil(
            data,
            friendshipId: row['id'].toString(),
            status: StatusTeman.berteman,
          ),
        );
      }
      hasil
          .sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal memuat teman: ${e.message}');
      throw Exception(_pesanError(e, 'Gagal memuat daftar teman.'));
    }
  }

  Future<List<PermintaanTeman>> daftarPermintaanMasuk() =>
      _permintaan(masuk: true);

  Future<List<PermintaanTeman>> daftarPermintaanKeluar() =>
      _permintaan(masuk: false);

  Future<List<PermintaanTeman>> _permintaan({required bool masuk}) async {
    final client = _requireClient();
    final me = _userId;
    if (me == null) return const [];

    try {
      final kolom = masuk ? 'addressee_id' : 'requester_id';
      final rows = await client
          .from('friendships')
          .select('id, requester_id, addressee_id, created_at')
          .eq('status', 'pending')
          .eq(kolom, me)
          .order('created_at', ascending: false);

      final profil = await _profilPeta(
        rows.map((r) => _lawanBicara(r, me)).whereType<String>().toList(),
      );
      final hasil = <PermintaanTeman>[];
      for (final row in rows) {
        final data = profil[_lawanBicara(row, me)];
        if (data == null) continue;
        hasil.add(
          PermintaanTeman(
            friendshipId: row['id'].toString(),
            pengguna: Teman.fromProfil(
              data,
              friendshipId: row['id'].toString(),
              status:
                  masuk ? StatusTeman.menungguKita : StatusTeman.menungguMereka,
            ),
            waktu: DateTime.tryParse('${row['created_at'] ?? ''}'),
          ),
        );
      }
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal memuat permintaan: ${e.message}');
      throw Exception(_pesanError(e, 'Gagal memuat permintaan pertemanan.'));
    }
  }

  /// Pengguna yang belum berteman, diurut dari poin tertinggi.
  Future<List<Teman>> saranTeman({int batas = 10}) async {
    final client = _requireClient();
    final me = _userId;
    if (me == null) return const [];

    try {
      final relasi = await client
          .from('friendships')
          .select('requester_id, addressee_id, status')
          .or('requester_id.eq.$me,addressee_id.eq.$me');
      final dikecualikan = <String>{me};
      final statusPer = <String, StatusTeman>{};
      for (final row in relasi) {
        final lain = _lawanBicara(row, me);
        if (lain == null) continue;
        dikecualikan.add(lain);
        statusPer[lain] = _statusDari(row, me);
      }

      final rows = await _kueriSaran(client, me, batas + dikecualikan.length);
      final sumber = rows.isEmpty
          ? await _cariRpc(client, me, '', batas + dikecualikan.length)
          : rows;

      final hasil = <Teman>[];
      for (final row in sumber) {
        final id = row['id'].toString();
        if (dikecualikan.contains(id)) continue;
        hasil.add(Teman.fromProfil(row));
        if (hasil.length >= batas) break;
      }
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal memuat saran: ${e.message}');
      return const [];
    }
  }

  // ===== Helper =====

  /// Saran teman: urutkan dari poin tertinggi bila kolom tersedia.
  Future<List<dynamic>> _kueriSaran(
    SupabaseClient client,
    String me,
    int batas,
  ) async {
    try {
      return await client
          .from('profiles')
          .select(_kolomProfil)
          .neq('id', me)
          .neq('role', 'admin')
          .order('points', ascending: false)
          .limit(batas);
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      debugPrint('[Teman] Kolom profil belum lengkap, memakai kolom dasar.');
      return await client
          .from('profiles')
          .select(_kolomDasar)
          .neq('id', me)
          .order('full_name')
          .limit(batas);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _profilPeta(
    List<String> ids,
  ) async {
    final client = _requireClient();
    if (ids.isEmpty) return const {};
    try {
      List<dynamic> rows;
      try {
        rows = await client
            .from('profiles')
            .select(_kolomProfil)
            .inFilter('id', ids);
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        rows = await client
            .from('profiles')
            .select(_kolomDasar)
            .inFilter('id', ids);
      }
      return {
        for (final row in rows) '${row['id']}': Map<String, dynamic>.from(row),
      };
    } on PostgrestException catch (e) {
      debugPrint('[Teman] Gagal membaca profil: ${e.message}');
      return _profilRpc(ids);
    }
  }

  /// Baca profil lewat RPC security definer saat RLS menolak SELECT.
  Future<Map<String, Map<String, dynamic>>> _profilRpc(
    List<String> ids,
  ) async {
    final client = _requireClient();
    try {
      final data = await client.rpc(
        'get_profil_publik',
        params: {'ids': ids},
      );
      return {
        for (final row in (data as List<dynamic>))
          '${row['id']}': Map<String, dynamic>.from(row as Map),
      };
    } on PostgrestException catch (e) {
      debugPrint('[Teman] RPC get_profil_publik gagal: ${e.message}');
      return const {};
    }
  }

  String? _lawanBicara(Map<String, dynamic> row, String me) {
    final requester = row['requester_id']?.toString();
    final addressee = row['addressee_id']?.toString();
    if (requester == me) return addressee;
    if (addressee == me) return requester;
    return null;
  }

  StatusTeman _statusDari(Map<String, dynamic> row, String me) {
    final status = row['status'] as String? ?? 'pending';
    switch (status) {
      case 'accepted':
        return StatusTeman.berteman;
      case 'blocked':
        return StatusTeman.diblokir;
      case 'rejected':
        return StatusTeman.ditolak;
      default:
        return row['requester_id'] == me
            ? StatusTeman.menungguMereka
            : StatusTeman.menungguKita;
    }
  }

  String _pesanError(PostgrestException e, String pesan) {
    if (e.code == '42P01' || e.code == 'PGRST205') {
      return 'Fitur teman belum siap. Jalankan '
          'supabase/patch_signl_sosial.sql di SQL Editor Supabase.';
    }
    if (e.code == '42501' ||
        e.message.toLowerCase().contains('row-level security')) {
      return 'Akses profil ditolak. Jalankan '
          'supabase/patch_signl_profil_publik.sql di SQL Editor Supabase.';
    }
    return pesan;
  }
}
