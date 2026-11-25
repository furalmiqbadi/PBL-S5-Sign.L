import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nama_tampil.dart';

/// Batas soal per kuis, sama dengan batas pengerjaan di aplikasi.
const int maksSoalPerKuis = 20;

String? _teksAtauNull(String? value) {
  final bersih = value?.trim();
  return (bersih == null || bersih.isEmpty) ? null : bersih;
}

/// Ringkasan angka untuk dasbor panel admin.
class AdminRingkasan {
  final int totalPengguna;
  final int laporanBaru;
  final int laporanChat;
  final int reviewMenunggu;
  final int totalMateri;
  final int totalKuis;

  const AdminRingkasan({
    this.totalPengguna = 0,
    this.laporanBaru = 0,
    this.laporanChat = 0,
    this.reviewMenunggu = 0,
    this.totalMateri = 0,
    this.totalKuis = 0,
  });

  int get tugasMenunggu => laporanBaru + laporanChat + reviewMenunggu;
}

/// Satu laporan pengguna dari tabel `laporan`.
class LaporanItem {
  final String id;
  final String tipe;
  final String pelapor;
  final String terlapor;
  final String alasan;
  final String detail;
  final String pesan;
  final String status;
  final DateTime? dibuat;
  final String balasan;
  final String alasanBalasan;
  final DateTime? dibalas;

  const LaporanItem({
    required this.id,
    required this.tipe,
    required this.pelapor,
    required this.terlapor,
    required this.alasan,
    required this.detail,
    required this.pesan,
    required this.status,
    this.dibuat,
    this.balasan = '',
    this.alasanBalasan = '',
    this.dibalas,
  });

  factory LaporanItem.fromRow(Map<String, dynamic> row) => LaporanItem(
        id: row['id'].toString(),
        tipe: (row['tipe'] as String?) ?? 'post',
        pelapor: (row['pelapor'] as String?) ?? labelNamaNetral,
        terlapor: (row['terlapor'] as String?) ?? labelNamaNetral,
        alasan: (row['alasan'] as String?) ?? '-',
        detail: (row['detail'] as String?) ?? '',
        pesan: (row['pesan'] as String?) ?? '',
        status: (row['status'] as String?) ?? 'baru',
        dibuat: DateTime.tryParse((row['created_at'] as String?) ?? ''),
        balasan: (row['balasan'] as String?) ?? '',
        alasanBalasan: (row['alasan_balasan'] as String?) ?? '',
        dibalas: DateTime.tryParse((row['dibalas_at'] as String?) ?? ''),
      );

  bool get sudahDibalas => status == 'dibalas';

  String get waktu => formatWaktu(dibuat);
}

/// Satu kiriman media untuk ditinjau (`review_media`).
class MediaItem {
  final String id;
  final String namaUser;
  final String tipe;
  final String deskripsi;
  final String status;
  final DateTime? dibuat;

  const MediaItem({
    required this.id,
    required this.namaUser,
    required this.tipe,
    required this.deskripsi,
    required this.status,
    this.dibuat,
  });

  factory MediaItem.fromRow(Map<String, dynamic> row) => MediaItem(
        id: row['id'].toString(),
        namaUser: (row['nama_user'] as String?) ?? labelNamaNetral,
        tipe: (row['tipe'] as String?) ?? 'foto',
        deskripsi: (row['deskripsi'] as String?) ?? '',
        status: (row['status'] as String?) ?? 'menunggu',
        dibuat: DateTime.tryParse((row['created_at'] as String?) ?? ''),
      );

  bool get isVideo => tipe == 'video';
  String get waktu => formatWaktu(dibuat);
}

/// Satu baris tabel `profiles` untuk manajemen pengguna & leaderboard.
class PenggunaItem {
  final String id;
  final String nama;
  final String username;
  final String role;
  final bool banned;
  final int xp;
  final int points;
  final int streak;

  const PenggunaItem({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    required this.banned,
    required this.xp,
    required this.points,
    required this.streak,
  });

  factory PenggunaItem.fromRow(Map<String, dynamic> row) => PenggunaItem(
        id: row['id'].toString(),
        nama: namaTampilDari(row),
        username: (row['username'] as String?) ?? '',
        role: (row['role'] as String?) ?? 'user',
        banned: (row['is_banned'] as bool?) ?? false,
        xp: (row['xp'] as num?)?.toInt() ?? 0,
        points: (row['points'] as num?)?.toInt() ?? 0,
        streak: (row['streak'] as num?)?.toInt() ?? 0,
      );

  String get roleLabel => labelPeran(role);
}

/// Satu baris `materi` untuk halaman Management Materi.
class MateriAdminItem {
  final String id;
  final String judul;
  final String deskripsi;
  final int urutan;
  final bool published;
  final int jumlahKuis;
  final String? gambarUrl;
  final String? videoUrl;
  final String? kameraHuruf;

  const MateriAdminItem({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.urutan,
    required this.published,
    required this.jumlahKuis,
    this.gambarUrl,
    this.videoUrl,
    this.kameraHuruf,
  });

  bool get adaGambar => gambarUrl != null && gambarUrl!.isNotEmpty;
  bool get adaVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get adaKamera => kameraHuruf != null && kameraHuruf!.isNotEmpty;
}

/// Satu baris `kuis` untuk halaman Management Kuis.
class KuisAdminItem {
  final String id;
  final String materiId;
  final String judul;
  final String deskripsi;
  final int xpReward;
  final int jumlahSoal;

  /// Banner kuis (opsional), dipakai di kartu kuis dan saat membagikan hasil.
  final String? bannerUrl;

  /// `kuis` untuk kuis materi, `latihan` untuk latihan soal mandiri.
  final String tipe;

  const KuisAdminItem({
    required this.id,
    required this.materiId,
    required this.judul,
    required this.deskripsi,
    required this.xpReward,
    required this.jumlahSoal,
    this.bannerUrl,
    this.tipe = 'kuis',
  });

  bool get isLatihan => tipe == 'latihan';
}

/// Satu bagian materi (tabel `materi_bagian`): teks, foto, dan/atau video.
class MateriBagianItem {
  final String id;
  final String materiId;
  final int urutan;
  final String judul;
  final String isi;
  final String? fotoUrl;
  final String? videoUrl;

  /// Huruf yang dilatih bagian ini (mis. `A`), dipakai layar kamera.
  final String? huruf;

  const MateriBagianItem({
    required this.id,
    required this.materiId,
    required this.urutan,
    required this.judul,
    required this.isi,
    this.fotoUrl,
    this.videoUrl,
    this.huruf,
  });

  bool get adaFoto => fotoUrl != null && fotoUrl!.isNotEmpty;
  bool get adaVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory MateriBagianItem.fromRow(Map<String, dynamic> row) {
    final foto = (row['foto_url'] as String?)?.trim();
    final video = (row['video_url'] as String?)?.trim();
    final huruf = (row['huruf'] as String?)?.trim().toUpperCase();
    return MateriBagianItem(
      id: row['id'].toString(),
      materiId: row['materi_id']?.toString() ?? '',
      urutan: (row['urutan'] as num?)?.toInt() ?? 0,
      judul: (row['judul'] as String?)?.trim() ?? '',
      isi: (row['isi'] as String?)?.trim() ?? '',
      fotoUrl: (foto == null || foto.isEmpty) ? null : foto,
      videoUrl: (video == null || video.isEmpty) ? null : video,
      huruf: (huruf == null || huruf.isEmpty) ? null : huruf,
    );
  }
}

/// Isian satu soal pada wizard kuis.
class SoalDraft {
  const SoalDraft({
    required this.pertanyaan,
    required this.opsi,
    required this.jawabanBenar,
    this.gambarPertanyaan,
    this.opsiGambar = const [],
    this.penjelasan = '',
  });

  final String pertanyaan;
  final List<String> opsi;
  final String jawabanBenar;
  final String? gambarPertanyaan;
  final List<String> opsiGambar;
  final String penjelasan;
}

/// Satu baris `soal` untuk kelola soal di panel admin.
class SoalAdminItem {
  final String id;
  final String kuisId;
  final String pertanyaan;
  final List<String> opsi;
  final String jawabanBenar;
  final String? gambarPertanyaan;
  final List<String> opsiGambar;
  final String penjelasan;
  final int urutan;

  const SoalAdminItem({
    required this.id,
    required this.kuisId,
    required this.pertanyaan,
    required this.opsi,
    required this.jawabanBenar,
    required this.urutan,
    this.gambarPertanyaan,
    this.opsiGambar = const [],
    this.penjelasan = '',
  });

  bool get adaGambar =>
      (gambarPertanyaan != null && gambarPertanyaan!.isNotEmpty) ||
      opsiGambar.any((g) => g.trim().isNotEmpty);

  factory SoalAdminItem.fromRow(Map<String, dynamic> row) {
    final opsiRaw = row['opsi'];
    final opsiGambarRaw = row['opsi_gambar'];
    return SoalAdminItem(
      id: row['id'].toString(),
      kuisId: row['kuis_id']?.toString() ?? '',
      pertanyaan: (row['pertanyaan'] as String?)?.trim() ?? '',
      opsi: opsiRaw is List
          ? opsiRaw.map((e) => e.toString()).toList()
          : const <String>[],
      jawabanBenar: (row['jawaban_benar'] as String?)?.trim() ?? '',
      gambarPertanyaan: _teksAtauNull(row['gambar_pertanyaan'] as String?),
      opsiGambar: opsiGambarRaw is List
          ? opsiGambarRaw.map((e) => e.toString()).toList()
          : const <String>[],
      penjelasan: (row['penjelasan'] as String?)?.trim() ?? '',
      urutan: (row['urutan'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Satu baris `banner_promo`.
class BannerItem {
  final String id;
  final String judul;
  final bool aktif;

  const BannerItem({
    required this.id,
    required this.judul,
    required this.aktif,
  });
}

/// Satu baris `log_admin`.
class LogItem {
  final String id;
  final String adminNama;
  final String aksi;
  final DateTime? dibuat;

  const LogItem({
    required this.id,
    required this.adminNama,
    required this.aksi,
    this.dibuat,
  });

  String get waktu => formatWaktu(dibuat);
}

/// Ubah tanggal ISO menjadi teks relatif singkat berbahasa Indonesia.
String formatWaktu(DateTime? waktu) {
  if (waktu == null) return '-';
  final local = waktu.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year}';
}

/// Hasil baca tabel opsional: [data] kosong bila tabel belum ada di server.
class AdminList<T> {
  final List<T> data;
  final bool tabelTersedia;

  const AdminList(this.data, {required this.tabelTersedia});

  static const AdminList<Never> kosongBelumSiap =
      AdminList<Never>([], tabelTersedia: false);
}

/// Service seluruh halaman admin: ringkasan, laporan, media, pengguna,
/// materi, kuis, banner, broadcast, dan log.
class AdminService {
  final SupabaseClient? _customClient;

  AdminService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? get _adminId => _safeClient?.auth.currentUser?.id;

  SupabaseClient _requireClient() {
    final client = _safeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }
    return client;
  }

  // ===== Ringkasan =====

  Future<AdminRingkasan> fetchRingkasan() async {
    final client = _requireClient();
    final pengguna = await _count(client, 'profiles');
    final materi = await _count(client, 'materi');
    final kuis = await _count(client, 'kuis');
    final laporan = await _selectOptional(client, 'laporan');
    final media = await _selectOptional(client, 'review_media');

    final laporanBaru = laporan
        .where((r) => ((r['status'] as String?) ?? 'baru') == 'baru')
        .length;
    final laporanChat = laporan
        .where((r) =>
            ((r['tipe'] as String?) ?? '') == 'chat' &&
            ((r['status'] as String?) ?? 'baru') == 'baru')
        .length;
    final reviewMenunggu = media
        .where((r) => ((r['status'] as String?) ?? 'menunggu') == 'menunggu')
        .length;

    return AdminRingkasan(
      totalPengguna: pengguna,
      laporanBaru: laporanBaru,
      laporanChat: laporanChat,
      reviewMenunggu: reviewMenunggu,
      totalMateri: materi,
      totalKuis: kuis,
    );
  }

  // ===== Laporan & moderasi =====

  Future<AdminList<LaporanItem>> fetchLaporan({String? tipe}) async {
    final client = _requireClient();
    final rows = await _selectOptional(client, 'laporan', order: 'created_at');
    if (rows.isEmpty) {
      return AdminList(const [],
          tabelTersedia: await _tabelAda(client, 'laporan'));
    }
    final items = rows.map(LaporanItem.fromRow).where((l) {
      if (tipe == null) return true;
      return l.tipe == tipe;
    }).toList();
    return AdminList(items, tabelTersedia: true);
  }

  Future<void> ubahStatusLaporan(String id, String status) async {
    final client = _requireClient();
    await client.from('laporan').update({'status': status}).eq('id', id);
  }

  Future<AdminList<MediaItem>> fetchMedia() async {
    final client = _requireClient();
    final rows =
        await _selectOptional(client, 'review_media', order: 'created_at');
    if (rows.isEmpty) {
      return AdminList(const [],
          tabelTersedia: await _tabelAda(client, 'review_media'));
    }
    return AdminList(rows.map(MediaItem.fromRow).toList(), tabelTersedia: true);
  }

  Future<void> ubahStatusMedia(String id, String status) async {
    final client = _requireClient();
    await client.from('review_media').update({'status': status}).eq('id', id);
  }

  // ===== Pengguna & leaderboard =====

  Future<List<PenggunaItem>> fetchPengguna() async {
    final client = _requireClient();
    final rows = await client
        .from('profiles')
        .select('id, full_name, username, role, is_banned, xp, points, streak')
        .order('created_at', ascending: false);
    return rows.map(PenggunaItem.fromRow).toList();
  }

  Future<void> setBanned(String userId, bool banned) async {
    final client = _requireClient();
    await client
        .from('profiles')
        .update({'is_banned': banned}).eq('id', userId);
  }

  Future<void> resetPoin(String userId) async {
    final client = _requireClient();
    await client
        .from('profiles')
        .update({'points': 0, 'xp': 0}).eq('id', userId);
  }

  // ===== Materi & kuis =====

  Future<List<MateriAdminItem>> fetchMateriAdmin() async {
    final client = _requireClient();
    final rows = await client.from('materi').select('*').order('urutan');
    final kuisRows = await client.from('kuis').select('materi_id');
    final hitung = <String, int>{};
    for (final row in kuisRows) {
      final materiId = row['materi_id']?.toString();
      if (materiId == null) continue;
      hitung[materiId] = (hitung[materiId] ?? 0) + 1;
    }
    return rows.map((row) {
      final id = row['id'].toString();
      final gambar = (row['gambar_url'] as String?)?.trim();
      final video = (row['video_url'] as String?)?.trim();
      final kamera = (row['kamera_huruf'] as String?)?.trim();
      return MateriAdminItem(
        id: id,
        judul: (row['judul'] as String?)?.trim() ?? 'Tanpa judul',
        deskripsi: (row['deskripsi'] as String?)?.trim() ?? '',
        urutan: (row['urutan'] as num?)?.toInt() ?? 0,
        published: (row['is_published'] as bool?) ?? true,
        jumlahKuis: hitung[id] ?? 0,
        gambarUrl: (gambar == null || gambar.isEmpty) ? null : gambar,
        videoUrl: (video == null || video.isEmpty) ? null : video,
        kameraHuruf: (kamera == null || kamera.isEmpty) ? null : kamera,
      );
    }).toList();
  }

  Future<void> simpanMateri({
    String? id,
    required String judul,
    required String deskripsi,
    required int urutan,
    String? gambarUrl,
    String? videoUrl,
    String? kameraHuruf,
  }) async {
    final client = _requireClient();
    final payload = <String, dynamic>{
      'judul': judul,
      'deskripsi': deskripsi,
      'urutan': urutan,
      'is_published': true,
      'gambar_url': _teksAtauNull(gambarUrl),
      'video_url': _teksAtauNull(videoUrl),
      'kamera_huruf': _teksAtauNull(kameraHuruf),
    };
    try {
      if (id == null) {
        await client.from('materi').insert(payload);
      } else {
        await client.from('materi').update(payload).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      // Kolom media belum ada: simpan kolom inti saja.
      payload.remove('gambar_url');
      payload.remove('video_url');
      payload.remove('kamera_huruf');
      if (id == null) {
        await client.from('materi').insert(payload);
      } else {
        await client.from('materi').update(payload).eq('id', id);
      }
    }
  }

  Future<void> hapusMateri(String id) async {
    final client = _requireClient();
    await client.from('materi').delete().eq('id', id);
  }

  Future<List<KuisAdminItem>> fetchKuisAdmin() async {
    final client = _requireClient();
    final rows = await client.from('kuis').select('*').order('created_at');
    return _mapKuis(client, rows);
  }

  /// Latihan soal mandiri (kolom `tipe = 'latihan'`), bila kolomnya ada.
  Future<List<KuisAdminItem>> fetchLatihanAdmin() async {
    final client = _requireClient();
    try {
      final rows = await client
          .from('kuis')
          .select('*')
          .eq('tipe', 'latihan')
          .order('created_at');
      return await _mapKuis(client, rows);
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      return const [];
    }
  }

  Future<List<KuisAdminItem>> _mapKuis(
    SupabaseClient client,
    List<dynamic> rows,
  ) async {
    final soalRows = await client.from('soal').select('kuis_id');
    final hitung = <String, int>{};
    for (final row in soalRows) {
      final kuisId = row['kuis_id']?.toString();
      if (kuisId == null) continue;
      hitung[kuisId] = (hitung[kuisId] ?? 0) + 1;
    }
    return rows.map((row) {
      final id = row['id'].toString();
      return KuisAdminItem(
        id: id,
        materiId: row['materi_id']?.toString() ?? '',
        judul: (row['judul'] as String?)?.trim() ?? 'Kuis',
        deskripsi: '',
        xpReward: (row['xp_reward'] as num?)?.toInt() ?? 0,
        jumlahSoal: hitung[id] ?? 0,
        bannerUrl: _teksAtauNull(row['banner_url'] as String?),
        tipe: (row['tipe'] as String?) ?? 'kuis',
      );
    }).toList();
  }

  Future<void> simpanKuis({
    String? id,
    required String materiId,
    required String judul,
    required int xpReward,
    String? bannerUrl,
  }) async {
    final client = _requireClient();
    final payload = <String, dynamic>{
      'materi_id': materiId,
      'judul': judul,
      'xp_reward': xpReward,
      'tipe': 'kuis',
      'banner_url': _teksAtauNull(bannerUrl),
    };
    try {
      if (id == null) {
        await client.from('kuis').insert(payload);
      } else {
        await client.from('kuis').update(payload).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      payload.remove('banner_url');
      try {
        if (id == null) {
          await client.from('kuis').insert(payload);
        } else {
          await client.from('kuis').update(payload).eq('id', id);
        }
      } on PostgrestException catch (e2) {
        if (e2.code != '42703') rethrow;
        payload.remove('tipe');
        if (id == null) {
          await client.from('kuis').insert(payload);
        } else {
          await client.from('kuis').update(payload).eq('id', id);
        }
      }
    }
  }

  /// Membuat kuis beserta seluruh soalnya dalam satu alur wizard.
  ///
  /// Mengembalikan id kuis yang baru dibuat.
  Future<String> buatKuisLengkap({
    required String materiId,
    required String judul,
    required int xpReward,
    String? bannerUrl,
    required List<SoalDraft> soal,
  }) async {
    final client = _requireClient();
    await simpanKuis(
      materiId: materiId,
      judul: judul,
      xpReward: xpReward,
      bannerUrl: bannerUrl,
    );
    final row = await client
        .from('kuis')
        .select('id')
        .eq('judul', judul)
        .order('created_at', ascending: false)
        .limit(1)
        .single();
    final kuisId = row['id'].toString();
    if (soal.isNotEmpty) {
      await client.from('soal').insert([
        for (var i = 0; i < soal.length; i++)
          _payloadSoal(soal[i], kuisId, i + 1),
      ]);
    }
    return kuisId;
  }

  Map<String, dynamic> _payloadSoal(SoalDraft s, String kuisId, int urutan) {
    final gambar = _teksAtauNull(s.gambarPertanyaan);
    return {
      'kuis_id': kuisId,
      'pertanyaan': s.pertanyaan,
      'opsi': s.opsi,
      'jawaban_benar': s.jawabanBenar,
      'gambar_pertanyaan': gambar,
      'opsi_gambar': s.opsiGambar,
      'penjelasan': s.penjelasan,
      'urutan': urutan,
      'tipe': gambar == null ? 'teks' : 'gambar',
    };
  }

  // ===== Bagian materi =====

  /// Daftar bagian satu materi, diurutkan menurut `urutan`.
  ///
  /// Mengembalikan daftar kosong bila tabel `materi_bagian` belum ada.
  Future<List<MateriBagianItem>> fetchBagianMateri(String materiId) async {
    final client = _requireClient();
    try {
      final rows = await client
          .from('materi_bagian')
          .select('*')
          .eq('materi_id', materiId)
          .order('urutan');
      return rows.map(MateriBagianItem.fromRow).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Admin] Bagian materi tidak tersedia: ${e.message}');
      return const [];
    }
  }

  /// Membuat materi beserta bagian-bagiannya dalam satu alur wizard.
  Future<void> buatMateriLengkap({
    required String judul,
    required String deskripsi,
    required int urutan,
    String? gambarUrl,
    String? videoUrl,
    String? kameraHuruf,
    required List<MateriBagianItem> bagian,
  }) async {
    final client = _requireClient();
    await simpanMateri(
      judul: judul,
      deskripsi: deskripsi,
      urutan: urutan,
      gambarUrl: gambarUrl,
      videoUrl: videoUrl,
      kameraHuruf: kameraHuruf,
    );
    final row = await client
        .from('materi')
        .select('id')
        .eq('judul', judul)
        .order('created_at', ascending: false)
        .limit(1)
        .single();
    final materiId = row['id'].toString();
    if (bagian.isEmpty) return;
    await client.from('materi_bagian').insert([
      for (var i = 0; i < bagian.length; i++)
        {
          'materi_id': materiId,
          'urutan': i + 1,
          'judul': bagian[i].judul,
          'isi': bagian[i].isi,
          'foto_url': _teksAtauNull(bagian[i].fotoUrl),
          'video_url': _teksAtauNull(bagian[i].videoUrl),
          if (_teksAtauNull(bagian[i].huruf) != null)
            'huruf': _teksAtauNull(bagian[i].huruf)!.toUpperCase(),
        },
    ]);
  }

  /// Menyimpan satu bagian materi (tambah bila [id] kosong, ubah bila ada).
  Future<void> simpanBagianMateri({
    String? id,
    required String materiId,
    required int urutan,
    required String judul,
    required String isi,
    String? fotoUrl,
    String? videoUrl,
    String? huruf,
  }) async {
    final client = _requireClient();
    final hurufBersih = _teksAtauNull(huruf)?.toUpperCase();
    final payload = <String, dynamic>{
      'materi_id': materiId,
      'urutan': urutan,
      'judul': judul,
      'isi': isi,
      'foto_url': _teksAtauNull(fotoUrl),
      'video_url': _teksAtauNull(videoUrl),
      // Hanya dikirim bila diisi, agar database lama tanpa kolom `huruf`
      // tidak gagal saat menyimpan bagian tanpa huruf.
      if (hurufBersih != null) 'huruf': hurufBersih,
    };
    try {
      if (id == null) {
        await client.from('materi_bagian').insert(payload);
      } else {
        await client.from('materi_bagian').update(payload).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code != '42P01' && e.code != '42703') rethrow;
      throw Exception(
        'Tabel materi_bagian belum tersedia di database. '
        'Jalankan supabase/patch_signl_backend.sql terlebih dahulu.',
      );
    }
  }

  Future<void> hapusBagianMateri(String id) async {
    final client = _requireClient();
    await client.from('materi_bagian').delete().eq('id', id);
  }

  /// Mengunggah media panel admin (foto WebP / video) ke bucket publik.
  ///
  /// Mengembalikan URL publik file.
  Future<String> unggahMedia(
    String pathLokal, {
    String bucket = 'materi-media',
    bool isVideo = false,
  }) async {
    final client = _requireClient();
    final berkas = File(pathLokal);
    if (!berkas.existsSync()) {
      throw Exception('Berkas media tidak ditemukan.');
    }
    final ekstensi = pathLokal.split('.').last.toLowerCase();
    final objectPath =
        'admin/${isVideo ? 'video' : 'foto'}_${DateTime.now().millisecondsSinceEpoch}.$ekstensi';
    try {
      await client.storage.from(bucket).upload(
            objectPath,
            berkas,
            fileOptions: FileOptions(
              contentType: isVideo ? 'video/mp4' : 'image/webp',
              upsert: true,
            ),
          );
      return client.storage.from(bucket).getPublicUrl(objectPath);
    } on StorageException catch (e) {
      debugPrint('[Admin] Gagal mengunggah media: ${e.message}');
      throw Exception(
        'Gagal mengunggah media. Pastikan bucket "$bucket" sudah dibuat '
        'dan akun ini admin.',
      );
    }
  }

  /// Membuat latihan soal mandiri (tidak terikat materi).
  Future<void> simpanLatihan({
    String? id,
    required String judul,
    required int xpReward,
  }) async {
    final client = _requireClient();
    final payload = {
      'judul': judul,
      'xp_reward': xpReward,
      'tipe': 'latihan',
    };
    try {
      if (id == null) {
        await client.from('kuis').insert(payload);
      } else {
        await client.from('kuis').update(payload).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23502') {
        throw Exception(
          'Kolom materi wajib di database. Jalankan '
          'supabase/patch_signl_backend.sql lalu ulangi.',
        );
      }
      rethrow;
    }
  }

  Future<void> hapusKuis(String id) async {
    final client = _requireClient();
    await client.from('kuis').delete().eq('id', id);
  }

  /// Soal satu kuis, diurutkan menurut `urutan` lalu waktu dibuat.
  Future<List<SoalAdminItem>> fetchSoalAdmin(String kuisId) async {
    final client = _requireClient();
    try {
      final rows = await client
          .from('soal')
          .select('*')
          .eq('kuis_id', kuisId)
          .order('urutan')
          .order('created_at');
      return rows.map(SoalAdminItem.fromRow).toList();
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      final rows = await client
          .from('soal')
          .select('id, kuis_id, pertanyaan, opsi, jawaban_benar')
          .eq('kuis_id', kuisId)
          .order('created_at');
      return rows.map(SoalAdminItem.fromRow).toList();
    }
  }

  Future<void> simpanSoal({
    String? id,
    required String kuisId,
    required String pertanyaan,
    required List<String> opsi,
    required String jawabanBenar,
    String? gambarPertanyaan,
    List<String> opsiGambar = const [],
    String penjelasan = '',
    int urutan = 0,
  }) async {
    final client = _requireClient();
    if (id == null) {
      final ada = await client.from('soal').select('id').eq('kuis_id', kuisId);
      if (ada.length >= maksSoalPerKuis) {
        throw Exception(
          'Kuis ini sudah mencapai batas $maksSoalPerKuis soal. '
          'Hapus soal lain sebelum menambah.',
        );
      }
    }
    final tipe = (gambarPertanyaan != null && gambarPertanyaan.isNotEmpty)
        ? 'gambar'
        : 'teks';
    final payload = <String, dynamic>{
      'kuis_id': kuisId,
      'pertanyaan': pertanyaan,
      'opsi': opsi,
      'jawaban_benar': jawabanBenar,
      'gambar_pertanyaan': _teksAtauNull(gambarPertanyaan),
      'opsi_gambar': opsiGambar,
      'penjelasan': penjelasan,
      'urutan': urutan,
      'tipe': tipe,
    };
    try {
      if (id == null) {
        await client.from('soal').insert(payload);
      } else {
        await client.from('soal').update(payload).eq('id', id);
      }
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      throw Exception(
        'Kolom media soal belum tersedia di database. '
        'Jalankan supabase/patch_signl_backend.sql terlebih dahulu.',
      );
    }
  }

  Future<void> hapusSoal(String id) async {
    final client = _requireClient();
    await client.from('soal').delete().eq('id', id);
  }

  // ===== Balasan laporan =====

  /// Membuat/melanjutkan percakapan dengan pelapor lalu mengirim balasan
  /// template dari admin. Percakapan bersifat hanya-baca bagi pelapor.
  ///
  /// Mengembalikan id percakapan yang dipakai.
  Future<String> balasLaporan({
    required LaporanItem laporan,
    required String template,
    required String alasan,
  }) async {
    final client = _requireClient();
    final adminId = _adminId;

    final pelaporId = await _cariPelaporId(client, laporan.pelapor);
    if (pelaporId == null) {
      throw Exception(
        'Akun pelapor "${laporan.pelapor}" tidak ditemukan di profil. '
        'Balasan tidak dapat dikirim.',
      );
    }

    final isi = template == 'ditolak'
        ? (alasan.trim().isEmpty
            ? 'Laporan ditolak.'
            : 'Laporan ditolak — alasan: ${alasan.trim()}')
        : (alasan.trim().isEmpty
            ? 'Laporan sudah dieksekusi.'
            : 'Laporan sudah dieksekusi. Catatan admin: ${alasan.trim()}');

    final lama = await client
        .from('conversations')
        .select('id')
        .eq('laporan_id', laporan.id)
        .limit(1);
    final lamaId = lama.isEmpty ? null : lama.first['id']?.toString();

    final String conversationId;
    if (lamaId == null) {
      final row = await client
          .from('conversations')
          .insert({
            'user_id': pelaporId,
            'admin_id': adminId,
            'laporan_id': laporan.id,
            'judul': 'Laporan ${laporan.alasan}',
            'last_message': isi,
            'last_message_at': DateTime.now().toUtc().toIso8601String(),
            'unread_count': 1,
            'is_read_only': true,
          })
          .select('id')
          .single();
      conversationId = row['id'].toString();
    } else {
      conversationId = lamaId;
      await client.from('conversations').update({
        'last_message': isi,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
        'unread_count': 1,
        'admin_id': adminId,
      }).eq('id', conversationId);
    }

    await client.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': adminId,
      'isi': isi,
      'dari_admin': true,
    });

    await client.from('laporan').update({
      'status': 'dibalas',
      'balasan': isi,
      'alasan_balasan': alasan.trim(),
      'dibalas_at': DateTime.now().toUtc().toIso8601String(),
      'conversation_id': conversationId,
    }).eq('id', laporan.id);

    await catatLog(
      template == 'ditolak'
          ? 'Menolak laporan "${laporan.alasan}" dari ${laporan.pelapor}'
          : 'Mengeksekusi laporan "${laporan.alasan}" dari ${laporan.pelapor}',
    );
    return conversationId;
  }

  Future<String?> _cariPelaporId(SupabaseClient client, String nama) async {
    final bersih = nama.trim();
    if (bersih.isEmpty) return null;
    try {
      final rows = await client
          .from('profiles')
          .select('id')
          .ilike('full_name', bersih)
          .limit(1);
      if (rows.isNotEmpty) return rows.first['id']?.toString();
      final username = await client
          .from('profiles')
          .select('id')
          .ilike('username', bersih)
          .limit(1);
      if (username.isNotEmpty) return username.first['id']?.toString();
    } catch (e) {
      debugPrint('[Admin] Gagal mencari pelapor: $e');
    }
    return null;
  }

  // ===== Banner, broadcast, log =====

  Future<AdminList<BannerItem>> fetchBanner() async {
    final client = _requireClient();
    final rows =
        await _selectOptional(client, 'banner_promo', order: 'created_at');
    if (rows.isEmpty) {
      return AdminList(const [],
          tabelTersedia: await _tabelAda(client, 'banner_promo'));
    }
    return AdminList(
      rows
          .map((row) => BannerItem(
                id: row['id'].toString(),
                judul: (row['judul'] as String?)?.trim() ?? 'Banner',
                aktif: (row['aktif'] as bool?) ?? true,
              ))
          .toList(),
      tabelTersedia: true,
    );
  }

  Future<void> setBannerAktif(String id, bool aktif) async {
    final client = _requireClient();
    await client.from('banner_promo').update({'aktif': aktif}).eq('id', id);
  }

  Future<void> simpanBanner(String judul) async {
    final client = _requireClient();
    await client.from('banner_promo').insert({'judul': judul, 'aktif': true});
  }

  Future<void> hapusBanner(String id) async {
    final client = _requireClient();
    await client.from('banner_promo').delete().eq('id', id);
  }

  Future<AdminList<LogItem>> fetchLog() async {
    final client = _requireClient();
    final rows =
        await _selectOptional(client, 'log_admin', order: 'created_at');
    if (rows.isEmpty) {
      return AdminList(const [],
          tabelTersedia: await _tabelAda(client, 'log_admin'));
    }
    return AdminList(
      rows
          .map((row) => LogItem(
                id: row['id'].toString(),
                adminNama: (row['admin_nama'] as String?) ?? 'Admin',
                aksi: (row['aksi'] as String?) ?? '-',
                dibuat: DateTime.tryParse((row['created_at'] as String?) ?? ''),
              ))
          .toList(),
      tabelTersedia: true,
    );
  }

  /// Kirim pengumuman: disimpan ke `broadcast_notifikasi` lalu didistribusikan
  /// ke `notifications` milik setiap pengguna yang cocok dengan target.
  Future<int> kirimBroadcast({
    required String judul,
    required String isi,
    required String target,
  }) async {
    final client = _requireClient();

    await client.from('broadcast_notifikasi').insert({
      'judul': judul,
      'isi': isi,
      'target': target,
      'created_by': _adminId,
    });

    final profiles = await client.from('profiles').select('id, role');
    final ids = profiles
        .where((row) {
          final role = (row['role'] as String?) ?? 'user';
          if (target == 'Hanya Mentor Tuli') return role == 'mentor';
          if (target == 'Hanya Pembelajar') return role == 'user';
          return true;
        })
        .map((row) => row['id'].toString())
        .toList();

    if (ids.isEmpty) return 0;

    final payload = ids
        .map((id) => {
              'user_id': id,
              'title': judul,
              'body': isi,
              'category': 'pengumuman',
              'target': 'learning',
            })
        .toList();
    await client.from('notifications').insert(payload);
    await catatLog('Mengirim broadcast "$judul" ke $target');
    return ids.length;
  }

  /// Mencatat aksi admin ke `log_admin`.
  Future<void> catatLog(String aksi) async {
    final client = _safeClient;
    final adminId = _adminId;
    if (client == null || adminId == null) return;
    try {
      String adminNama = 'Admin';
      try {
        final row = await client
            .from('profiles')
            .select('full_name, username')
            .eq('id', adminId)
            .maybeSingle();
        final nama = (row?['full_name'] as String?)?.trim();
        final username = (row?['username'] as String?)?.trim();
        if (nama != null && nama.isNotEmpty) {
          adminNama = nama;
        } else if (username != null && username.isNotEmpty) {
          adminNama = username;
        }
      } catch (e) {
        debugPrint('[Admin] Gagal membaca nama admin: $e');
      }
      await client.from('log_admin').insert({
        'admin_id': adminId,
        'admin_nama': adminNama,
        'aksi': aksi,
      });
    } on PostgrestException catch (e) {
      debugPrint('[Admin] Gagal menulis log: ${e.message}');
    } catch (e) {
      debugPrint('[Admin] Gagal menulis log: $e');
    }
  }

  // ===== Helper =====

  Future<int> _count(SupabaseClient client, String table) async {
    try {
      final data = await client.from(table).select('id');
      return data.length;
    } catch (e) {
      debugPrint('[Admin] Gagal menghitung $table: $e');
      return 0;
    }
  }

  Future<bool> _tabelAda(SupabaseClient client, String table) async {
    try {
      await client.from(table).select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _selectOptional(
    SupabaseClient client,
    String table, {
    String? order,
  }) async {
    try {
      var query = client.from(table).select('*');
      final data = order == null ? await query : await query.order(order);
      return data.cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      debugPrint('[Admin] $table tidak tersedia: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('[Admin] $table tidak tersedia: $e');
      return const [];
    }
  }
}
