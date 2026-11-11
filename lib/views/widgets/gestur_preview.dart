import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GesturPreview extends StatelessWidget {
  final String assetPath;
  const GesturPreview({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 224,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface, // latar putih supaya ruang kosong menyatu dengan foto
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain, // tampilkan seluruh gambar, tidak dipotong
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.textMuted),
        ),
      ),
    );
  }
}