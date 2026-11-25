import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

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
    final remaining = (totalBab - completedBab).clamp(0, totalBab);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: AppColors.tertiary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'TARGET CAPAIAN',
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const AppStatusBadge(
                      label: 'Terkunci',
                      color: AppColors.textSecondary,
                      backgroundColor: AppColors.surfaceMuted,
                      icon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sertifikasi Resmi Tingkat A1 Sign.L',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Selesaikan Bab 1 sampai $totalBab dan lulus uji kamera AI komprehensif untuk membuka lencana verifikasi dan sertifikat digital portofolio.',
                  style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kemajuan: $completedBab / $totalBab Bab',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Sisa $remaining Bab',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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
