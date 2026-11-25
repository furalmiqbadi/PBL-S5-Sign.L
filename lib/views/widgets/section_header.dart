import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';

/// Kerangka bersama untuk header bagian (section) di dalam aplikasi.
///
/// Memberi chrome yang konsisten di semua header: judul besar di kiri,
/// deretan aksi di kanan. Latar header transparan agar gradasi halaman
/// ([AppBackground]) menyambung ke konten di bawahnya tanpa garis potong.
/// Dipakai oleh header Beranda, Materi, Komunitas, Profil, dan halaman yang
/// di-*push* agar tinggi serta gayanya seragam.
class SectionHeader extends StatelessWidget {
  /// Tinggi tetap area konten header.
  ///
  /// Disamakan dengan tinggi kontrol tertinggi (tombol ikon/avatar 48px)
  /// supaya semua header punya tinggi identik, termasuk yang hanya berisi
  /// konten pendek seperti [StatPill].
  static const double contentHeight = 48;

  /// Font display untuk semua judul header tab.
  ///
  /// Memakai Plus Jakarta Sans (font aplikasi sesuai `docs/prd/design.md`)
  /// agar judul tab seragam dengan tipografi halaman lainnya. Ukurannya 22px:
  /// satu tingkat di atas judul halaman yang di-*push* (20px) supaya hierarki
  /// navigasi tetap terbaca.
  static TextStyle displayStyle(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return AppTextStyles.headlineSmall.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.15,
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

  /// Padding luar header. Bisa dikosongkan bila induk sudah memberi padding
  /// horizontal (mis. halaman Beranda yang memakai ListView berpaddding).
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.leading,
    this.titleStyle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      // Latar transparan: gradasi latar halaman ([AppBackground]) menyambung
      // mulus dengan konten di bawahnya, tanpa garis potong.
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
              // Aksi dibatasi maksimal ~62% lebar layar lalu diperkecil
              // seragam bila tidak muat, sehingga header tidak pernah
              // meluap di ponsel sempit (mis. 4 pill statistik Materi).
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.62,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
              ),
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
/// Gaya seragam dengan tombol header Beranda: kotak membulat 48x48 berwarna
/// putih, bergaris tepi, dan berbayang lembut. Saat disorot (web/desktop)
/// atau ditekan, tombol memakai latar aksen lembut dan ikon berubah ke warna
/// aksen tema — pola umpan balik yang sama di semua tab.
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
    final radius = BorderRadius.circular(AppRadii.md);

    // Ikon dirender ulang dengan warna animasi saat state berubah.
    Widget iconFor(Color color) => widget.svgAsset != null
        ? SvgPicture.asset(
            widget.svgAsset!,
            width: widget.iconSize,
            height: widget.iconSize,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(widget.icon, size: widget.iconSize, color: color);

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _active ? AppColors.pinkSoft : AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color:
              _active ? accentColor.withValues(alpha: 0.32) : AppColors.border,
        ),
        boxShadow: _active ? AppShadows.card : AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onHover: (value) => setState(() => _hovered = value),
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
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border:
                    Border.all(color: theme.colorScheme.surface, width: 1.5),
              ),
              child: Text(
                widget.badge!,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
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
        scale: _active ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
