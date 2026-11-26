import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/profile_controller.dart';
import '../../models/user_profile_model.dart';
import '../theme/app_colors.dart';
import '../widgets/featured_badge_catalog.dart';
import '../widgets/share_sheet.dart';
import '../widgets/user_avatar.dart';
import '../edit/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadRequested) return;
    _loadRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.profile;
    final badges = profile?.featuredBadges ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileHeader(context, controller, profile),
          const SizedBox(height: 32),
          _buildSectionTitle(
            icon: Icons.military_tech_rounded,
            title: 'Pencapaian Unggulan',
            iconColor: AppColors.primary,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${badges.length} / 3 Dipilih',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bagikan pencapaian',
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () => showShareSheet(
                    context,
                    text: _shareText(badges),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementsRow(badges),
          const SizedBox(height: 32),
          _buildSectionTitle(
            icon: Icons.school_rounded,
            title: 'Modul & Progres Isyarat',
            iconColor: AppColors.primary,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '4 Modul',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            iconWidget: const Stack(
              alignment: Alignment.bottomRight,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 2.0, right: 2.0),
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(Icons.check, size: 12, color: AppColors.primary),
              ],
            ),
            title: 'Alfabet (A - Z)',
            subtitle: '26 Huruf Dasar • Selesai',
            percentText: '100%',
            progressValue: 1.0,
            progressColor: AppColors.primary,
            iconBgColor: AppColors.pinkSoft,
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '123',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),
            ),
            title: 'Angka & Bilangan',
            subtitle: '0 - 100 & Satuan • 15/20 Pelajaran',
            percentText: '75%',
            progressValue: 0.75,
            progressColor: AppColors.secondary,
            iconBgColor: AppColors.purpleSoft,
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: const Icon(
              Icons.back_hand_rounded,
              color: AppColors.tertiary,
              size: 20,
            ),
            title: 'Sapaan & Percakapan Dasar',
            subtitle: 'Halo, Terima Kasih, Maaf • 8/20 Pelajaran',
            percentText: '40%',
            progressValue: 0.40,
            progressColor: AppColors.tertiary,
            iconBgColor: AppColors.orangeSoft,
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: AppColors.info,
              size: 22,
            ),
            title: 'Ekspresi Wajah & Emosi',
            subtitle: 'Gramatika Visual Non-Manual • 3/20 Pelajaran',
            percentText: '15%',
            progressValue: 0.15,
            progressColor: AppColors.info,
            iconBgColor: AppColors.infoSoft,
          ),
          const SizedBox(height: 24), // Extra padding at bottom
        ],
      ),
    );
  }

  String _shareText(List<String> badgeIds) {
    final titles = badgeIds
        .map((id) => featuredBadgeById(id)?['title'])
        .whereType<String>()
        .toList(growable: false);
    if (titles.isEmpty) {
      return 'Aku sedang membangun profil isyaratku di Sign.L!';
    }
    return 'Aku membuka lencana ${titles.join(', ')} di Sign.L! 🏅';
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ProfileController controller,
    UserProfile? profile,
  ) {
    final name = profile?.displayName ?? 'Memuat profil...';
    final username = profile?.displayUsername ?? '';
    final bio = profile?.bio.trim() ?? '';

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
                  imageUrl: profile?.avatarUrl,
                  name: name,
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
        // Baris Nama Pengguna & Tombol Edit Profil
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openEditProfile(context),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
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
        if (username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            username,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            bio,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (controller.isLoading && profile == null) ...[
          const SizedBox(height: 12),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
        if (!controller.isLoading && profile == null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => controller.load(force: true),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(controller.errorMessage ?? 'Muat ulang profil'),
          ),
        ],
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final controller = context.read<ProfileController>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (!mounted) return;
    controller.load(force: true);
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

  Widget _buildAchievementsRow(List<String> badgeIds) {
    final badges = badgeIds
        .map(featuredBadgeById)
        .whereType<Map<String, dynamic>>()
        .take(3)
        .toList(growable: false);

    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'Belum ada lencana unggulan.\nPilih lewat tombol Edit Profil.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final badge in badges)
          _buildAchievementCard(
            icon: badge['icon'] as IconData,
            iconBg: badge['bg'] as Color,
            iconColor: badge['color'] as Color,
            title: badge['title'] as String,
            subtitle: badge['category'] as String,
            subtitleColor: badge['color'] as Color,
          ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required String percentText,
    required double progressValue,
    required Color progressColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.fieldFill,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
