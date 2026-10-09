import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'section_header.dart';

/// Header untuk halaman yang di-*push* (Chat, Notifikasi).
///
/// Menggabungkan tombol kembali di kiri dengan [SectionHeader] milik tim di
/// kanannya, di dalam satu bilah putih yang sama agar garis pemisah bawah
/// tetap menyambung. `SectionHeader` sendiri tidak menyediakan slot leading,
/// sehingga tombol kembali ditambahkan di sini tanpa mengubah file teman.
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
    if (!showBack) {
      return SectionHeader(title: title, actions: actions);
    }

    // IntrinsicHeight memberi tinggi yang terbatas & seragam untuk kedua anak
    // sehingga garis pemisah bawah menyambung tanpa perlu tinggi tetap.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackButton(onTap: () => Navigator.of(context).maybePop()),
          Expanded(child: SectionHeader(title: title, actions: actions)),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Center(
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          iconSize: 20,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
    );
  }
}
