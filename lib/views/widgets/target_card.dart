import 'package:flutter/material.dart';

class TargetCard extends StatelessWidget {
  final int completedBab;
  final int totalBab;

  const TargetCard({
    super.key,
    required this.completedBab,
    required this.totalBab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.27, -0.27),
          end: Alignment(0.73, 1.27),
          colors: [Colors.white, Color(0xFFF0EDEC), Color(0xFFEBE7E7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TARGET CAPAIAN',
                      style: TextStyle(
                        color: const Color(0xFFB5005F),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDEC),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'Terkunci',
                        style: TextStyle(
                          color: const Color(0xFF8D6F77),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Sertifikasi Resmi Tingkat A1\nSign.L',
                  style: TextStyle(
                    color: const Color(0xFF1C1B1B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selesaikan Bab 1 sampai 5 dan lulus uji\nkamera AI komprehensif untuk membuka\nlencana verifikasi dan sertifikat digital\nportofolio.',
                  style: TextStyle(
                    color: const Color(0xFF594047),
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kemajuan: $completedBab / $totalBab Bab',
                      style: TextStyle(
                        color: const Color(0xFF594047),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Sisa ${totalBab - completedBab} Bab',
                      style: TextStyle(
                        color: const Color(0xFFB5005F),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}