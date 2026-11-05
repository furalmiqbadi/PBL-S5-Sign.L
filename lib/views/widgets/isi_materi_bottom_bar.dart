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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: isFirst ? 0.4 : 1,
              child: _outlineButton(
                label: 'Sebelumnya',
                fg: AppColors.textSecondary,
                bg: AppColors.fieldFill,
                onTap: isFirst ? () {} : onPrevious,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _outlineButton(
              label: 'Coba Foto',
              fg: AppColors.primary,
              bg: AppColors.pinkSoft,
              onTap: onCamera,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
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