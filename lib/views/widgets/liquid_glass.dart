import 'dart:ui';

import 'package:flutter/material.dart';

/// Permukaan "liquid glass": blur isi di belakangnya, lapisan putih transparan,
/// dan kilau (specular) di tepi atas agar terlihat seperti kaca.
///
/// Dipakai untuk bottom navbar dan kartu. Efek blur hanya terlihat bila ada
/// konten yang tergambar di belakang widget ini.
class LiquidGlass extends StatelessWidget {
  /// Isi kaca (ikon, teks, kartu, dan sebagainya).
  final Widget child;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Radius sudut kaca.
  final double borderRadius;

  /// Kekuatan blur latar. Semakin besar semakin buram.
  final double blurSigma;

  /// Warna dasar kaca.
  final Color tint;

  /// Opasitas lapisan [tint] (0..1).
  final double tintOpacity;

  /// Warna garis tepi (rim) kaca.
  final Color borderColor;

  /// Ketebalan garis tepi.
  final double borderWidth;

  /// Tampilkan bayangan lembut di bawah kaca.
  final bool showShadow;

  const LiquidGlass({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 28,
    this.blurSigma = 20,
    this.tint = Colors.white,
    this.tintOpacity = 0.62,
    this.borderColor = const Color(0x99FFFFFF),
    this.borderWidth = 1.2,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor, width: borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: tintOpacity),
                  tint.withValues(alpha: tintOpacity * 0.72),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Kilau atas: pantulan cahaya pada permukaan kaca.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: const Alignment(0.6, 0.35),
                          stops: const [0, 0.45, 1],
                          colors: [
                            Colors.white.withValues(alpha: 0.40),
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu kaca dengan padding standar.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return LiquidGlass(
      margin: margin,
      borderRadius: borderRadius,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
