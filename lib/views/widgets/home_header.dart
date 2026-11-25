import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nama_tampil.dart';
import '../theme/app_colors.dart';
import 'app_ui.dart';
import 'section_header.dart';
import 'user_avatar.dart';

/// Header halaman Beranda: logo aplikasi + nama "Sign.L" di kiri, lalu di
/// kanan tombol notifikasi (dengan badge), tombol pesan langsung (DM), dan
/// foto profil pengguna.
class HomeHeader extends StatelessWidget {
  /// Jumlah notifikasi belum dibaca. Badge disembunyikan bila 0.
  final int notificationCount;

  /// URL foto profil pengguna. Null = tampilkan inisial [userName].
  final String? avatarUrl;

  /// Nama pengguna untuk inisial avatar cadangan.
  final String userName;

  final VoidCallback? onNotifications;
  final VoidCallback? onMessages;
  final VoidCallback? onAvatarTap;

  /// Padding luar header. Isi [EdgeInsets.zero] bila induk sudah memberi
  /// padding horizontal (mis. ListView Beranda) agar logo rata dengan kartu.
  final EdgeInsetsGeometry padding;

  const HomeHeader({
    super.key,
    this.notificationCount = 3,
    this.avatarUrl,
    this.userName = labelNamaNetral,
    this.onNotifications,
    this.onMessages,
    this.onAvatarTap,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Sign.L',
      padding: padding,
      leading: const _AppLogo(),
      // Wordmark memakai font script Grand Hotel (nuansa seperti logo
      // Instagram, tetapi typeface berbeda).
      titleStyle: GoogleFonts.grandHotel(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      actions: [
        HeaderIconButton(
          svgAsset: 'assets/images/notifikasi_fix.svg',
          semanticLabel: 'Notifikasi',
          badge: notificationCount > 0 ? '$notificationCount' : null,
          onTap: onNotifications,
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          svgAsset: 'assets/images/dm_fix.svg',
          semanticLabel: 'Pesan langsung',
          onTap: onMessages,
        ),
        const SizedBox(width: 8),
        _HeaderAvatar(url: avatarUrl, name: userName, onTap: onAvatarTap),
      ],
    );
  }
}

/// Logo aplikasi: kotak membulat bergradien dengan ikon bahasa isyarat.
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        gradient: AppColors.brandGradient,
      ),
      child: const Icon(
        Icons.sign_language_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Avatar bulat untuk header, dengan inisial nama sebagai cadangan.
class _HeaderAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final VoidCallback? onTap;

  const _HeaderAvatar({this.url, required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = url?.trim();
    final photoUrl = (photo == null || photo.isEmpty) ? null : photo;

    // Chrome sama dengan [HeaderIconButton]: kotak 48px putih berbingkai
    // dengan bayangan lembut, hanya saja isinya avatar bulat.
    return Semantics(
      button: true,
      label: 'Profil',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: UserAvatar(
                imageUrl: photoUrl,
                name: name,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
