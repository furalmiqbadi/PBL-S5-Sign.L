import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_bottom_nav_bar.dart' show kDummyAvatarUrl;
import 'section_header.dart';

/// Header halaman Beranda: logo aplikasi + nama "Sign.L" di kiri, lalu di
/// kanan tombol notifikasi (dengan badge), tombol pesan langsung (DM), dan
/// foto profil pengguna.
class HomeHeader extends StatelessWidget {
  /// Jumlah notifikasi belum dibaca. Badge disembunyikan bila 0.
  final int notificationCount;

  /// URL foto profil pengguna. Null = pakai foto dummy bawaan.
  final String? avatarUrl;

  final VoidCallback? onNotifications;
  final VoidCallback? onMessages;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    this.notificationCount = 3,
    this.avatarUrl,
    this.onNotifications,
    this.onMessages,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Sign.L',
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
        const SizedBox(width: 4),
        HeaderIconButton(
          svgAsset: 'assets/images/dm_fix.svg',
          semanticLabel: 'Pesan langsung',
          onTap: onMessages,
        ),
        const SizedBox(width: 4),
        _HeaderAvatar(url: avatarUrl, onTap: onAvatarTap),
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
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF57C00), Color(0xFFD81B60)],
        ),
      ),
      child: const Icon(
        Icons.sign_language_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Avatar bulat untuk header, dengan cadangan ikon bila foto gagal dimuat.
class _HeaderAvatar extends StatelessWidget {
  final String? url;
  final VoidCallback? onTap;

  const _HeaderAvatar({this.url, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = url ?? kDummyAvatarUrl;

    return Semantics(
      button: true,
      label: 'Profil',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.network(
                photo,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
