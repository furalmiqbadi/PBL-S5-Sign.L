import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bab_model.dart';
import '../models/materi_model.dart';

/// Service Layer untuk mengakses data Materi, Bab, dan Kuis dari Supabase.
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

  /// Mengambil daftar Bab materi pembelajaran dari tabel `materi` di Supabase.
  Future<List<Bab>> getBabList() async {
    final client = _safeClient;
    if (client == null) return dummyBabList;

    try {
      final rows = await client
          .from('materi')
          .select('*, kuis(*)')
          .order('urutan', ascending: true);

      if (rows.isEmpty) return dummyBabList;

      final List<Bab> babList = [];
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final urutan = (row['urutan'] as num?)?.toInt() ?? (i + 1);
        final kuisList = row['kuis'] as List? ?? [];
        final totalMateri = kuisList.isNotEmpty ? kuisList.length : 5;

        BabStatus status;
        double progress;
        int completedMateri;

        if (urutan == 1) {
          status = BabStatus.inProgress;
          progress = 0.65;
          completedMateri = (totalMateri * progress).round();
        } else if (urutan == 2) {
          status = BabStatus.available;
          progress = 0.0;
          completedMateri = 0;
        } else {
          status = BabStatus.locked;
          progress = 0.0;
          completedMateri = 0;
        }

        babList.add(Bab(
          id: urutan,
          number: urutan.toString().padLeft(2, '0'),
          title: (row['judul'] as String?) ?? 'Bab $urutan',
          subtitle: status == BabStatus.inProgress
              ? 'Bab $urutan • Sedang Berjalan'
              : (status == BabStatus.available
                  ? 'Bab $urutan • Siap Dimulai'
                  : 'Terkunci • Prasyarat Bab ${urutan - 1}'),
          description: (row['deskripsi'] as String?) ?? 'Materi isyarat BISINDO',
          totalMateri: totalMateri,
          completedMateri: completedMateri,
          durationMinutes: 15 + (urutan * 5),
          status: status,
          progress: progress,
        ));
      }

      return babList;
    } catch (e) {
      debugPrint('[MateriService] Gagal fetch materi dari Supabase: $e');
      return dummyBabList;
    }
  }

  /// Mengambil daftar kuis dan soal dari Supabase.
  Future<List<Map<String, dynamic>>> getKuisList() async {
    final client = _safeClient;
    if (client == null) return [];

    try {
      final rows = await client
          .from('kuis')
          .select('*, soal(*)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[MateriService] Gagal fetch kuis: $e');
      return [];
    }
  }

  /// Mengambil data detail materi (Section) dari Supabase.
  Future<List<Materi>> getDetailMateriList() async {
    final client = _safeClient;
    if (client == null) return dummyMateriList;

    try {
      final kuisRows = await client
          .from('kuis')
          .select('*, soal(*)')
          .order('created_at', ascending: true);

      if (kuisRows.isEmpty) return dummyMateriList;

      final List<Materi> list = [];
      for (int i = 0; i < kuisRows.length; i++) {
        final k = kuisRows[i];
        final soalList = k['soal'] as List? ?? [];
        final count = soalList.isNotEmpty ? soalList.length : 5;
        final xp = (k['xp_reward'] as num?)?.toInt() ?? 50;

        MateriStatus status;
        double progress;
        int completed;

        if (i == 0) {
          status = MateriStatus.completed;
          progress = 1.0;
          completed = count;
        } else if (i == 1) {
          status = MateriStatus.inProgress;
          progress = 0.6;
          completed = (count * 0.6).round();
        } else {
          status = MateriStatus.locked;
          progress = 0.0;
          completed = 0;
        }

        list.add(Materi(
          id: i + 1,
          title: (k['judul'] as String?) ?? 'Pelajaran ${i + 1}',
          subtitle: status == MateriStatus.completed
              ? '$count Gestur selesai • Akurasi gestur 98%'
              : (status == MateriStatus.inProgress
                  ? 'Transisi kelenturan jari & pemahaman ekspresif.'
                  : '$count Gerakan baru • Belum dimulai'),
          description: (k['judul'] as String?) ?? '',
          totalGestures: count,
          completedGestures: completed,
          xpReward: xp,
          status: status,
          progress: progress,
          isQuiz: true,
        ));
      }

      return list;
    } catch (e) {
      debugPrint('[MateriService] Gagal fetch detail materi: $e');
      return dummyMateriList;
    }
  }
}

