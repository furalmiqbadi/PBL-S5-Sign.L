import 'package:flutter/material.dart';
import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

class BabCard extends StatelessWidget {
  final Bab bab;
  final VoidCallback? onTap;

  const BabCard({super.key, required this.bab, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (bab.isLocked) return _buildLockedCard();
    return _buildActiveCard();
  }

  Widget _buildActiveCard() {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderColor: bab.isInProgress
          ? AppColors.primary.withValues(alpha: 0.28)
          : AppColors.border,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildNumberBadge(bab.number, bab.isInProgress),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bab.subtitle,
                            style: AppTextStyles.labelXSmall.copyWith(
                              color: bab.isInProgress
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            bab.title,
                            style: AppTextStyles.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildProgressBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bab.description,
                      style: AppTextStyles.bodySmall.copyWith(height: 1.33),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.menu_book,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${bab.totalMateri} ${bab.metaUnit}',
                          style: AppTextStyles.labelXSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          bab.progressText,
                          style: AppTextStyles.labelXSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bab.isInProgress) ...[
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedCard() {
    return Opacity(
      opacity: 0.85,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        color: AppColors.surfaceTonal,
        shadows: null,
        child: Column(
          children: [
            Row(
              children: [
                _buildNumberBadge(bab.number, false),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bab.subtitle,
                            style: AppTextStyles.labelXSmall,
                          ),
                        ],
                      ),
                      Text(
                        bab.title,
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildThumbnail(isLocked: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bab.description,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted, height: 1.33),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.menu_book,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${bab.totalMateri} ${bab.metaUnit}',
                            style: AppTextStyles.labelXSmall
                                .copyWith(fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bab.progressText,
                            style: AppTextStyles.labelXSmall
                                .copyWith(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBadge(String number, bool isActive) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.pinkSoft : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bab.isInProgress ? AppColors.pinkSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        bab.isInProgress ? '${(bab.progress * 100).toInt()}%' : 'Baru',
        style: AppTextStyles.labelXSmall.copyWith(
          color: bab.isInProgress
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThumbnail({bool isLocked = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isLocked ? Colors.white : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/bisindo.jpg',
              fit: BoxFit.cover,
              // Bila gambar gagal dimuat, biarkan warna latar kartu terlihat.
              errorBuilder: (_, __, ___) => const SizedBox.expand(),
            ),
          ),
          if (isLocked)
            Container(
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: bab.progress,
            backgroundColor: AppColors.pinkSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bab.progressText,
              style: AppTextStyles.labelXSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lanjut Belajar',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 15, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
