import 'package:flutter/material.dart';

import '../../models/bab_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';
import 'section_header.dart';
import 'stat_pill.dart';

/// Header halaman detail materi: tombol kembali, judul, progres, lalu kartu
/// ringkasan bab yang sedang dibuka.
///
/// Semua elemen berada dalam satu kolom agar tombol kembali sejajar dengan
/// judul (bukan mengambang di tengah kartu), dan pill progres memakai
/// [StatPill] yang sama dengan header tab Materi.
class DetailHeader extends StatelessWidget {
  final String title;
  final Bab bab;
  final VoidCallback? onBack;

  const DetailHeader({
    super.key,
    required this.bab,
    this.title = 'Detail Materi',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (bab.progress * 100).round();
    final statusColor = babStatusColor(bab.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              // Chrome sama dengan header tab: kotak 48px putih berbingkai.
              HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Kembali',
                onTap: onBack,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineSmall,
              ),
            ),
            const SizedBox(width: 8),
            StatPill(
              icon: Icons.bolt_rounded,
              value: '$percent%',
              accent: AppColors.primary,
              semanticLabel: 'Progres $percent persen',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  bab.number,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bab.progressText,
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: bab.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.pinkSoft,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
