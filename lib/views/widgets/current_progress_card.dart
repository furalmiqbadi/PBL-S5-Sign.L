import 'package:flutter/material.dart';
import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

/// Kartu fokus "sedang berlangsung" di halaman Materi.
///
/// Permukaan putih dengan aksen `primary` agar tetap menjadi titik fokus,
/// tanpa gradasi merek (gradasi hanya untuk tombol tengah navbar).
class CurrentProgressCard extends StatelessWidget {
  final Bab bab;
  final VoidCallback? onTap;

  const CurrentProgressCard({super.key, required this.bab, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderRadius: AppRadii.dialog,
      borderColor: AppColors.primary.withValues(alpha: 0.18),
      shadows: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.10),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEDANG BERLANGSUNG',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bab.title,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  bab.progressText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.textOnPrimary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
