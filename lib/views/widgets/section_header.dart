import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Kerangka bersama untuk header bagian (section) di dalam aplikasi.
///
/// Memberi chrome yang konsisten di semua header: judul besar di kiri,
/// deretan aksi di kanan, dan garis pemisah halus di bawahnya. Dipakai oleh
/// header Materi, Komunitas, dan Profil agar tinggi serta gayanya seragam.
class SectionHeader extends StatelessWidget {
  /// Judul bagian.
  final String title;

  /// Aksi di sisi kanan (ikon, tombol, dsb). Ditata dari kiri ke kanan.
  final List<Widget> actions;

  const SectionHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          // Judul mengisi sisa ruang; aksi mengambil ukuran alaminya.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Tombol ikon untuk header, opsional dengan badge notifikasi.
///
/// Ikon bisa berasal dari Material ([icon]) atau aset SVG ([svgAsset]).
/// Bila [svgAsset] diisi, SVG di-tint mengikuti warna ikon header.
///
/// [filled] = true menampilkan latar lingkaran abu tipis (gaya tombol
/// sekunder). [filled] = false menampilkan ikon polos tanpa latar.
///
/// Tombol mengecil sedikit saat ditekan sebagai umpan balik taktil.
class HeaderIconButton extends StatefulWidget {
  /// Ikon Material. Kosongkan bila memakai [svgAsset].
  final IconData? icon;

  /// Path aset SVG (mis. `assets/images/dm_fix.svg`). Kosongkan bila memakai
  /// [icon]. SVG sebaiknya satu warna solid agar hasil tint rapi.
  final String? svgAsset;

  final VoidCallback? onTap;
  final String semanticLabel;

  /// Teks badge kecil di pojok kanan atas (mis. `"2"`). Null = tanpa badge.
  final String? badge;

  /// True = latar lingkaran tipis; false = ikon polos.
  final bool filled;

  /// Ukuran ikon.
  final double iconSize;

  const HeaderIconButton({
    super.key,
    this.icon,
    this.svgAsset,
    required this.semanticLabel,
    this.onTap,
    this.badge,
    this.filled = true,
    this.iconSize = 21,
  }) : assert(icon != null || svgAsset != null,
            'Isi salah satu: icon atau svgAsset.');

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;
    final badgeColor = theme.colorScheme.primary;

    final child = widget.svgAsset != null
        ? SvgPicture.asset(
            widget.svgAsset!,
            width: widget.iconSize,
            height: widget.iconSize,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          )
        : Icon(widget.icon, size: widget.iconSize, color: iconColor);

    Widget button = Material(
      color: widget.filled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
          : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );

    if (widget.badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
              ),
              child: Text(
                widget.badge!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
