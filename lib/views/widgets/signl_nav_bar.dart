import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_bottom_nav_bar.dart';

/// Wrapper Sign.L di atas [AppBottomNavBar] milik tim.
///
/// Menyusun 5 tab yang sama seperti `MainShell`:
/// `0 Beranda · 1 Kuis · 2 Materi (tengah) · 3 Komunitas · 4 Profil`.
///
/// Dipakai pada halaman yang di-*push* (Chat, Notifikasi). Karena kontrol tab
/// utama berada di `MainShell`, menekan item secara default akan menutup
/// halaman ini dan kembali ke shell. Kirim [onSelect]/[onCenterTap] untuk
/// mengganti perilaku tersebut.
class SignlNavBar extends StatelessWidget {
  const SignlNavBar({
    super.key,
    this.selectedIndex = 3,
    this.onSelect,
    this.onCenterTap,
  });

  /// Indeks tab aktif (0..4, dengan 2 = tombol tengah).
  final int selectedIndex;

  final ValueChanged<int>? onSelect;
  final VoidCallback? onCenterTap;

  /// Tepat 4 item untuk slot kiri/kanan; tombol tengah terpisah.
  static const List<AppNavItem> _items = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    AppNavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Kuis',
    ),
    AppNavItem(
      svgAsset: 'assets/images/komunitas.svg',
      label: 'Komunitas',
    ),
    AppNavItem(imageUrl: _profilePhotoUrl),
  ];

  static const String? _profilePhotoUrl = null;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      items: _items,
      selectedIndex: selectedIndex,
      onSelect: (index) {
        if (onSelect != null) {
          onSelect!(index);
        } else {
          Navigator.of(context).maybePop();
        }
      },
      onCenterTap: () {
        if (onCenterTap != null) {
          onCenterTap!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      centerIcon: Icons.menu_book_rounded,
      centerLabel: 'Materi',
      palette: const NavBarPalette(
        barColor: AppColors.surface,
        inactiveColor: AppColors.neutral,
        activeColor: AppColors.primary,
        centerGradientStart: Color(0xFFF57C00),
        centerGradientEnd: Color(0xFFD81B60),
      ),
    );
  }
}
