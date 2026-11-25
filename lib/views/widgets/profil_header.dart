import 'package:flutter/material.dart';
import '../setting/setting_screen.dart';
import 'section_header.dart';

/// Header halaman Profil: judul di kiri, tombol Teman dan pengaturan di kanan.
class ProfilHeader extends StatelessWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onTeman;

  /// Jumlah permintaan teman yang belum dijawab; badge disembunyikan bila 0.
  final int permintaanTeman;

  const ProfilHeader({
    super.key,
    this.onSettings,
    this.onTeman,
    this.permintaanTeman = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Profil',
      actions: [
        HeaderIconButton(
          icon: Icons.people_alt_outlined,
          semanticLabel: 'Teman',
          badge: permintaanTeman > 0 ? '$permintaanTeman' : null,
          onTap: onTeman,
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          svgAsset: 'assets/images/setting_fix.svg',
          semanticLabel: 'Pengaturan',
          onTap: onSettings ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingScreen()),
                );
              },
        ),
      ],
    );
  }
}
