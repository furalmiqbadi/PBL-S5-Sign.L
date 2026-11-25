import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar kanvas bersama untuk seluruh tab utama.
///
/// Memberi gradasi sangat lembut dari putih kebiruan di atas ke abu-biru di
/// bawah, ditambah satu aura biru di kanan atas. Dengan begitu header, kartu,
/// dan latar halaman memakai keluarga warna yang sama sehingga tidak terlihat
/// berbeda potongan.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFBFDFF),
            AppColors.background,
            Color(0xFFEEF3FB),
          ],
          stops: [0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: [
          // Aura biru tipis, senada aksen header dan tombol utama.
          Positioned(
            top: -140,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x1F0062EE), Color(0x000062EE)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x140BB59E), Color(0x000BB59E)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
