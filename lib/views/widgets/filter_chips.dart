import 'package:flutter/material.dart';
import '../../controllers/materi_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FilterChips extends StatelessWidget {
  final FilterType currentFilter;
  final Function(FilterType) onFilterChanged;

  const FilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('Semua Bab', FilterType.all, true),
          const SizedBox(width: 8),
          _buildChip('Sedang Dipelajari', FilterType.inProgress, false),
          const SizedBox(width: 8),
          _buildChip('Selesai', FilterType.completed, false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, FilterType type, bool isActive) {
    final active = currentFilter == type;
    return GestureDetector(
      onTap: () => onFilterChanged(type),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}