import 'package:flutter/material.dart';

import '../../models/profil_model.dart';
import '../../services/auth_service.dart';
import '../../services/profil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/user_avatar.dart';

/// Membuka papan peringkat (layar penuh).
Future<void> openLeaderboard(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
  );
}

/// Nama lama, dipertahankan supaya home_page.dart dan komunitas_header.dart
/// tidak perlu diubah. Isinya sekarang membuka layar penuh.
Future<void> showLeaderboardSheet(BuildContext context) =>
    openLeaderboard(context);

/// Papan peringkat pengguna, diurutkan dari poin terbanyak.
///
/// Data dibaca dari tabel `profiles` (kolom `points` dan `xp`).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ProfilService _service = ProfilService();
  final String? _myId = AuthService().currentUser?.id;

  List<ProfilPengguna> _pengguna = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool force = false}) async {
    // Spinner hanya saat belum ada data; data cache langsung ditampilkan.
    if (_pengguna.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _service.fetchLeaderboard(force: force);
      if (!mounted) return;
      setState(() {
        _pengguna = data;
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

  int _xpOf(ProfilPengguna p) => p.points > 0 ? p.points : p.xp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Papan Peringkat',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _muat(force: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: AppColors.textMuted, size: 32),
                const SizedBox(height: 12),
                Text('Gagal memuat papan peringkat',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _muat(force: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_pengguna.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: AppColors.textMuted, size: 32),
                const SizedBox(height: 12),
                Text('Belum ada peringkat', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Papan peringkat akan terisi setelah pengguna mengumpulkan poin.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final top3 = _pengguna.take(3).toList();
    final rest = _pengguna.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _buildPeriodChips(),
        const SizedBox(height: 28),
        _buildPodium(top3),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildRankCard(rest),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Peringkat dihitung dari total poin setiap pengguna.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  // ---------------- FILTER PERIODE ----------------

  Widget _buildPeriodChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Sepanjang Waktu',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }

  // ---------------- PODIUM TOP 3 ----------------

  Widget _buildPodium(List<ProfilPengguna> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();
    Widget? second = top3.length > 1 ? _podiumItem(top3[1], 2) : null;
    Widget? third = top3.length > 2 ? _podiumItem(top3[2], 3) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second ?? const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(child: _podiumItem(top3[0], 1)),
          const SizedBox(width: 8),
          Expanded(
            child: third ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(ProfilPengguna p, int rank) {
    final first = rank == 1;
    final me = p.id == _myId;
    final blockHeight = first ? 130.0 : (rank == 2 ? 98.0 : 82.0);
    final radius = first ? 36.0 : 30.0;
    final ringColor = first ? AppColors.tertiary : AppColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
          ),
          child: UserAvatar(
            imageUrl: p.avatarUrl.isEmpty ? null : p.avatarUrl,
            name: p.nama,
            size: radius * 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          me ? 'Kamu' : p.nama,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: me ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 16, color: AppColors.secondary),
            Flexible(
              child: Text(
                '${ProfilPengguna.formatAngka(_xpOf(p))} XP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: blockHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: first
                ? const LinearGradient(
                    colors: [AppColors.tertiary, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [AppColors.pinkSoft, AppColors.purpleSoft],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: first ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- DAFTAR PERINGKAT 4 DST --------------

  Widget _buildRankCard(List<ProfilPengguna> rest) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            for (int i = 0; i < rest.length; i++) ...[
              _buildRow(rest[i], i + 4),
              if (i < rest.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 60,
                  endIndent: 16,
                  color: AppColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(ProfilPengguna p, int rank) {
    final me = p.id == _myId;
    return Container(
      color:
          me ? AppColors.pinkSoft.withValues(alpha: 0.3) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: me ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          UserAvatar(
            imageUrl: p.avatarUrl.isEmpty ? null : p.avatarUrl,
            name: p.nama,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    me ? 'Kamu' : p.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: me ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (me) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Kamu',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.bolt,
            size: 16,
            color: me ? AppColors.primary : AppColors.secondary,
          ),
          Text(
            '${ProfilPengguna.formatAngka(_xpOf(p))} XP',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: me ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
