import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kerangka bersama untuk header bagian (section) di dalam aplikasi.
///
/// Memberi chrome yang konsisten di semua header: judul besar di kiri,
/// deretan aksi di kanan, dan garis pemisah halus di bawahnya. Dipakai oleh
/// header Materi, Komunitas, dan Profil agar tinggi serta gayanya seragam.
///
/// Seluruh warna diambil dari [ColorScheme] sehingga header otomatis cocok
/// saat mode gelap diaktifkan.
class SectionHeader extends StatelessWidget {
  /// Tinggi tetap area konten header.
  ///
  /// Disamakan dengan tinggi kontrol tertinggi (tombol ikon/avatar 48px)
  /// supaya semua header punya tinggi identik, termasuk yang hanya berisi
  /// konten pendek seperti [StatPill].
  static const double contentHeight = 48;

  /// Font display untuk semua judul header.
  ///
  /// Quicksand (rounded geometric) dipilih karena tarikan garisnya lebih tipis
  /// dan lapang daripada Fredoka, sehingga judul tab terasa ringan namun tetap
  /// tegas dan mudah dipindai — berbeda dari font script pada wordmark merek.
  static TextStyle displayStyle(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.quicksand(
      fontSize: 25,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  /// Judul bagian.
  final String title;

  /// Widget opsional sebelum judul (mis. logo aplikasi).
  final Widget? leading;

  /// Gaya opsional untuk judul. Menimpa sebagian gaya bawaan (mis. untuk
  /// memakai font kustom pada wordmark), sementara warna tetap dari tema.
  final TextStyle? titleStyle;

  /// Aksi di sisi kanan (ikon, tombol, dsb). Ditata dari kiri ke kanan.
  final List<Widget> actions;

  const SectionHeader({
    super.key,
    required this.title,
    this.leading,
    this.titleStyle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Padding vertikal lega supaya header terasa lapang dan seimbang
      // dengan tinggi tombol aksi (48px).
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SizedBox(
        height: contentHeight,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            // Judul mengisi sisa ruang; aksi mengambil ukuran alaminya.
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: displayStyle(context).merge(titleStyle),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol ikon untuk header, opsional dengan badge notifikasi.
///
/// Ikon bisa berasal dari Material ([icon]) atau aset SVG ([svgAsset]).
/// Bila [svgAsset] diisi, SVG di-tint mengikuti warna ikon header.
///
/// Tanpa latar, agar semua header seragam. Saat disorot (web/desktop) atau
/// ditekan, ikon berubah ke warna aksen tema dan mengecil sedikit — pola
/// umpan balik yang sama dengan item [AppBottomNavBar].
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

  /// Ukuran ikon.
  final double iconSize;

  const HeaderIconButton({
    super.key,
    this.icon,
    this.svgAsset,
    required this.semanticLabel,
    this.onTap,
    this.badge,
    this.iconSize = 22,
  }) : assert(icon != null || svgAsset != null,
            'Isi salah satu: icon atau svgAsset.');

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton> {
  bool _pressed = false;
  bool _hovered = false;

  /// True saat tombol sedang disorot atau ditekan.
  bool get _active => _pressed || _hovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.onSurface;
    final accentColor = theme.colorScheme.primary;

    // Ikon dirender ulang dengan warna animasi saat state berubah.
    Widget iconFor(Color color) => widget.svgAsset != null
        ? SvgPicture.asset(
            widget.svgAsset!,
            width: widget.iconSize,
            height: widget.iconSize,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(widget.icon, size: widget.iconSize, color: color);

    Widget button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onHover: (value) => setState(() => _hovered = value),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: _active ? accentColor : baseColor),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              builder: (context, color, _) => iconFor(color ?? baseColor),
            ),
          ),
        ),
      ),
    );

    if (widget.badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colorScheme.surface, width: 1.5),
              ),
              child: Text(
                widget.badge!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
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
        scale: _active ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
