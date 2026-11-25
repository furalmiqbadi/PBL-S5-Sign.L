import 'package:flutter/material.dart';

import '../../services/kuis_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

/// Kartu satu kuis pada halaman detail materi.
///
/// Tombol dinonaktifkan bila [onStart] null (kuis belum punya soal).
class QuizCard extends StatelessWidget {
  final KuisInfo kuis;
  final VoidCallback? onStart;

  const QuizCard({super.key, required this.kuis, this.onStart});

  @override
  Widget build(BuildContext context) {
    final aktif = onStart != null;
    final metaColor = aktif ? AppColors.textSecondary : AppColors.textMuted;

    return AppCard(
      onTap: onStart,
      color: aktif ? null : AppColors.surfaceTonal,
      borderColor: aktif ? AppColors.border : AppColors.surfaceTonal,
      shadows: aktif ? AppShadows.card : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: aktif ? AppColors.pinkSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  aktif ? Icons.quiz_outlined : Icons.lock_outline_rounded,
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
                      '${kuis.jumlahSoal} soal',
                      style: AppTextStyles.bodySmall.copyWith(color: metaColor),
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
          if (kuis.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              kuis.deskripsi,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.bolt_rounded,
                  size: 14,
                  color: aktif ? AppColors.tertiary : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '+${kuis.xpReward} XP',
                style: AppTextStyles.labelXSmall.copyWith(
                  color: aktif ? AppColors.tertiary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
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
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: Text(
                aktif ? 'Mulai Kuis' : 'Belum Tersedia',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
