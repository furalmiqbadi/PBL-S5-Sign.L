import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class IsiMateriBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onCamera;
  final VoidCallback onNext;
  final bool isFirst;
  final bool isLast;

  const IsiMateriBottomBar({
    super.key,
    required this.onPrevious,
    required this.onCamera,
    required this.onNext,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.surfaceMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: isFirst ? 0.4 : 1,
              child: _outlineButton(
                label: 'Sebelumnya',
                fg: AppColors.secondary,
                onTap: isFirst ? () {} : onPrevious,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _outlineButton(
              label: 'Coba Foto',
              fg: AppColors.primary,
              onTap: onCamera,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Selesai' : 'Lanjut',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.pinkSoft.withValues(alpha: 0.30),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}