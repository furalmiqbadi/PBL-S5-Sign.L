import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/final_exam_card.dart';
import 'quiz_page.dart';

/// Konten tab Kuis: daftar kuis dari tabel `kuis` di Supabase (yang dikelola
/// lewat halaman admin "Management Kuis").
///
/// Tiap kartu membuka [QuizPage] sesuai `kuis.id`. Kuis yang belum punya soal
/// ditampilkan redup dan tombolnya dinonaktifkan.
class KuisPage extends StatefulWidget {
  const KuisPage({super.key});

  @override
  State<KuisPage> createState() => _KuisPageState();
}

/// Data satu kuis untuk ditampilkan di kartu.
class _KuisItem {
  final String id;
  final String judul;
  final int xpReward;
  final int jumlahSoal;
  final String? materi;

  /// User sudah pernah lulus kuis ini (ada hasil dengan skor >= [skorLulus]).
  final bool sudahLulus;

  /// Kuis boleh dibuka (kuis sebelumnya di materi yang sama sudah lulus).
  final bool terbuka;

  const _KuisItem({
    required this.id,
    required this.judul,
    required this.xpReward,
    required this.jumlahSoal,
    required this.materi,
    required this.sudahLulus,
    required this.terbuka,
  });

  /// Sudah punya soal di database.
  bool get punyaSoal => jumlahSoal > 0;

  /// Bisa dimainkan sekarang.
  bool get tersedia => punyaSoal && terbuka;

  /// XP per soal benar (sama dengan perhitungan di [QuizPage]).
  int get totalXp => xpReward * jumlahSoal;

  /// Estimasi durasi: sekitar 1 menit per soal.
  String get durasiText => '±$jumlahSoal mnt';
}

class _KuisPageState extends State<KuisPage> {
  late Future<List<_KuisItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _ambil();
  }

  Future<List<_KuisItem>> _ambil() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // 1. Daftar kuis
    final List<dynamic> rows = await client
        .from('kuis')
        .select(
            'id, judul, xp_reward, created_at, materi(judul, urutan), soal(count)')
        .eq('tipe', 'kuis');

    // Urutkan: pertama menurut `materi.urutan` (Abjad dulu, lalu Sapaan),
    // lalu menurut waktu dibuat di dalam materi yang sama (A-E, F-J, ...).
    int urutanMateri(dynamic r) {
      final materi = r['materi'];
      return (materi is Map ? materi['urutan'] as int? : null) ?? 1 << 30;
    }

    rows.sort((a, b) {
      final byMateri = urutanMateri(a).compareTo(urutanMateri(b));
      if (byMateri != 0) return byMateri;
      return '${a['created_at']}'.compareTo('${b['created_at']}');
    });

    // 2. Kuis yang sudah lulus oleh user ini
    final lulus = <String>{};
    if (user != null) {
      final List<dynamic> hasil = await client
          .from('hasil_kuis')
          .select('kuis_id')
          .eq('user_id', user.id)
          .gte('skor', skorLulus);
      lulus.addAll(hasil.map((h) => h['kuis_id'] as String));
    }

    // 3. Tentukan kunci berurutan: hanya kuis pertama yang terbuka, kuis
    //    berikutnya terbuka bila kuis sebelumnya sudah lulus.
    //    Kuis tanpa soal dilewati agar tidak memblokir rantai.
    var bolehBuka = true; // apakah kuis berikutnya boleh dibuka?
    final items = <_KuisItem>[];

    for (final r in rows) {
      final m = Map<String, dynamic>.from(r as Map);
      final id = m['id'] as String;
      final soal = m['soal'] as List?;
      final materi = m['materi'];
      final jumlahSoal = (soal?.firstOrNull?['count'] as int?) ?? 0;
      final sudahLulus = lulus.contains(id);

      var terbuka = false;
      if (jumlahSoal > 0) {
        terbuka = bolehBuka;
        bolehBuka = terbuka && sudahLulus;
      }

      items.add(_KuisItem(
        id: id,
        judul: (m['judul'] as String?) ?? 'Kuis',
        xpReward: (m['xp_reward'] as int?) ?? 10,
        jumlahSoal: jumlahSoal,
        materi: materi is Map ? materi['judul'] as String? : null,
        sudahLulus: sudahLulus,
        terbuka: terbuka,
      ));
    }

    return items;
  }

  Future<void> _refresh() async {
    final f = _ambil();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  Future<void> _buka(_KuisItem k) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizPage(kuisId: k.id)),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_KuisItem>>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final daftar = snap.data ?? const <_KuisItem>[];
        final tersedia = daftar.where((k) => k.tersedia).length;

        if (snap.hasError) {
          debugPrint('Gagal memuat daftar kuis: ${snap.error}');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _KuisSummaryCard(
                keterangan: loading
                    ? 'Memuat daftar kuis...'
                    : '$tersedia dari ${daftar.length} kuis tersedia untukmu.',
              ),
              const SizedBox(height: 24),
              Text('Kuis per Materi', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (snap.hasError)
                _pesan(
                  'Gagal memuat daftar kuis. Periksa koneksi internet kamu.',
                  aksi: TextButton(
                    onPressed: _refresh,
                    child: const Text('Coba Lagi'),
                  ),
                )
              else if (daftar.isEmpty)
                _pesan('Belum ada kuis.')
              else
                for (var i = 0; i < daftar.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _QuizKuisCard(
                      nomor: '${i + 1}',
                      item: daftar[i],
                      onStart:
                          daftar[i].tersedia ? () => _buka(daftar[i]) : null,
                    ),
                  ),
              const SizedBox(height: 8),
              Text('Evaluasi Akhir', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              const FinalExamCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _pesan(String teks, {Widget? aksi}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                teks,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (aksi != null) aksi,
            ],
          ),
        ),
      );
}

/// Kartu ringkasan di atas daftar kuis.
class _KuisSummaryCard extends StatelessWidget {
  final String keterangan;

  const _KuisSummaryCard({required this.keterangan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.quiz_rounded, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UJI PEMAHAMAN',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kuis & Evaluasi',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  keterangan,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu untuk satu kuis dari Supabase.
class _QuizKuisCard extends StatelessWidget {
  final String nomor;
  final _KuisItem item;
  final VoidCallback? onStart;

  const _QuizKuisCard({
    required this.nomor,
    required this.item,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !item.tersedia;
    final metaColor = locked ? AppColors.textMuted : AppColors.textSecondary;

    final String deskripsi;
    final String labelTombol;
    if (!item.punyaSoal) {
      deskripsi = 'Soal untuk kuis ini belum tersedia.';
      labelTombol = 'Belum Tersedia';
    } else if (!item.terbuka) {
      deskripsi =
          'Selesaikan kuis sebelumnya dengan skor minimal $skorLulus untuk membuka kuis ini.';
      labelTombol = 'Terkunci';
    } else if (item.sudahLulus) {
      deskripsi = 'Kamu sudah lulus kuis ini. Ulangi untuk melatih ingatanmu.';
      labelTombol = 'Ulangi Kuis';
    } else {
      deskripsi =
          'Kerjakan ${item.jumlahSoal} soal pilihan ganda untuk menguji pemahamanmu.';
      labelTombol = 'Mulai Kuis';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: locked ? AppColors.fieldFill : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _numberBadge(nomor, !locked),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.materi ?? 'Kuis $nomor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: locked ? AppColors.textMuted : AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: locked ? AppColors.textSecondary : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                const Icon(Icons.lock, size: 16, color: AppColors.textMuted)
              else if (item.sudahLulus)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            deskripsi,
            style: AppTextStyles.bodySmall.copyWith(
              color: locked ? AppColors.textMuted : null,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.quiz_outlined, '${item.jumlahSoal} Soal', metaColor),
              const SizedBox(width: 16),
              _meta(Icons.access_time, item.durasiText, metaColor),
              const SizedBox(width: 16),
              _diamondMeta(
                '+${item.totalXp}',
                locked ? AppColors.textMuted : AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    locked
                        ? Icons.lock_outline
                        : (item.sudahLulus
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labelTombol,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberBadge(String number, bool active) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.pinkSoft : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.labelXSmall.copyWith(color: color)),
      ],
    );
  }

  Widget _diamondMeta(String text, Color color) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/diamond_fix.svg',
          width: 13,
          height: 13,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.labelXSmall.copyWith(color: color)),
      ],
    );
  }
}