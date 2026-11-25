import 'package:flutter/material.dart';

import '../../models/friend_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';
import 'user_avatar.dart';

/// Label kecil berhuruf kapital sebagai pemisah bagian dalam daftar.
class BagianLabel extends StatelessWidget {
  const BagianLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Tombol pil ringkas untuk aksi pertemanan (Tambah, Terima, Batalkan, Pesan).
class TemanPillButton extends StatelessWidget {
  const TemanPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.terisi = false,
    this.minWidth = 84,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool terisi;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(minWidth, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      textStyle: WidgetStatePropertyAll(AppTextStyles.labelLarge),
    );

    if (terisi) {
      return FilledButton(
        onPressed: onPressed,
        style: style.copyWith(
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textOnPrimary),
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
        onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Satu orang dalam daftar: avatar, nama, keterangan, dan aksi di kanan.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.nama,
    this.username = '',
    this.peran = '',
    this.avatarUrl,
    this.isOnline = false,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String nama;
  final String username;
  final String peran;
  final String? avatarUrl;
  final bool isOnline;

  /// Mengganti keterangan bawaan (`@username · peran` atau status online).
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  String get _subtitle {
    if (subtitle != null) return subtitle!;
    if (isOnline) return 'Aktif sekarang';
    final bagian = [
      if (username.isNotEmpty) '@$username',
      if (peran.isNotEmpty) peran,
    ];
    return bagian.isEmpty ? 'Anggota komunitas' : bagian.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: UserAvatar(
        imageUrl: avatarUrl,
        name: nama,
        showOnlineBadge: isOnline,
        size: 46,
      ),
      title: Text(
        nama,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.titleSmall,
      ),
      subtitle: Text(
        _subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Aksi di kanan tile berdasarkan status relasi pertemanan.
class TemanStatusAksi extends StatelessWidget {
  const TemanStatusAksi({
    super.key,
    required this.status,
    required this.sibuk,
    required this.onTambah,
    required this.onBatalkan,
    required this.onIkutiBalik,
    required this.onBuka,
  });

  final StatusTeman status;
  final bool sibuk;
  final VoidCallback onTambah;
  final VoidCallback onBatalkan;
  final VoidCallback onIkutiBalik;
  final VoidCallback onBuka;

  @override
  Widget build(BuildContext context) {
    if (sibuk) {
      return const SizedBox(
        width: 96,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return switch (status) {
      StatusTeman.tidakAda || StatusTeman.ditolak => TemanPillButton(
          label: 'Tambah',
          onPressed: onTambah,
          terisi: true,
        ),
      StatusTeman.menungguMereka => TemanPillButton(
          label: 'Menunggu',
          onPressed: onBatalkan,
        ),
      StatusTeman.menungguKita => TemanPillButton(
          label: 'Terima',
          onPressed: onIkutiBalik,
          terisi: true,
        ),
      StatusTeman.berteman => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: onBuka,
            tooltip: 'Kirim pesan',
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      StatusTeman.diblokir => const TemanPillButton(
          label: 'Diblokir',
          onPressed: null,
        ),
    };
  }
}
