import 'package:flutter/material.dart';

class IsiMateriHeader extends StatelessWidget {
  final VoidCallback onBack;
  const IsiMateriHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xE5FCF9F8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDEC),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, size: 14, color: Color(0xFF1C1B1B)),
                  SizedBox(width: 6),
                  Text(
                    'Kembali',
                    style: TextStyle(
                      color: Color(0xFF1C1B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _badge(
                bg: const Color(0x99FFDCC6),
                fg: const Color(0xFF964900),
                icon: Icons.local_fire_department,
                text: '7',
              ),
              const SizedBox(width: 8),
              _badge(
                bg: const Color(0x7FFFD9E2),
                fg: const Color(0xFFDD2A7B),
                icon: Icons.star,
                text: '+15 XP',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge({
    required Color bg,
    required Color fg,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}