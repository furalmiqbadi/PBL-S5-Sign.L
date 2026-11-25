import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu kuis (`kuis`) beserta jumlah soal dan jumlah soal yang sudah dikerjakan
/// pengguna aktif.
class KuisInfo {
  final String id;
  final String materiId;
  final String judul;
  final String deskripsi;
  final int xpReward;
  final int jumlahSoal;
  final bool sudahDikerjakan;

  /// `true` bila minimal satu soal memakai gambar pertanyaan atau opsi gambar.
  final bool adaGambar;

  /// `latihan` untuk latihan soal mandiri, `kuis` untuk kuis materi.
  final String tipe;

  /// Banner kuis dari panel admin, bila ada.
  final String? bannerUrl;

  const KuisInfo({
    required this.id,
    required this.materiId,
    required this.judul,
    required this.deskripsi,
    required this.xpReward,
    required this.jumlahSoal,
    required this.sudahDikerjakan,
    this.adaGambar = false,
    this.tipe = 'kuis',
    this.bannerUrl,
  });

  bool get bisaDikerjakan => jumlahSoal > 0;

  bool get isLatihan => tipe == 'latihan';
}

/// Satu soal dari tabel `soal`.
///
/// Soal bisa berupa teks biasa (`tipe = 'teks'`), pertanyaan bergambar
/// (`gambar_pertanyaan`), atau pilihan jawaban bergambar (`opsi_gambar`).
class SoalKuis {
  /// Batas jumlah soal per pengerjaan; kuis di atas ini dipotong.
  static const int maksSoal = 20;

  final String pertanyaan;
  final List<String> opsi;
  final String jawabanBenar;
  final String? gambarPertanyaan;
  final List<String> opsiGambar;
  final String penjelasan;

  const SoalKuis({
    required this.pertanyaan,
    required this.opsi,
    required this.jawabanBenar,
    this.gambarPertanyaan,
    this.opsiGambar = const [],
    this.penjelasan = '',
  });

  bool get adaGambarPertanyaan =>
      gambarPertanyaan != null && gambarPertanyaan!.isNotEmpty;

  bool get adaOpsiGambar =>
      opsiGambar.isNotEmpty && opsiGambar.any((g) => g.isNotEmpty);

  /// Gambar untuk opsi ke-[index], atau null bila opsi itu hanya teks.
  String? gambarOpsi(int index) {
    if (index < 0 || index >= opsiGambar.length) return null;
    final url = opsiGambar[index].trim();
    return url.isEmpty ? null : url;
  }

  static SoalKuis? fromRow(Map<String, dynamic> row) {
    final pertanyaan = (row['pertanyaan'] as String?)?.trim() ?? '';
    final jawaban = (row['jawaban_benar'] as String?)?.trim() ?? '';
    final opsiRaw = row['opsi'];
    final opsi = opsiRaw is List
        ? opsiRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    final gambar = (row['gambar_pertanyaan'] as String?)?.trim();
    final opsiGambarRaw = row['opsi_gambar'];
    final opsiGambar = opsiGambarRaw is List
        ? opsiGambarRaw.map((e) => e.toString()).toList()
        : const <String>[];
    if ((pertanyaan.isEmpty && (gambar == null || gambar.isEmpty)) ||
        jawaban.isEmpty ||
        opsi.isEmpty) {
      return null;
    }
    return SoalKuis(
      pertanyaan: pertanyaan,
      opsi: opsi,
      jawabanBenar: jawaban,
      gambarPertanyaan: (gambar == null || gambar.isEmpty) ? null : gambar,
      opsiGambar: opsiGambar,
      penjelasan: (row['penjelasan'] as String?)?.trim() ?? '',
    );
  }
}

/// Service kuis: daftar kuis per materi, soal satu kuis, dan penyimpanan hasil.
class KuisService {
  final SupabaseClient? _customClient;

  KuisService({SupabaseClient? client}) : _customClient = client;

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

  /// Mengambil semua kuis beserta jumlah soal nyata dan status pengerjaan.
  Future<List<KuisInfo>> fetchDaftarKuis() async {
    final client = _requireClient();
    try {
      final kuisRows =
          await client.from('kuis').select('*').order('created_at');
      final soalRows = await _selectSoalRingkas(client);

      final jumlahSoal = <String, int>{};
      final kuisBergambar = <String>{};
      for (final row in soalRows) {
        final kuisId = row['kuis_id']?.toString();
        if (kuisId == null) continue;
        jumlahSoal[kuisId] = (jumlahSoal[kuisId] ?? 0) + 1;
        final gambarPertanyaan = (row['gambar_pertanyaan'] as String?)?.trim();
        final opsiGambar = row['opsi_gambar'];
        final adaOpsiGambar = opsiGambar is List &&
            opsiGambar.any((e) => e.toString().trim().isNotEmpty);
        if ((gambarPertanyaan != null && gambarPertanyaan.isNotEmpty) ||
            adaOpsiGambar) {
          kuisBergambar.add(kuisId);
        }
      }

      final dikerjakan = <String>{};
      final userId = _userId;
      if (userId != null) {
        try {
          final hasil = await client
              .from('hasil_kuis')
              .select('kuis_id')
              .eq('user_id', userId);
          for (final row in hasil) {
            final kuisId = row['kuis_id']?.toString();
            if (kuisId != null) dikerjakan.add(kuisId);
          }
        } on PostgrestException catch (e) {
          debugPrint('[Kuis] Gagal membaca hasil_kuis: ${e.message}');
        }
      }

      return kuisRows.map((row) {
        final id = row['id'].toString();
        final banner = (row['banner_url'] as String?)?.trim();
        return KuisInfo(
          id: id,
          materiId: row['materi_id']?.toString() ?? '',
          judul: (row['judul'] as String?)?.trim() ?? 'Kuis',
          deskripsi: (row['deskripsi'] as String?)?.trim() ?? '',
          xpReward: (row['xp_reward'] as num?)?.toInt() ?? 0,
          jumlahSoal: jumlahSoal[id] ?? 0,
          sudahDikerjakan: dikerjakan.contains(id),
          adaGambar: kuisBergambar.contains(id),
          tipe: (row['tipe'] as String?) ?? 'kuis',
          bannerUrl: (banner == null || banner.isEmpty) ? null : banner,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Kuis] Gagal memuat kuis: ${e.message}');
      throw Exception('Gagal memuat kuis: ${e.message}');
    } catch (e) {
      debugPrint('[Kuis] Gagal memuat kuis: $e');
      throw Exception(
        'Tidak dapat memuat kuis. Periksa koneksi internet lalu coba lagi.',
      );
    }
  }

  /// Membaca ringkasan soal. Kolom media hanya ada setelah patch SQL
  /// dijalankan, jadi bila belum ada (`42703`) baca kolom minimal.
  Future<List<Map<String, dynamic>>> _selectSoalRingkas(
    SupabaseClient client,
  ) async {
    try {
      final rows = await client
          .from('soal')
          .select('kuis_id,gambar_pertanyaan,opsi_gambar');
      return rows;
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      final rows = await client.from('soal').select('kuis_id');
      return rows;
    }
  }

  /// Mengambil soal satu kuis. Baris yang tidak lengkap dilewati.
  Future<List<SoalKuis>> fetchSoal(String kuisId) async {
    final client = _requireClient();
    try {
      final rows = await client
          .from('soal')
          .select('*')
          .eq('kuis_id', kuisId)
          .order('urutan')
          .order('created_at')
          .limit(SoalKuis.maksSoal);
      return rows.map(SoalKuis.fromRow).whereType<SoalKuis>().toList();
    } on PostgrestException catch (e) {
      debugPrint('[Kuis] Gagal memuat soal: ${e.message}');
      throw Exception('Gagal memuat soal kuis: ${e.message}');
    } catch (e) {
      debugPrint('[Kuis] Gagal memuat soal: $e');
      throw Exception(
        'Tidak dapat memuat soal. Periksa koneksi internet lalu coba lagi.',
      );
    }
  }

  /// Menyimpan hasil kuis pengguna (`hasil_kuis` hanya punya kolom skor).
  /// Mengembalikan `true` bila hasil tersimpan.
  Future<bool> simpanHasil({required String kuisId, required int skor}) async {
    final client = _safeClient;
    final userId = _userId;
    if (client == null || userId == null) return false;
    try {
      await client.from('hasil_kuis').insert({
        'user_id': userId,
        'kuis_id': kuisId,
        'skor': skor,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('[Kuis] Gagal menyimpan hasil: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Kuis] Gagal menyimpan hasil: $e');
      return false;
    }
  }
}
