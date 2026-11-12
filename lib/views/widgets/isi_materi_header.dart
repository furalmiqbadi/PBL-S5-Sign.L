import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class IsiMateriHeader extends StatelessWidget {
  final VoidCallback onBack;
  const IsiMateriHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Kembali',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _badge(
                bg: AppColors.orangeSoft,
                fg: AppColors.tertiary,
                leading: SvgPicture.asset(
                  'assets/images/streak_fix.svg',
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    AppColors.tertiary,
                    BlendMode.srcIn,
                  ),
                ),
                text: '7',
              ),
              const SizedBox(width: 8),
              _badge(
                bg: AppColors.purpleSoft,
                fg: AppColors.secondary,
                leading: SvgPicture.asset(
                  'assets/images/diamond_fix.svg',
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    AppColors.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                text: '+15',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required Color bg,
    required Color fg,
    required Widget leading,
    required String text,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
