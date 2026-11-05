import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Avatar pengguna dengan fallback inisial jika gambar gagal dimuat.
///
/// Mendukung tampilan grup (ikon orang) serta badge status online.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.isGroup = false,
    this.showOnlineBadge = false,
  });

  final String? imageUrl;
  final String name;
  final double size;
  final bool isGroup;
  final bool showOnlineBadge;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts[0].characters.take(1).toString() +
            parts[1].characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: isGroup
                  ? _groupPlaceholder()
                  : (imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialPlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _initialPlaceholder();
                          },
                        )
                      : _initialPlaceholder()),
            ),
          ),
          if (showOnlineBadge && !isGroup)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialPlaceholder() {
    return Container(
      color: AppColors.pinkSoft,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.primary,
          fontSize: size * 0.34,
        ),
      ),
    );
  }

  Widget _groupPlaceholder() {
    return Container(
      color: AppColors.pinkSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.groups_rounded,
        color: AppColors.primary,
        size: size * 0.55,
      ),
    );
  }
}
