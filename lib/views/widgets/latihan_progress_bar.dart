import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../models/gestur_model.dart';
import '../theme/app_text_styles.dart';

class LatihanProgressBar extends StatelessWidget {
  final Gestur gestur;
  const LatihanProgressBar({super.key, required this.gestur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  letterSpacing: 0.30,
                ),
                children: [
                  TextSpan(
                    text: 'LATIHAN ${gestur.latihanKe} ',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '(DARI ${gestur.totalLatihan})',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              gestur.progressPercent,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar segmented: biru = selesai, ungu muda = sisa
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Flexible(
                  flex: gestur.latihanKe,
                  child: Container(color: AppColors.secondary),
                ),
                Flexible(
                  flex: gestur.totalLatihan - gestur.latihanKe,
                  child: Container(color: AppColors.purpleSoft),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}