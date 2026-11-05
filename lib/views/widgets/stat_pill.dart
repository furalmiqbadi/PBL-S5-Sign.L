import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';

/// Pill statistik kecil: ikon + angka, dengan latar tipis berwarna aksen.
///
/// Dipakai untuk menampilkan statistik belajar seperti streak, heart (nyawa),
/// diamond (gems), dan EXP. Ikon di-tint mengikuti [accent] agar selaras dengan
/// angka dan latarnya. Isi salah satu: [svgAsset] atau [icon].
class StatPill extends StatelessWidget {
  /// Path aset SVG ikon (mis. `assets/images/streak_fix.svg`).
  final String? svgAsset;

  /// Ikon Material, dipakai bila tidak ada aset SVG.
  final IconData? icon;

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
    this.svgAsset,
    this.icon,
    required this.value,
    required this.accent,
    this.semanticLabel,
    this.iconSize = 14,
  }) : assert(svgAsset != null || icon != null, 'Isi salah satu: svgAsset atau icon.');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? value,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              )
            else
              Icon(icon, size: iconSize + 2, color: accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.labelLarge.copyWith(
                color: accent,
                fontSize: 12,
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
