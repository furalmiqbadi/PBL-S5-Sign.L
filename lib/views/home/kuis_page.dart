import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/final_exam_card.dart';
import 'quiz_page.dart';

/// Konten tab Kuis: daftar ujian per bab dengan gaya yang sama seperti kartu
/// di tab Materi.
///
/// Tiap kartu membuka [QuizPage] (layar soal). Bab yang masih terkunci
/// ditampilkan redup dan tombolnya dinonaktifkan.
class KuisPage extends StatelessWidget {
  const KuisPage({super.key});

  /// Jumlah soal tiap ujian bab.
  static const int _jumlahSoal = 10;

  @override
  Widget build(BuildContext context) {
    final babList = dummyBabList;
    final tersedia = babList.where((b) => !b.isLocked).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _KuisSummaryCard(tersedia: tersedia, total: babList.length),
        const SizedBox(height: 24),
        Text('Ujian per Bab', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        ...babList.map(
          (bab) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _QuizBabCard(
              bab: bab,
              jumlahSoal: _jumlahSoal,
              onStart: bab.isLocked
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuizPage()),
                      ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Evaluasi Akhir', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        const FinalExamCard(),
      ],
    );
  }
}

/// Kartu ringkasan di atas daftar ujian.
class _KuisSummaryCard extends StatelessWidget {
  final int tersedia;
  final int total;

  const _KuisSummaryCard({required this.tersedia, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UJI PEMAHAMAN',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Kuis & Evaluasi', style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '$tersedia dari $total ujian tersedia untukmu.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu ujian untuk satu bab.
class _QuizBabCard extends StatelessWidget {
  final Bab bab;
  final int jumlahSoal;
  final VoidCallback? onStart;

  const _QuizBabCard({
    required this.bab,
    required this.jumlahSoal,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final locked = bab.isLocked;
    final metaColor = locked ? AppColors.textMuted : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locked ? AppColors.surfaceMuted : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _numberBadge(bab.number, !locked),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ujian Bab ${bab.number}',
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: locked ? AppColors.textMuted : AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      bab.title,
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
                const Icon(Icons.lock, size: 16, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kerjakan $jumlahSoal soal pilihan ganda untuk menguji pemahamanmu.',
            style: AppTextStyles.bodySmall.copyWith(
              color: locked ? AppColors.textMuted : null,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.quiz_outlined, '$jumlahSoal Soal', metaColor),
              const SizedBox(width: 16),
              _meta(Icons.access_time, bab.durationText, metaColor),
              const SizedBox(width: 16),
              _diamondMeta(
                '+${bab.totalMateri * 10}',
                locked ? AppColors.textMuted : AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    locked ? Icons.lock_outline : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locked ? 'Terkunci' : 'Mulai Ujian',
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
