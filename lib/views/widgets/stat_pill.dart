import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Pill statistik kecil: ikon SVG + angka, dengan latar tipis berwarna aksen.
///
/// Dipakai untuk menampilkan statistik belajar seperti streak, heart (nyawa),
/// dan diamond (gems). Ikon di-tint mengikuti [accent] agar selaras dengan
/// angka dan latarnya.
class StatPill extends StatelessWidget {
  /// Path aset SVG ikon (mis. `assets/images/streak_fix.svg`).
  final String svgAsset;

  /// Nilai yang ditampilkan (sudah diformat, mis. `"7"` atau `"420"`).
  final String value;

  /// Warna aksen pill: dipakai untuk ikon, angka, latar, dan border.
  final Color accent;

  /// Label untuk pembaca layar. Bila null, dipakai [value].
  final String? semanticLabel;

  /// Ukuran ikon.
  final double iconSize;

  const StatPill({
    super.key,
    required this.svgAsset,
    required this.value,
    required this.accent,
    this.semanticLabel,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
