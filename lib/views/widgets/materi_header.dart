import 'package:flutter/material.dart';

import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
import '../theme/app_colors.dart';
import 'section_header.dart';
import 'stat_pill.dart';

/// Header halaman Materi/Kuis: judul di kiri, tiga pill statistik di kanan
/// (streak, XP, poin) yang dibaca dari tabel `profiles`.
class MateriHeader extends StatefulWidget {
  /// Judul halaman.
  final String title;

  const MateriHeader({super.key, this.title = 'Materi'});

  static const Color streakAccent = AppColors.tertiary;
  static const Color expAccent = AppColors.primary;
  static const Color poinAccent = AppColors.secondary;

  @override
  State<MateriHeader> createState() => _MateriHeaderState();
}

class _MateriHeaderState extends State<MateriHeader> {
  final ProfilService _service = ProfilService();
  ProfilPengguna? _profil;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final profil = await _service.profilSaya();
    if (!mounted || profil == null) return;
    setState(() => _profil = profil);
  }

  @override
  Widget build(BuildContext context) {
    final streak = _profil?.streak ?? 0;
    final xp = _profil?.xp ?? 0;
    final points = _profil?.points ?? 0;

    return SectionHeader(
      title: widget.title,
      actions: [
        StatPill(
          svgAsset: 'assets/images/streak_fix.svg',
          value: '$streak',
          accent: MateriHeader.streakAccent,
          semanticLabel: 'Streak $streak hari',
        ),
        const SizedBox(width: 8),
        StatPill(
          icon: Icons.bolt_rounded,
          value: ProfilPengguna.formatAngka(xp),
          accent: MateriHeader.expAccent,
          semanticLabel: '$xp XP',
        ),
        const SizedBox(width: 8),
        StatPill(
          svgAsset: 'assets/images/diamond_fix.svg',
          value: ProfilPengguna.formatAngka(points),
          accent: MateriHeader.poinAccent,
          semanticLabel: '$points poin',
        ),
      ],
    );
  }
}
