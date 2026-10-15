import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/app_settings.dart';
import '../auth/auth_views.dart';
import '../edit/edit_profile_screen.dart';
import '../theme/app_colors.dart';

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
/// [AuthController]; tidak ada akses storage/service langsung.
class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
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
    if (v == 'en') _toast('Terjemahan English belum tersedia, pilihan disimpan.');
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
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  title: Text(
                    o.title,
                    style: TextStyle(
                      fontWeight:
                          o.value == selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: o.subtitle == null ? null : Text(o.subtitle!),
                  trailing: o.value == selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o.value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Kamu perlu masuk lagi untuk melanjutkan belajar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await context.read<AuthController>().logout();
    if (!mounted) return;
    // Hapus seluruh stack agar tombol back tidak kembali ke halaman ber-login.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

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
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.reminderLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
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
              iconBg: AppColors.border,
              title: 'Ukuran Teks & Kontras Tinggi',
              subtitle: '${s.textSize.label} (Optimal untuk Pembelajar Tuli)',
              onTap: () => _pickTextSize(c),
            ),
          ),
          _Row(
            child: _SwitchTile(
              icon: Icons.vibration_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.border,
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
              iconBg: AppColors.border,
              title: 'Kata Sandi & Keamanan',
              subtitle: 'Ubah kata sandi akun',
              onTap: () => _toast('Halaman ubah kata sandi belum tersedia.'),
            ),
          ),
          _Row(
            child: _NavTile(
              icon: Icons.language_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.border,
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
              iconBg: AppColors.border,
              title: 'Pusat Bantuan & Komunitas',
              subtitle: 'Tutorial isyarat & FAQ',
              onTap: () => _toast('Pusat Bantuan belum tersedia.'),
            ),
          ),
          _Row(
            child: _NavTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textPrimary,
              iconBg: AppColors.border,
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
        ),
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
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
              PopupMenuItem(value: 'reset', child: Text('Atur ulang pengaturan')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProfileCard(onManage: _openEditProfile),
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
  const _ProfileCard({required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // Avatar dengan ring gradient
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: ClipOval(
                child: Image.network(
                  'https://i.pravatar.cc/150?img=47',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  // Cadangan bila offline.
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.border,
                    child: const Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nama + level (Expanded agar tombol di kanan tidak overflow)
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sarah Chen',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Level 8 Signer',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4)),
      ],
    );

class _SettingsCard extends StatelessWidget {
  final List<_Row> rows;
  const _SettingsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            rows[i].child,
          ],
        ],
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(19),
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          subtitleWidget ??
              Text(
                subtitle ?? '',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.3),
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
      label: const Text(
        'Keluar dari Akun',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
