import 'package:flutter/material.dart';
import '../../models/gestur_model.dart';

class LatihanProgressBar extends StatelessWidget {
  final Gestur gestur;
  const LatihanProgressBar({super.key, required this.gestur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  letterSpacing: 0.30,
                ),
                children: [
                  TextSpan(
                    text: 'LATIHAN ${gestur.latihanKe} ',
                    style: const TextStyle(
                      color: Color(0xFF8639B4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '(DARI ${gestur.totalLatihan})',
                    style: const TextStyle(
                      color: Color(0xFF594047),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              gestur.progressPercent,
              style: const TextStyle(
                color: Color(0xFFDD2A7B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bar segmented: biru = selesai, ungu muda = sisa
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Flexible(
                  flex: gestur.latihanKe,
                  child: Container(color: const Color(0xFF00C2FF)),
                ),
                Flexible(
                  flex: gestur.totalLatihan - gestur.latihanKe,
                  child: Container(color: const Color(0xFFE5D4FF)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}