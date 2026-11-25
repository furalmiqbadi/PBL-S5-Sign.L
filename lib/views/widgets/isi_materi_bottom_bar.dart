import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: isFirst ? 0.45 : 1,
                  child: _tonalButton(
                    label: 'Sebelumnya',
                    fg: AppColors.textSecondary,
                    bg: AppColors.surfaceMuted,
                    onTap: isFirst ? null : onPrevious,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tonalButton(
                  label: 'Coba Foto',
                  fg: AppColors.primary,
                  bg: AppColors.pinkSoft,
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isLast ? 'Selesai' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tonalButton({
    required String label,
    required Color fg,
    required Color bg,
    required VoidCallback? onTap,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Material(
      color: bg,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.copyWith(
              color: fg,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
