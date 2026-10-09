import 'package:flutter/material.dart';

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
        color: Colors.white, // latar putih supaya ruang kosong menyatu dengan foto
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain, // tampilkan seluruh gambar, tidak dipotong
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Color(0xFF8D6F77)),
        ),
      ),
    );
  }
}