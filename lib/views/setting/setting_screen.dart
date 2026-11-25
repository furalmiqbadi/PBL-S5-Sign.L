import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../models/app_settings.dart';
import '../../models/nama_tampil.dart';
import '../../models/profil_model.dart';
import '../../services/profil_service.dart';
import '../auth/auth_views.dart';
import '../edit/edit_profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/user_avatar.dart';

// ============================================================================
// 1. KONSTANTA
// ============================================================================

/// Versi mengikuti `pubspec.yaml` (1.0.0+1). Ganti bila versi dinaikkan.
const String _appVersion = 'Versi 1.0.0 (Build 1)';

// ============================================================================
// 2. SCREEN UTAMA
// ============================================================================

/// Halaman Pengaturan Akun. Di-push dari ikon gear di [ProfilHeader], bukan
/// tab di MainShell. View hanya memanggil [SettingsController] dan
/// fungsi `konfirmasiKeluar`; tidak ada akses storage/service langsung.
class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ProfilService _profilService = ProfilService();
  ProfilPengguna? _profil;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final profil = await _profilService.profilSaya();
    if (!mounted) return;
    setState(() => _profil = profil);
  }

  void _toast(String message) {
    showAppSnackBar(
      context,
      message,
      type: AppSnackType.info,
      duration: const Duration(seconds: 2),
    );
  }

  // --------------------------------------------------------------------------
  // 2a. ACTIONS (picker, logout, navigasi)
  // --------------------------------------------------------------------------

  Future<void> _pickDialect(SettingsController c) async {
    final v = await _pickOption<String>(
      title: 'Dialek Isyarat Utama',
      selected: c.settings.dialect,
      options: const [
        _Option('BISINDO', 'BISINDO', 'Bahasa Isyarat Indonesia'),
        _Option('SIBI', 'SIBI', 'Sistem Isyarat Bahasa Indonesia'),
      ],
    );
    if (v != null) await c.setDialect(v);
  }

  Future<void> _pickTextSize(SettingsController c) async {
    final v = await _pickOption<TextSizeOption>(
      title: 'Ukuran Teks',
      selected: c.settings.textSize,
      options: [
        for (final o in TextSizeOption.values)
          _Option(o, o.label, 'Skala ${(o.scale * 100).round()}%'),
      ],
    );
    if (v != null) await c.setTextSize(v);
  }

  Future<void> _pickLanguage(SettingsController c) async {
    final v = await _pickOption<String>(
      title: 'Bahasa Aplikasi',
      selected: c.settings.language,
      options: const [
        _Option('id', 'Bahasa Indonesia', null),
        _Option('en', 'English', null),
      ],
    );
    if (v == null) return;
    await c.setLanguage(v);
    if (v == 'en') {
      _toast('Terjemahan English belum tersedia, pilihan disimpan.');
    }
  }

  Future<void> _pickReminderTime(SettingsController c) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: c.settings.reminderHour,
        minute: c.settings.reminderMinute,
      ),
      helpText: 'Waktu pengingat harian',
    );
    if (t != null) await c.setReminderTime(t.hour, t.minute);
  }

  /// Bottom sheet pilihan generik. Mengembalikan nilai yang dipilih, atau null
  /// bila sheet ditutup tanpa memilih.
  Future<T?> _pickOption<T>({
    required String title,
    required T selected,
    required List<_Option<T>> options,
  }) {
    return showAppBottomSheet<T>(
      context,
      title: title,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            AppSheetOptionTile(
              icon: o.value == selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              iconColor:
                  o.value == selected ? AppColors.primary : AppColors.textMuted,
              iconBackground: o.value == selected
                  ? AppColors.pinkSoft
                  : AppColors.surfaceMuted,
              title: o.title,
              subtitle: o.subtitle,
              isSelected: o.value == selected,
              onTap: () => Navigator.pop(ctx, o.value),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() => konfirmasiKeluar(context);

  void _openEditProfile() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      );

  // --------------------------------------------------------------------------
  // 2b. ISI SECTION
  // --------------------------------------------------------------------------

  List<_Section> _sections(SettingsController c) {
    final s = c.settings;
    return [
      _Section(
        title: 'PREFERENSI BELAJAR & ISYARAT',
        trailing: s.dialect,
        rows: [
          _Row(
            child: _NavTile(
              icon: Icons.sign_language_rounded,
              iconColor: AppColors.primary,
              iconBg: AppColors.pinkSoft,
              title: 'Dialek Isyarat Utama',
              subtitle: s.dialect == 'SIBI'
                  ? 'SIBI (Sistem Isyarat Bahasa Indonesia)'
                  : 'BISINDO (Bahasa Isyarat Indonesia)',
              onTap: () => _pickDialect(c),
            ),
          ),
          _Row(
            child: _SwitchTile(
              icon: Icons.flip_rounded,
              iconColor: AppColors.tertiary,
              iconBg: AppColors.orangeSoft,
              title: 'Mode Cermin (Mirror View)',
              subtitle: 'Membalikkan arah peragaan video',
              value: s.mirrorMode,
              onChanged: c.setMirrorMode,
            ),
          ),
        ],
      ),
      _Section(
        title: 'NOTIFIKASI & PENGINGAT',
        rows: [
          _Row(
            child: _SwitchTile(
              icon: Icons.schedule_rounded,
              iconColor: AppColors.secondary,
              iconBg: AppColors.purpleSoft,
              title: 'Pengingat Latihan Harian',
              subtitleWidget: Row(
                children: [
                  // Chip jam bisa diketuk untuk mengganti waktu pengingat.
                  InkWell(
                    onTap: s.dailyReminder ? () => _pickReminderTime(c) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.reminderLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Setiap Hari',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              value: s.dailyReminder,
              onChanged: c.setDailyReminder,
            ),
          ),
          _Row(
            child: _SwitchTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.tertiary,
              iconBg: AppColors.orangeSoft,
              title: 'Peringatan Streak 7 Hari',
              subtitle: 'Kabar capaian dan lencana baru',
              value: s.streakReminder,
              onChanged: c.setStreakReminder,
            ),
          ),
        ],
      ),
      _Section(
        title: 'TAMPILAN & AKSESIBILITAS',
        rows: [
          _Row(
            child: _NavTile(
              icon: Icons.text_fields_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Ukuran Teks & Kontras Tinggi',
              subtitle: '${s.textSize.label} (Optimal untuk Pembelajar Tuli)',
              onTap: () => _pickTextSize(c),
            ),
          ),
          _Row(
            child: _SwitchTile(
              icon: Icons.vibration_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Getaran Responsif (Haptic Feedback)',
              subtitle: 'Getaran halus saat isyarat berhasil',
              value: s.haptic,
              onChanged: c.setHaptic,
            ),
          ),
        ],
      ),
      _Section(
        title: 'AKUN & KEAMANAN',
        rows: [
          _Row(
            child: _NavTile(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Kata Sandi & Keamanan',
              subtitle: 'Ubah kata sandi akun',
              onTap: () => _toast('Halaman ubah kata sandi belum tersedia.'),
            ),
          ),
          _Row(
            child: _NavTile(
              icon: Icons.language_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Bahasa Aplikasi',
              subtitle: c.languageLabel,
              onTap: () => _pickLanguage(c),
            ),
          ),
        ],
      ),
      _Section(
        title: 'BANTUAN & INFO',
        rows: [
          _Row(
            child: _NavTile(
              icon: Icons.help_outline_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Pusat Bantuan & Komunitas',
              subtitle: 'Tutorial isyarat & FAQ',
              onTap: () => _toast('Pusat Bantuan belum tersedia.'),
            ),
          ),
          _Row(
            child: _NavTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.fieldFill,
              title: 'Tentang Sign.L',
              subtitle: _appVersion,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Sign.L',
                applicationVersion: _appVersion,
                applicationLegalese: 'Sign.L Indonesia',
              ),
            ),
          ),
        ],
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // 2c. BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SettingsController>();
    final sections = _sections(c);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
        ),
        title: const Text('Pengaturan Akun'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Opsi lainnya',
            onSelected: (v) async {
              if (v == 'reset') {
                await c.reset();
                _toast('Pengaturan dikembalikan ke default.');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'reset', child: Text('Atur ulang pengaturan')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProfileCard(onManage: _openEditProfile, profil: _profil),
            const SizedBox(height: 8),
            for (final section in sections) ...[
              _SectionLabel(title: section.title, trailing: section.trailing),
              _SettingsCard(rows: section.rows),
            ],
            const SizedBox(height: 24),
            _LogoutButton(onTap: _confirmLogout),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Sign.L Indonesia  •  Bersama Membuka Akses Komunikasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. DATA HOLDERS
// ============================================================================

class _Option<T> {
  final T value;
  final String title;
  final String? subtitle;
  const _Option(this.value, this.title, this.subtitle);
}

class _Row {
  final Widget child;
  const _Row({required this.child});
}

class _Section {
  final String title;
  final String? trailing;
  final List<_Row> rows;
  const _Section({required this.title, this.trailing, required this.rows});
}

// ============================================================================
// 4. WIDGET KARTU PROFIL
// ============================================================================

class _ProfileCard extends StatelessWidget {
  final VoidCallback onManage;
  final ProfilPengguna? profil;
  const _ProfileCard({required this.onManage, this.profil});

  @override
  Widget build(BuildContext context) {
    final nama =
        profil?.nama.isNotEmpty == true ? profil!.nama : labelNamaNetral;
    final sub =
        'Level ${profil?.level ?? 1} · ${profil?.roleLabel ?? 'Pembelajar'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // Avatar dengan ring gradient
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pinkSoft,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surface),
              child: UserAvatar(
                imageUrl: (profil?.avatarUrl.isEmpty ?? true)
                    ? null
                    : profil!.avatarUrl,
                name: nama,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nama + level (Expanded agar tombol di kanan tidak overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tombol menuju halaman Edit Profile
          InkWell(
            onTap: onManage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.pinkSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. WIDGET SECTION & TILE
// ============================================================================

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionLabel({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    );

class _SettingsCard extends StatelessWidget {
  final List<_Row> rows;
  const _SettingsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 66,
                    endIndent: 16,
                    color: AppColors.border),
              rows[i].child,
            ],
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  const _TileIcon({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 19, color: color),
      );
}

class _TileText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  const _TileText({required this.title, this.subtitle, this.subtitleWidget});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          subtitleWidget ??
              Text(
                subtitle ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
        ],
      );
}

/// Baris dengan panah (membuka picker / halaman lain).
class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _TileIcon(icon: icon, color: iconColor, bg: iconBg),
              const SizedBox(width: 12),
              Expanded(child: _TileText(title: title, subtitle: subtitle)),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris dengan switch on/off.
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _TileIcon(icon: icon, color: iconColor, bg: iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: _TileText(
              title: title,
              subtitle: subtitle,
              subtitleWidget: subtitleWidget,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. TOMBOL LOGOUT
// ============================================================================

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Keluar dari Akun'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        backgroundColor: AppColors.dangerSoft,
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
    );
  }
}
