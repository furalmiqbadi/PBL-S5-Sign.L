import 'package:flutter/material.dart';
import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CurrentProgressCard extends StatelessWidget {
  final Bab bab;

  const CurrentProgressCard({super.key, required this.bab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEDANG BERLANGSUNG',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bab.title,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.textOnPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Langkah berikutnya: Uji Kamera Huruf M-Z',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}