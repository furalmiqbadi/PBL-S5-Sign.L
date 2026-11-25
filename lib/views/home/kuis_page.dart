import 'package:flutter/material.dart';

import '../../services/kuis_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import 'quiz_page.dart';

/// Konten tab Kuis: daftar kuis nyata dari tabel `kuis` di Supabase.
///
/// Tiap kartu membuka [QuizPage]. Kuis tanpa soal ditampilkan redup dan
/// tombolnya dinonaktifkan.
class KuisPage extends StatefulWidget {
  const KuisPage({super.key});

  @override
  State<KuisPage> createState() => _KuisPageState();
}

class _KuisPageState extends State<KuisPage> {
  final KuisService _service = KuisService();

  List<KuisInfo> _kuis = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final kuis = await _service.fetchDaftarKuis();
      if (!mounted) return;
      setState(() {
        _kuis = kuis;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : '$e';
      });
    }
  }

  Future<void> _buka(KuisInfo kuis) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizPage(kuis: kuis)),
    );
    if (mounted) _muat();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bisa = _kuis.where((k) => k.bisaDikerjakan).length;
    final kuisMateri = _kuis.where((k) => !k.isLatihan).toList();
    final latihan = _kuis.where((k) => k.isLatihan).toList();

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _RingkasanKuis(tersedia: bisa, total: _kuis.length),
          const SizedBox(height: 24),
          if (_error != null)
            _PesanKartu(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat kuis',
              message: _error!,
              onRetry: _muat,
            )
          else if (_kuis.isEmpty)
            _PesanKartu(
              icon: Icons.quiz_outlined,
              title: 'Belum ada kuis',
              message:
                  'Admin belum menambahkan kuis. Silakan cek kembali nanti.',
              onRetry: _muat,
            )
          else ...[
            if (kuisMateri.isNotEmpty) ...[
              Text('Daftar Ujian', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              ...kuisMateri.map(_kartu),
            ],
            if (latihan.isNotEmpty) ...[
              if (kuisMateri.isNotEmpty) const SizedBox(height: 8),
              Text('Latihan Soal', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Latihan mandiri dengan soal bergambar atau pilihan jawaban foto.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              ...latihan.map(_kartu),
            ],
          ],
        ],
      ),
    );
  }

  Widget _kartu(KuisInfo kuis) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _KartuKuis(
        kuis: kuis,
        onStart: kuis.bisaDikerjakan ? () => _buka(kuis) : null,
      ),
    );
  }
}

/// Kartu ringkasan di atas daftar ujian.
class _RingkasanKuis extends StatelessWidget {
  final int tersedia;
  final int total;

  const _RingkasanKuis({required this.tersedia, required this.total});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primary,
      borderColor: Colors.transparent,
      borderRadius: AppRadii.xl,
      shadows: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.24),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: AppColors.textOnPrimary,
            ),
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
                  '$tersedia dari $total ujian tersedia untukmu.',
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

/// Kartu satu kuis.
class _KartuKuis extends StatelessWidget {
  final KuisInfo kuis;
  final VoidCallback? onStart;

  const _KartuKuis({required this.kuis, this.onStart});

  @override
  Widget build(BuildContext context) {
    final aktif = onStart != null;
    final metaColor = aktif ? AppColors.textSecondary : AppColors.textMuted;

    return AppCard(
      color: aktif ? null : AppColors.surfaceTonal,
      borderColor: aktif ? AppColors.border : AppColors.surfaceTonal,
      shadows: aktif ? AppShadows.card : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: aktif ? AppColors.pinkSoft : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  aktif ? Icons.quiz_rounded : Icons.lock_outline_rounded,
                  size: 20,
                  color: aktif ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kuis.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: aktif ? null : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kuis.sudahDikerjakan
                          ? 'Sudah dikerjakan'
                          : (kuis.bisaDikerjakan
                              ? 'Siap dikerjakan'
                              : 'Belum ada soal'),
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: metaColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _meta(
                      Icons.quiz_outlined,
                      '${kuis.jumlahSoal.clamp(0, SoalKuis.maksSoal)} Soal',
                      metaColor,
                    ),
                    _meta(
                      Icons.bolt_rounded,
                      '+${kuis.xpReward} XP',
                      aktif ? AppColors.tertiary : AppColors.textMuted,
                    ),
                    if (kuis.adaGambar)
                      _meta(
                        Icons.image_outlined,
                        'Bergambar',
                        aktif ? AppColors.secondary : AppColors.textMuted,
                      ),
                  ],
                ),
              ),
              if (kuis.sudahDikerjakan) ...[
                const SizedBox(width: 8),
                const AppStatusBadge(
                  label: 'Selesai',
                  color: AppColors.success,
                ),
              ],
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
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    aktif
                        ? Icons.play_arrow_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    aktif
                        ? (kuis.isLatihan ? 'Mulai Latihan' : 'Mulai Ujian')
                        : 'Belum Tersedia',
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

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.labelXSmall.copyWith(color: color)),
      ],
    );
  }
}

/// Kartu pesan untuk state error dan kosong.
class _PesanKartu extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _PesanKartu({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTonal,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat ulang'),
          ),
        ],
      ),
    );
  }
}
