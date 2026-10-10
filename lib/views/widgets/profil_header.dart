import 'package:flutter/material.dart';

import 'section_header.dart';

/// Header halaman Profil: judul di kiri, lalu di kanan tombol pesan langsung
/// (DM) dan tombol pengaturan. Keduanya ikon polos tanpa latar.
class ProfilHeader extends StatelessWidget {
  final VoidCallback? onMessages;
  final VoidCallback? onSettings;

  const ProfilHeader({
    super.key,
    this.onMessages,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Profil',
      actions: [
        HeaderIconButton(
          svgAsset: 'assets/images/dm_fix.svg',
          semanticLabel: 'Pesan langsung',
          onTap: onMessages,
        ),
        const SizedBox(width: 4),
        HeaderIconButton(
          svgAsset: 'assets/images/setting_fix.svg',
          semanticLabel: 'Pengaturan',
          onTap: onSettings,
        ),
      ],
    );
  }
}
