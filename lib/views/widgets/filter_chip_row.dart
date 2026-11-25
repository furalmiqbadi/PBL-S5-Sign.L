import 'package:flutter/material.dart';

import 'app_ui.dart';

/// Baris chip filter yang dapat digulir horizontal.
///
/// Chip terpilih menggunakan [AppChoiceChip] agar selaras di seluruh aplikasi.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Center(
            child: AppChoiceChip(
              label: labels[index],
              isSelected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
          );
        },
      ),
    );
  }
}
