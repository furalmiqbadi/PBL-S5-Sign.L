import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'section_header.dart';

/// Header untuk halaman yang di-*push* (Chat, Notifikasi).
///
/// Menumpang [SectionHeader] agar padding, tinggi, tipografi, dan tombol
/// kembali sama persis dengan header tab lain. Tombol kembali dipasang
/// sebagai `leading` sehingga judul tetap rata kiri dengan konten halaman.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: title,
      // 20px (headlineSmall): satu tingkat di bawah judul tab 22px supaya
      // hierarki navigasi tetap terbaca.
      titleStyle: AppTextStyles.headlineSmall,
      leading: showBack
          ? HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Kembali',
              onTap: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
    );
  }
}
