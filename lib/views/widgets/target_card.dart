import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TargetCard extends StatelessWidget {
  final int completedBab;
  final int totalBab;

  const TargetCard({
    super.key,
    required this.completedBab,
    required this.totalBab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.27, -0.27),
          end: Alignment(0.73, 1.27),
          colors: [AppColors.surface, AppColors.surfaceMuted, AppColors.border],
        ),
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.tertiary, AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TARGET CAPAIAN',
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'Terkunci',
                        style: AppTextStyles.labelXSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Sertifikasi Resmi Tingkat A1\nSign.L',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Selesaikan Bab 1 sampai 5 dan lulus uji\nkamera AI komprehensif untuk membuka\nlencana verifikasi dan sertifikat digital\nportofolio.',
                  style: AppTextStyles.bodySmall.copyWith(height: 1.33),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kemajuan: $completedBab / $totalBab Bab',
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Sisa ${totalBab - completedBab} Bab',
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}