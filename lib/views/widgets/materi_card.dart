import 'package:flutter/material.dart';
import '../../models/materi_model.dart';

class MateriCard extends StatelessWidget {
  final Materi materi;
  final VoidCallback onTap;

  const MateriCard({super.key, required this.materi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (materi.isLocked) return _buildLockedCard();
    if (materi.isInProgress) return _buildInProgressCard();
    return _buildCompletedCard();
  }

  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDCC6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF311300)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            materi.title,
                            style: const TextStyle(
                              color: Color(0xFF1C1B1B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDCC6),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '+${materi.xpReward} XP',
                            style: const TextStyle(
                              color: Color(0xFF311300),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materi.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF594047),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: Color(0xFF964900)),
                  const SizedBox(width: 4),
                  const Text(
                    'Selesai Dikuasai',
                    style: TextStyle(
                      color: Color(0xFF964900),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE7E7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'Ulas Kembali',
                  style: TextStyle(
                    color: Color(0xFF1C1B1B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD9E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Color(0xFF3E001D)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD92778),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'SEDANG DIPELAJARI',
                            style: TextStyle(
                              color: Color(0xFFFFFBFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Progres ${materi.completedGestures}/${materi.totalGestures}',
                          style: const TextStyle(
                            color: Color(0xFFB5005F),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      materi.title,
                      style: const TextStyle(
                        color: Color(0xFF1C1B1B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      materi.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF594047),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE7E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/bisindo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF8D6F77),
                      ),
                    ),
                  ),
                ), // <- kurung penutup Container yang tadi kurang
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Saat Ini',
                        style: TextStyle(
                          color: Color(0xFF594047),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gerakan Huruf H: Dua Jari Horisontal',
                        style: TextStyle(
                          color: Color(0xFF1C1B1B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: 0.6,
                          backgroundColor: const Color(0xFFE5E2E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDD2A7B)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Lanjut Belajar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard() {
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x99F6F3F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EDEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 16, color: Color(0xFF8D6F77)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materi.title,
                      style: const TextStyle(
                        color: Color(0xFF1C1B1B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      materi.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF594047),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}