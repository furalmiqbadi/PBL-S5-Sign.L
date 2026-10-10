import 'package:flutter/material.dart';
import '../../models/gestur_model.dart';

class GesturDescriptionCard extends StatelessWidget {
  final Gestur gestur;
  const GesturDescriptionCard({super.key, required this.gestur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0EDEC)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HURUF ${gestur.huruf}',
                style: const TextStyle(
                  color: Color(0xFF8639B4),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.47,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x7FFFD9E2),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  gestur.badgeLabel,
                  style: const TextStyle(
                    color: Color(0xFFDD2A7B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Label deskripsi
          const Text(
            'DESKRIPSI BENTUK TANGAN',
            style: TextStyle(
              color: Color(0xFFDD2A7B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.60,
            ),
          ),
          const SizedBox(height: 6),
          // Daftar langkah
          ...gestur.deskripsiLangkah.map(
            (langkah) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8639B4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      langkah,
                      style: const TextStyle(
                        color: Color(0xFF594047),
                        fontSize: 12,
                        height: 1.63,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}