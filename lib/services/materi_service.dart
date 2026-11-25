import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bab_model.dart';

/// Data mentah tab Materi: baris tabel `materi`, jumlah kuis per materi,
/// serta progres belajar pengguna yang sedang masuk.
///
/// Progres dibaca dari `progres_materi` dan hasil kuis dari `hasil_kuis`.
/// Bila tabel progres belum tersedia di server, nilainya dianggap kosong
/// sehingga aplikasi tetap bisa menampilkan daftar bab.
class MateriSnapshot {
  final List<Map<String, dynamic>> materiRows;
  final Map<String, int> kuisCount;
  final Map<String, int> hurufSelesai;
  final Map<String, int> kuisSelesai;

  const MateriSnapshot({
    required this.materiRows,
    required this.kuisCount,
    required this.hurufSelesai,
    required this.kuisSelesai,
  });

  int hurufUntuk(String materiId) => hurufSelesai[materiId] ?? 0;
  int kuisUntuk(String materiId) => kuisCount[materiId] ?? 0;
  int kuisSelesaiUntuk(String materiId) => kuisSelesai[materiId] ?? 0;
}

/// Satu bagian materi (tabel `materi_bagian`): teks, foto, dan/atau video.
class MateriBagian {
  final String id;
  final int urutan;
  final String judul;
  final String isi;
  final String? fotoUrl;
  final String? videoUrl;

  /// Huruf yang dilatih bagian ini (mis. `A`). Dipakai kamera untuk
  /// menampilkan isi materi yang cocok saat huruf terdeteksi.
  final String? huruf;

  const MateriBagian({
    required this.id,
    required this.urutan,
    required this.judul,
    required this.isi,
    this.fotoUrl,
    this.videoUrl,
    this.huruf,
  });

  bool get adaFoto => fotoUrl != null && fotoUrl!.isNotEmpty;
  bool get adaVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory MateriBagian.fromRow(Map<String, dynamic> row) {
    final foto = (row['foto_url'] as String?)?.trim();
    final video = (row['video_url'] as String?)?.trim();
    final huruf = (row['huruf'] as String?)?.trim().toUpperCase();
    return MateriBagian(
      id: row['id'].toString(),
      urutan: (row['urutan'] as num?)?.toInt() ?? 0,
      judul: (row['judul'] as String?)?.trim() ?? '',
      isi: (row['isi'] as String?)?.trim() ?? '',
      fotoUrl: (foto == null || foto.isEmpty) ? null : foto,
      videoUrl: (video == null || video.isEmpty) ? null : video,
      huruf: (huruf == null || huruf.isEmpty) ? null : huruf,
    );
  }
}

/// Service data materi & kuis yang dipakai bersama tab Materi dan Kuis.
class MateriService {
  final SupabaseClient? _customClient;

  MateriService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _userId => _safeClient?.auth.currentUser?.id;

  SupabaseClient _requireClient() {
    final client = _safeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }
    return client;
  }

  /// Mengambil seluruh data yang dibutuhkan daftar bab.
  Future<MateriSnapshot> fetchSnapshot() async {
    final client = _requireClient();
    final userId = _userId;

    // Keempat query tidak saling bergantung, jadi dijalankan paralel agar
    // tab Materi/Kuis tidak menunggu empat round-trip berurutan.
    final materiFuture = _select(client, 'materi', 'urutan');
    final kuisFuture = _select(client, 'kuis', 'created_at');
    final progresFuture = userId == null
        ? Future<List<Map<String, dynamic>>>.value(const [])
        : _selectOptional(
            client,
            'progres_materi',
            filters: {'user_id': userId},
          );
    final hasilFuture = userId == null
        ? Future<List<Map<String, dynamic>>>.value(const [])
        : _selectOptional(
            client,
            'hasil_kuis',
            filters: {'user_id': userId},
          );

    final rows = await materiFuture;
    final kuisRows = await kuisFuture;
    final progres = await progresFuture;
    final hasil = await hasilFuture;

    final kuisCount = <String, int>{};
    final kuisMateri = <String, List<String>>{};
    for (final row in kuisRows) {
      final materiId = row['materi_id']?.toString();
      final kuisId = row['id']?.toString();
      if (materiId == null || kuisId == null) continue;
      kuisCount[materiId] = (kuisCount[materiId] ?? 0) + 1;
      kuisMateri.putIfAbsent(materiId, () => []).add(kuisId);
    }

    final hurufSelesai = <String, int>{};
    final kuisSelesai = <String, int>{};

    if (userId != null) {
      for (final row in progres) {
        final materiId = row['materi_id']?.toString();
        if (materiId == null) continue;
        hurufSelesai[materiId] =
            (row['huruf_dipelajari'] as num?)?.toInt() ?? 0;
      }

      final selesaiSet = <String>{};
      for (final row in hasil) {
        final kuisId = row['kuis_id']?.toString();
        if (kuisId != null) selesaiSet.add(kuisId);
      }
      for (final entry in kuisMateri.entries) {
        kuisSelesai[entry.key] = entry.value.where(selesaiSet.contains).length;
      }
    }

    return MateriSnapshot(
      materiRows: rows,
      kuisCount: kuisCount,
      hurufSelesai: hurufSelesai,
      kuisSelesai: kuisSelesai,
    );
  }

  /// Seluruh bab siap tampil, sudah diberi status terkunci berurutan.
  Future<List<Bab>> fetchBabList() async {
    final snapshot = await fetchSnapshot();
    return _buildBabList(snapshot);
  }

  /// Satu bab berdasarkan UUID materi, atau `null` bila tidak ada.
  Future<Bab?> fetchBabById(String materiId) async {
    final snapshot = await fetchSnapshot();
    for (final bab in _buildBabList(snapshot)) {
      if (bab.id == materiId) return bab;
    }
    return null;
  }

  static List<Bab> _buildBabList(MateriSnapshot snapshot) {
    final babList = <Bab>[];
    var previousCompleted = true;
    for (final row in snapshot.materiRows) {
      final materiId = row['id'].toString();
      final bab = Bab.fromRow(
        row,
        hurufDipelajari: snapshot.hurufUntuk(materiId),
        kuisCount: snapshot.kuisUntuk(materiId),
        kuisSelesai: snapshot.kuisSelesaiUntuk(materiId),
        previousCompleted: previousCompleted,
      );
      previousCompleted = bab.isCompleted;
      babList.add(bab);
    }
    return babList;
  }

  /// Bagian-bagian satu materi, diurutkan menurut `urutan`.
  ///
  /// Mengembalikan daftar kosong bila tabel `materi_bagian` belum ada.
  Future<List<MateriBagian>> fetchBagian(String materiId) async {
    final client = _safeClient;
    if (client == null) return const [];
    try {
      final data = await client
          .from('materi_bagian')
          .select('*')
          .eq('materi_id', materiId)
          .order('urutan', ascending: true);
      return data
          .cast<Map<String, dynamic>>()
          .map(MateriBagian.fromRow)
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('[Materi] Bagian materi tidak tersedia: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('[Materi] Bagian materi tidak tersedia: $e');
      return const [];
    }
  }

  /// Menyimpan jumlah huruf yang sudah dipelajari untuk satu materi.
  Future<void> simpanProgresHuruf({
    required String materiId,
    required int hurufDipelajari,
    required int totalHuruf,
  }) async {
    final client = _safeClient;
    final userId = _userId;
    if (client == null || userId == null) return;

    final selesai = totalHuruf > 0 && hurufDipelajari >= totalHuruf;
    try {
      await client.from('progres_materi').upsert({
        'user_id': userId,
        'materi_id': materiId,
        'huruf_dipelajari': hurufDipelajari,
        'total_huruf': totalHuruf,
        'status': selesai ? 'selesai' : 'berjalan',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,materi_id');
    } on PostgrestException catch (e) {
      debugPrint('[Materi] Gagal menyimpan progres: ${e.message}');
    } catch (e) {
      debugPrint('[Materi] Gagal menyimpan progres: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _select(
    SupabaseClient client,
    String table,
    String orderColumn,
  ) async {
    try {
      final data = await client
          .from(table)
          .select('*')
          .order(orderColumn, ascending: true);
      return data.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      debugPrint('[Materi] Gagal membaca $table: ${e.message}');
      throw Exception(_friendly(e));
    } catch (e) {
      debugPrint('[Materi] Gagal membaca $table: $e');
      throw Exception(
        'Tidak dapat memuat data. Periksa koneksi internet lalu coba lagi.',
      );
    }
  }

  /// Membaca tabel opsional. Tabel yang belum ada dianggap kosong.
  Future<List<Map<String, dynamic>>> _selectOptional(
    SupabaseClient client,
    String table, {
    required Map<String, String> filters,
  }) async {
    try {
      var query = client.from(table).select('*');
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
      final data = await query;
      return data.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      debugPrint('[Materi] $table tidak tersedia: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('[Materi] $table tidak tersedia: $e');
      return const [];
    }
  }

  String _friendly(PostgrestException e) {
    if (e.code == 'PGRST205' || e.message.contains('does not exist')) {
      return 'Tabel materi belum tersedia di server. Hubungi admin.';
    }
    return 'Gagal memuat materi: ${e.message}';
  }
}
