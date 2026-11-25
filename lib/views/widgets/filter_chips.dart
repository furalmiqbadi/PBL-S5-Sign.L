import 'package:flutter/material.dart';
import '../../controllers/materi_controller.dart';
import 'app_ui.dart';

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
          AppChoiceChip(
            label: 'Semua Bab',
            isSelected: currentFilter == FilterType.all,
            onTap: () => onFilterChanged(FilterType.all),
          ),
          const SizedBox(width: 8),
          AppChoiceChip(
            label: 'Sedang Dipelajari',
            isSelected: currentFilter == FilterType.inProgress,
            onTap: () => onFilterChanged(FilterType.inProgress),
          ),
          const SizedBox(width: 8),
          AppChoiceChip(
            label: 'Selesai',
            isSelected: currentFilter == FilterType.completed,
            onTap: () => onFilterChanged(FilterType.completed),
          ),
        ],
      ),
    );
  }
}
