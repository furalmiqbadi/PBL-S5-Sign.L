import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../../models/gestur_model.dart';
import 'admin_detail_pages.dart';

/// Tampilan pratinjau kuis dan bagian materi.
///
/// Dipakai bersama oleh wizard (langkah preview) dan halaman edit, sehingga
/// hasil pratinjau identik dengan isi yang akan disimpan.

String hurufOpsi(int indeks) => String.fromCharCode(65 + indeks);

/// Kotak huruf pilihan; disorot bila menjadi jawaban benar.
Widget kotakHuruf(String huruf, bool benar) {
  return Container(
    width: 32,
    height: 32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: benar ? AppColors.successSoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.sm),
    ),
    child: Text(
      huruf,
      style: AppTextStyles.labelLarge.copyWith(
        color: benar ? AppColors.success : AppColors.textSecondary,
      ),
    ),
  );
}

/// Kartu judul + subjudul pada halaman pratinjau.
Widget kartuInfo({
  String? gambarUrl,
  String? gambarLokal,
  double gambarTinggi = 160,
  required String judul,
  String? deskripsi,
  required String meta,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (gambarUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: gambarPratinjau(
            lokal: gambarLokal,
            url: gambarUrl,
            tinggi: gambarTinggi,
          ),
        ),
        const SizedBox(height: 12),
      ],
      Text(
        judul,
        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
      ),
      if (deskripsi != null && deskripsi.trim().isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          deskripsi.trim(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
      const SizedBox(height: 4),
      Text(
        meta,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
      ),
    ],
  );
}

/// Gambar dari berkas lokal bila ada, selain itu dari URL jaringan.
Widget gambarPratinjau({
  required String? lokal,
  required String url,
  required double tinggi,
}) {
  final file = lokal == null ? null : File(lokal);
  if (file != null && file.existsSync()) {
    return Image.file(
      file,
      height: tinggi,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
  return Image.network(
    url,
    height: tinggi,
    width: double.infinity,
    fit: BoxFit.cover,
  );
}

/// Kartu pertanyaan + pilihan jawaban beserta kunci jawaban.
Widget kartuSoalPratinjau({
  required int nomor,
  required String pertanyaan,
  required List<String> opsi,
  required int jawaban,
  String? gambarUrl,
  String? gambarLokal,
  String penjelasan = '',
}) {
  return itemCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Soal $nomor',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            AppStatusBadge(
              label: 'Jawaban ${hurufOpsi(jawaban)}',
              color: AppColors.success,
              backgroundColor: AppColors.successSoft,
            ),
          ],
        ),
        if (pertanyaan.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(pertanyaan.trim(), style: AppTextStyles.bodyMedium),
        ],
        if (gambarUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: gambarPratinjau(
              lokal: gambarLokal,
              url: gambarUrl,
              tinggi: 120,
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (var i = 0; i < opsi.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kotakHuruf(hurufOpsi(i), jawaban == i),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opsi[i].trim().isEmpty ? '(kosong)' : opsi[i].trim(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: jawaban == i
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight:
                          jawaban == i ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (penjelasan.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              'Penjelasan: ${penjelasan.trim()}',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Pemilih kelas huruf untuk satu bagian materi.
///
/// Setiap bagian mewakili satu kelas huruf (mis. `A`), sehingga kamera bisa
/// menampilkan isi bagian yang cocok saat huruf itu terdeteksi.
Widget pemilihHuruf({
  required String? nilai,
  required ValueChanged<String?> onChanged,
  bool aktif = true,
}) {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final h in hurufLatihan)
        ChoiceChip(
          label: Text(h),
          selected: nilai == h,
          onSelected: aktif ? (_) => onChanged(nilai == h ? null : h) : null,
          showCheckmark: false,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: nilai == h ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: nilai == h ? FontWeight.w700 : FontWeight.w500,
          ),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceMuted,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
    ],
  );
}

/// Kartu satu bagian materi: judul, isi, foto, dan penanda video.
Widget kartuBagianPratinjau({
  required int nomor,
  required String judul,
  required String isi,
  String? fotoUrl,
  String? fotoLokal,
  String? videoUrl,
  String? videoLokal,
  String? huruf,
}) {
  return itemCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bagian $nomor${judul.trim().isEmpty ? '' : ' • ${judul.trim()}'}',
                style: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (huruf != null && huruf.isNotEmpty)
              AppStatusBadge(
                label: 'Kelas $huruf',
                color: AppColors.primary,
                backgroundColor: AppColors.pinkSoft,
              ),
          ],
        ),
        if (isi.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(isi.trim(), style: AppTextStyles.bodySmall),
        ],
        if (fotoUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: gambarPratinjau(
              lokal: fotoLokal,
              url: fotoUrl,
              tinggi: 120,
            ),
          ),
        ],
        if (videoUrl != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  videoLokal == null ? 'Video tersedia' : 'Video siap diunggah',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
