import 'package:flutter/material.dart';
import '../setting/setting_screen.dart';
import 'section_header.dart';

/// Header halaman Profil: judul di kiri, lalu di kanan tombol pesan langsung
/// (DM) dan tombol pengaturan. Keduanya ikon polos tanpa latar.
/// Header halaman Profil: judul di kiri, lalu di kanan tombol pengaturan.

class ProfilHeader extends StatelessWidget {
  // [Kode Asli] final VoidCallback? onMessages; -> Disembunyikan karena desain saat ini tidak memakai DM
  // final VoidCallback? onMessages;
  final VoidCallback? onSettings;

  const ProfilHeader({
    super.key,
    // this.onMessages,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Profil',
      actions: [
        /* 
        [Kode Asli Tim-mu] Tombol DM (Pesan Langsung) 
        Aku hide/comment karena di desain barumu tidak ada logo DM, hanya Gear Setting.
        Jika nanti mau dipakai lagi, tinggal di-uncomment.
        
        HeaderIconButton(
          svgAsset: 'assets/images/dm_fix.svg',
          semanticLabel: 'Pesan langsung',
          onTap: onMessages,
        ),
        const SizedBox(width: 4),
        */
        
        // [Tugasmu] Tombol Pengaturan (Settings) yang sudah dilink ke SettingScreen
        HeaderIconButton(
          svgAsset: 'assets/images/setting_fix.svg',
          semanticLabel: 'Pengaturan',
          onTap: onSettings ?? () {
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
