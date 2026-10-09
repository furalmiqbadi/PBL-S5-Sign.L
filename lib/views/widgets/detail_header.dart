import 'package:flutter/material.dart';

class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detail Materi',
              style: TextStyle(
                color: Color(0xFF1C1B1B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE7E7),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Color(0xFF594047)),
                      SizedBox(width: 4),
                      Text(
                        '190 / 250 XP',
                        style: TextStyle(
                          color: Color(0xFF594047),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EDEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 16, color: Color(0xFF594047)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33E0BEC6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0x4CE0BEC6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '01',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bab 1: Alfabet',
                      style: TextStyle(
                        color: Color(0xFF1C1B1B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0x33E0BEC6)),
                ),
                child: Row(
                  children: [
                    const Text(
                      '42% Selesai',
                      style: TextStyle(
                        color: Color(0xFFB5005F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      height: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: 0.42,
                          backgroundColor: const Color(0xFFE5E2E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDD2A7B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}