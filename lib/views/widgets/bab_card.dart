import 'package:flutter/material.dart';
import '../../models/bab_model.dart';

class BabCard extends StatelessWidget {
  final Bab bab;
  final VoidCallback? onTap;

  const BabCard({super.key, required this.bab, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (bab.isLocked) return _buildLockedCard();
    return _buildActiveCard();
  }

  Widget _buildActiveCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildNumberBadge(bab.number, bab.isInProgress),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bab.subtitle,
                        style: TextStyle(
                          color: bab.isInProgress ? const Color(0xFFB5005F) : const Color(0xFF594047),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        bab.title,
                        style: const TextStyle(
                          color: Color(0xFF1C1B1B),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildProgressBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThumbnail(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bab.description,
                      style: TextStyle(
                        color: const Color(0xFF594047),
                        fontSize: 12,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book, size: 14, color: Color(0xFF594047)),
                        const SizedBox(width: 4),
                        Text(
                          '${bab.totalMateri} Materi',
                          style: TextStyle(color: Color(0xFF594047), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Color(0xFF594047)),
                        const SizedBox(width: 4),
                        Text(
                          bab.durationText,
                          style: TextStyle(color: Color(0xFF594047), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bab.isInProgress) ...[
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedCard() {
    return Opacity(
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildNumberBadge(bab.number, false),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, size: 12, color: Color(0xFF8D6F77)),
                          const SizedBox(width: 4),
                          Text(
                            bab.subtitle,
                            style: TextStyle(
                              color: const Color(0xFF8D6F77),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        bab.title,
                        style: TextStyle(
                          color: const Color(0xFF594047),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildThumbnail(isLocked: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bab.description,
                        style: TextStyle(
                          color: const Color(0xFF8D6F77),
                          fontSize: 12,
                          height: 1.33,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.menu_book, size: 14, color: Color(0xFF8D6F77)),
                          const SizedBox(width: 4),
                          Text(
                            '${bab.totalMateri} Materi',
                            style: TextStyle(color: Color(0xFF8D6F77), fontSize: 10),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Color(0xFF8D6F77)),
                          const SizedBox(width: 4),
                          Text(
                            bab.durationText,
                            style: TextStyle(color: Color(0xFF8D6F77), fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBadge(String number, bool isActive) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD9E2) : const Color(0xFFE5E2E1),
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: TextStyle(
          color: isActive ? const Color(0xFF3E001D) : const Color(0xFF1C1B1B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bab.isInProgress ? const Color(0xFFFFD9E2) : const Color(0xFFF0EDEC),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        bab.isInProgress ? '${(bab.progress * 100).toInt()}%' : 'Baru',
        style: TextStyle(
          color: bab.isInProgress ? const Color(0xFF3E001D) : const Color(0xFF594047),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThumbnail({bool isLocked = false}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isLocked ? Colors.white : const Color(0xFFF0EDEC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://placehold.co/80x80',
              fit: BoxFit.cover,
            ),
          ),
          if (isLocked)
            Container(
              decoration: BoxDecoration(
                color: const Color(0x99EBE7E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, color: Color(0xFF8D6F77)),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: bab.progress,
            backgroundColor: const Color(0xFFEBE7E7),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDD2A7B)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bab.progressText,
              style: TextStyle(color: const Color(0xFF594047), fontSize: 10, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Text(
                    'Lanjut Belajar',
                    style: TextStyle(
                      color: const Color(0xFFB5005F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFFB5005F)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}