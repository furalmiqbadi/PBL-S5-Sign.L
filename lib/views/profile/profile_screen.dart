import 'package:flutter/material.dart';

import '../../models/bab_model.dart';
import '../../models/nama_tampil.dart';
import '../../models/profil_model.dart';
import '../../services/materi_service.dart';
import '../../services/profil_service.dart';
import '../auth/auth_views.dart' show konfirmasiKeluar;
import '../edit/edit_profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/share_sheet.dart';
import '../widgets/user_avatar.dart';

/// Halaman Profil pengguna: identitas, statistik belajar, dan progres modul.
///
/// Semua angka diambil dari Supabase: profil dari tabel `profiles` dan
/// progres modul dari `progres_materi`/`hasil_kuis` lewat [MateriService].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfilService _profilService = ProfilService();
  final MateriService _materiService = MateriService();

  ProfilPengguna? _profil;
  List<Bab> _bab = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool force = false}) async {
    if (_profil == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // Profil dari cache & daftar bab diambil paralel agar tab Profil cepat.
      final profilFuture = _profilService.profilSaya(force: force);
      final babFuture = _materiService.fetchBabList();
      final profil = await profilFuture;
      final bab = await babFuture;
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _bab = bab;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String get _nama => _profil?.nama ?? labelNamaNetral;
  String get _username =>
      (_profil?.username ?? '').isEmpty ? '' : _profil!.usernameText;
  String? get _avatar =>
      (_profil?.avatarUrl ?? '').isEmpty ? null : _profil!.avatarUrl;

  void _bagikan() {
    final teks = _profil == null
        ? 'Aku belajar bahasa isyarat BISINDO di Sign.L!'
        : 'Aku sudah mengumpulkan ${ProfilPengguna.formatAngka(_profil!.xp)} XP '
            'dan ${ProfilPengguna.formatAngka(_profil!.points)} poin di Sign.L!';
    showShareSheet(context, text: teks);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _muat(force: true),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                AppBottomNavBar.reservedSpace(context) + 16,
              ),
              children: [
                if (_error != null) ...[
                  _buildPesan(
                    icon: Icons.cloud_off_rounded,
                    title: 'Gagal memuat profil',
                    message: _error!,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildProfileHeader(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    icon: Icons.insights_rounded,
                    title: 'Statistik Belajar',
                    iconColor: AppColors.primary,
                    trailing: IconButton(
                      tooltip: 'Bagikan pencapaian',
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: _bagikan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementsRow(),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    icon: Icons.school_rounded,
                    title: 'Modul & Progres Isyarat',
                    iconColor: AppColors.primary,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_bab.length} Modul',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_bab.isEmpty)
                    _buildPesan(
                      icon: Icons.menu_book_outlined,
                      title: 'Belum ada modul',
                      message: 'Materi akan muncul di sini setelah admin '
                          'menambahkannya.',
                    )
                  else
                    ..._bab.map(
                      (bab) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildModuleCard(bab),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildKeluar(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
    );
  }

  /// Tombol keluar diletakkan di tab Profil agar mudah dijangkau tanpa
  /// harus membuka halaman Pengaturan.
  Widget _buildKeluar() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => konfirmasiKeluar(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Keluar dari Akun'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          backgroundColor: AppColors.dangerSoft,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pinkSoft,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: UserAvatar(
                  imageUrl: _avatar,
                  name: _nama,
                  size: 80,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (mounted) _muat();
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _username.isEmpty ? (_profil?.roleLabel ?? 'Pembelajar') : _username,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAchievementsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          icon: Icons.local_fire_department_rounded,
          iconBg: AppColors.orangeSoft,
          iconColor: AppColors.tertiary,
          value: '${_profil?.streak ?? 0}',
          label: 'Hari Streak',
        ),
        _buildStatCard(
          icon: Icons.bolt_rounded,
          iconBg: AppColors.purpleSoft,
          iconColor: AppColors.secondary,
          value: ProfilPengguna.formatAngka(_profil?.xp ?? 0),
          label: 'Total XP',
        ),
        _buildStatCard(
          icon: Icons.stars_rounded,
          iconBg: AppColors.pinkSoft,
          iconColor: AppColors.primary,
          value: ProfilPengguna.formatAngka(_profil?.points ?? 0),
          label: 'Poin',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LiquidGlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          borderRadius: AppRadii.lg,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(Bab bab) {
    final percent = (bab.progress * 100).round();
    final selesai = bab.isCompleted;
    final color = selesai ? AppColors.secondary : AppColors.primary;
    final bg = selesai ? AppColors.purpleSoft : AppColors.pinkSoft;
    final subtitle = bab.hasLetterPractice
        ? '${bab.totalMateri} huruf • ${bab.progressText}'
        : '${bab.kuisSelesai}/${bab.kuisTotal} kuis • '
            '${bab.isInProgress ? 'Sedang berjalan' : 'Siap dimulai'}';

    return AppCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadii.xl,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  bab.number,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selesai ? 'Selesai' : '$percent%',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: bab.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesan({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTonal,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _muat(force: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat ulang'),
          ),
        ],
      ),
    );
  }
}
