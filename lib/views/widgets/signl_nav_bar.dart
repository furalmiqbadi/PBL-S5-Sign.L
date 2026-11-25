import 'package:flutter/material.dart';

import '../../models/nama_tampil.dart';
import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
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
class SignlNavBar extends StatefulWidget {
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

  @override
  State<SignlNavBar> createState() => _SignlNavBarState();
}

class _SignlNavBarState extends State<SignlNavBar> {
  final ProfilService _profilService = ProfilService();
  ProfilPengguna? _profil;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final profil = await _profilService.profilSaya();
    if (!mounted) return;
    setState(() => _profil = profil);
  }

  /// Tepat 4 item untuk slot kiri/kanan; tombol tengah terpisah.
  static const List<AppNavItem> _itemsDasar = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      items: [
        ..._itemsDasar,
        AppNavItem(
          imageUrl: _profil?.avatarUrl,
          name: (_profil?.nama.isNotEmpty ?? false)
              ? _profil!.nama
              : labelNamaNetral,
        ),
      ],
      selectedIndex: widget.selectedIndex,
      onSelect: (index) {
        final onSelect = widget.onSelect;
        if (onSelect != null) {
          onSelect(index);
        } else {
          Navigator.of(context).maybePop();
        }
      },
      onCenterTap: () {
        final onCenterTap = widget.onCenterTap;
        if (onCenterTap != null) {
          onCenterTap();
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
        centerGradientStart: AppColors.brandGradientStart,
        centerGradientEnd: AppColors.brandGradientEnd,
      ),
    );
  }
}
