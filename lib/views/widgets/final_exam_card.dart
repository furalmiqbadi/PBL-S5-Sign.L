import 'package:flutter/material.dart';

class FinalExamCard extends StatelessWidget {
  const FinalExamCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xB2F6F3F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBE7E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Color(0xFF8D6F77)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ujian Refleks Gestur Bab 1',
                    style: TextStyle(
                      color: Color(0xFF1C1B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selesaikan seluruh materi & latihan\nkamera AI untuk membuka\nsertifikasi bab.',
                    style: TextStyle(
                      color: const Color(0xFF594047),
                      fontSize: 12,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Text(
            'Terkunci',
            style: TextStyle(
              color: Color(0xFF8D6F77),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}