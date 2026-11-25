import 'package:flutter/material.dart';

import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';
import 'section_header.dart';
import 'stat_pill.dart';

/// Header halaman latihan huruf: tombol kembali dan dua pill statistik
/// (streak dan total XP) yang dibaca dari tabel `profiles`.
///
/// Transparan serta memakai tinggi dan padding yang sama dengan
/// [SectionHeader], sehingga header menyambung dengan latar halaman dan pill
/// statistiknya seragam dengan header tab Materi.
class IsiMateriHeader extends StatefulWidget {
  final VoidCallback onBack;
  const IsiMateriHeader({super.key, required this.onBack});

  @override
  State<IsiMateriHeader> createState() => _IsiMateriHeaderState();
}

class _IsiMateriHeaderState extends State<IsiMateriHeader> {
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

    return Container(
      // Transparan agar latar halaman mengalir tanpa potongan warna.
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: SectionHeader.contentHeight,
        child: Row(
          children: [
            _BackButton(onTap: widget.onBack),
            const Spacer(),
            StatPill(
              svgAsset: 'assets/images/streak_fix.svg',
              value: '$streak',
              accent: AppColors.tertiary,
              semanticLabel: 'Streak $streak hari',
            ),
            const SizedBox(width: 8),
            StatPill(
              svgAsset: 'assets/images/diamond_fix.svg',
              value: ProfilPengguna.formatAngka(xp),
              accent: AppColors.secondary,
              semanticLabel: '$xp XP',
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol kembali berlabel, memakai kotak putih berbingkai yang sama dengan
/// [HeaderIconButton] di header tab lain.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Semantics(
      button: true,
      label: 'Kembali',
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kembali',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
