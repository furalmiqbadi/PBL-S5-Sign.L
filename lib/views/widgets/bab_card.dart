import 'package:flutter/material.dart';
import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildNumberBadge(bab.number, bab.isInProgress),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bab.subtitle,
                        style: AppTextStyles.labelXSmall.copyWith(
                          color: bab.isInProgress ? AppColors.primary : AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        bab.title,
                        style: AppTextStyles.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
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
                        const Icon(Icons.menu_book, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${bab.totalMateri} Materi',
                          style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          bab.durationText,
                          style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textSecondary),
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
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
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
                          const Icon(Icons.lock, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bab.subtitle,
                            style: AppTextStyles.labelXSmall,
                          ),
                        ],
                      ),
                      Text(
                        bab.title,
                        style: AppTextStyles.titleLarge.copyWith(color: AppColors.textSecondary),
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
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, height: 1.33),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.menu_book, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${bab.totalMateri} Materi',
                            style: AppTextStyles.labelXSmall.copyWith(fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bab.durationText,
                            style: AppTextStyles.labelXSmall.copyWith(fontWeight: FontWeight.w400),
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
          color: bab.isInProgress ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThumbnail({bool isLocked = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isLocked ? Colors.white : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
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
            backgroundColor: AppColors.border,
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
              style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    'Lanjut Belajar',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}