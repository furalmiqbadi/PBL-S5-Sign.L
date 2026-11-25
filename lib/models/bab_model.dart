import 'package:flutter/material.dart';

import '../views/theme/app_colors.dart';
import 'gestur_model.dart';

/// Status tampilan sebuah bab/materi di tab Materi.
enum BabStatus { locked, inProgress, completed, available }

/// Satu baris tabel `materi` di Supabase, siap dipakai widget tab Materi.
///
/// Progres belajar dibaca dari tabel `progres_materi` (jumlah huruf yang
/// dipelajari) dan hasil kuis dari `hasil_kuis`.
class Bab {
  /// UUID materi di Supabase.
  final String id;
  final int urutan;
  final String title;
  final String description;
  final bool isPublished;

  /// Jumlah butir yang bisa diselesaikan pada bagian utama: jumlah huruf
  /// tersedia untuk materi alfabet, atau jumlah kuis untuk materi lain.
  final int totalMateri;

  /// Jumlah butir utama yang sudah diselesaikan pengguna.
  final int completedMateri;

  /// Satuan dari [totalMateri] (`Huruf` atau `Kuis`).
  final String metaUnit;

  /// Jumlah kuis yang terdaftar untuk materi ini.
  final int kuisTotal;

  /// Jumlah kuis materi ini yang sudah dikerjakan pengguna.
  final int kuisSelesai;

  final BabStatus status;

  /// URL gambar materi (opsional).
  final String? gambarUrl;

  /// URL video materi (opsional).
  final String? videoUrl;

  /// Huruf target latihan kamera, mis. `A` (opsional).
  final String? kameraHuruf;

  const Bab({
    required this.id,
    required this.urutan,
    required this.title,
    required this.description,
    required this.isPublished,
    required this.totalMateri,
    required this.completedMateri,
    required this.metaUnit,
    required this.status,
    this.kuisTotal = 0,
    this.kuisSelesai = 0,
    this.gambarUrl,
    this.videoUrl,
    this.kameraHuruf,
  });

  bool get adaGambar => gambarUrl != null && gambarUrl!.isNotEmpty;
  bool get adaVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get adaKamera => kameraHuruf != null && kameraHuruf!.isNotEmpty;

  /// Nomor tampilan dua digit (`01`, `02`, ...).
  String get number => urutan.toString().padLeft(2, '0');

  String get subtitle => switch (status) {
        BabStatus.completed => 'Bab $number • Selesai',
        BabStatus.inProgress => 'Bab $number • Sedang Berjalan',
        BabStatus.available => 'Bab $number • Siap Dimulai',
        BabStatus.locked => 'Terkunci • Prasyarat bab sebelumnya',
      };

  double get progress {
    if (totalMateri <= 0) return 0;
    return (completedMateri / totalMateri).clamp(0.0, 1.0);
  }

  String get progressText =>
      '$completedMateri dari $totalMateri ${metaUnit.toLowerCase()}';

  bool get isLocked => status == BabStatus.locked;
  bool get isInProgress => status == BabStatus.inProgress;
  bool get isCompleted => status == BabStatus.completed;

  /// Materi alfabet punya latihan huruf; materi lain hanya kuis.
  bool get hasLetterPractice => metaUnit == 'Huruf';

  static const _alfabetKeys = ['abjad', 'alfabet', 'alphabet'];

  /// Membuat [Bab] dari baris Supabase. [previousCompleted] dipakai untuk
  /// menentukan status terkunci berurutan (prasyarat bab sebelumnya).
  factory Bab.fromRow(
    Map<String, dynamic> row, {
    required int hurufDipelajari,
    required int kuisCount,
    required int kuisSelesai,
    required bool previousCompleted,
  }) {
    final judul = (row['judul'] as String?)?.trim() ?? 'Tanpa judul';
    final lower = judul.toLowerCase();
    final isAlphabet = _alfabetKeys.any(lower.contains);
    final published = row['is_published'] as bool? ?? true;
    // Materi alfabet hanya menghitung huruf yang benar-benar punya materi
    // latihan, supaya progres bisa mencapai 100%.
    final total = isAlphabet ? hurufAlfabet.length : kuisCount;
    final done = (isAlphabet ? hurufDipelajari : kuisSelesai).clamp(0, total);
    final isDone = total > 0 && done >= total;

    final BabStatus status;
    if (!published) {
      status = BabStatus.locked;
    } else if (isDone) {
      status = BabStatus.completed;
    } else if (done > 0) {
      status = BabStatus.inProgress;
    } else if (previousCompleted) {
      status = BabStatus.available;
    } else {
      status = BabStatus.locked;
    }

    final gambar = (row['gambar_url'] as String?)?.trim();
    final video = (row['video_url'] as String?)?.trim();
    final kamera = (row['kamera_huruf'] as String?)?.trim();

    return Bab(
      id: row['id'].toString(),
      urutan: (row['urutan'] as num?)?.toInt() ?? 1,
      title: judul,
      description: (row['deskripsi'] as String?)?.trim() ?? '',
      isPublished: published,
      totalMateri: total,
      completedMateri: done,
      metaUnit: isAlphabet ? 'Huruf' : 'Kuis',
      kuisTotal: kuisCount,
      kuisSelesai: kuisSelesai.clamp(0, kuisCount),
      status: status,
      gambarUrl: (gambar == null || gambar.isEmpty) ? null : gambar,
      videoUrl: (video == null || video.isEmpty) ? null : video,
      kameraHuruf:
          (kamera == null || kamera.isEmpty) ? null : kamera.toUpperCase(),
    );
  }
}

/// Label status yang dipakai kartu materi.
String babStatusLabel(BabStatus status) => switch (status) {
      BabStatus.completed => 'Selesai',
      BabStatus.inProgress => 'Berjalan',
      BabStatus.available => 'Baru',
      BabStatus.locked => 'Terkunci',
    };

/// Warna aksen status kartu materi.
Color babStatusColor(BabStatus status) => switch (status) {
      BabStatus.completed => AppColors.secondary,
      BabStatus.inProgress => AppColors.primary,
      BabStatus.available => AppColors.tertiary,
      BabStatus.locked => AppColors.textMuted,
    };
