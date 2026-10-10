import 'package:flutter/material.dart';

import 'section_header.dart';

/// Header halaman Komunitas: judul di kiri, lalu di kanan tombol papan
/// peringkat (leaderboard) dan tombol pesan langsung (DM) dengan badge
/// jumlah pesan belum dibaca.
class KomunitasHeader extends StatelessWidget {
  /// Jumlah pesan belum dibaca. Badge disembunyikan bila 0.
  final int unreadCount;

  final VoidCallback? onLeaderboard;
  final VoidCallback? onMessages;

  const KomunitasHeader({
    super.key,
    this.unreadCount = 2,
    this.onLeaderboard,
    this.onMessages,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Komunitas',
      actions: [
        HeaderIconButton(
          svgAsset: 'assets/images/leaderboard_fix.svg',
          semanticLabel: 'Papan peringkat',
          onTap: onLeaderboard,
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          svgAsset: 'assets/images/dm_fix.svg',
          semanticLabel: 'Pesan langsung',
          badge: unreadCount > 0 ? '$unreadCount' : null,
          onTap: onMessages,
        ),
      ],
    );
  }
}
