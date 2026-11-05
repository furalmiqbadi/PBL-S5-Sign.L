import 'package:flutter/material.dart';
import '../auth/auth_views.dart' show LoginPage;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'admin_detail_pages.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  // ===== MOCK DATA (ganti nanti sama API/backend) =====
  static const int laporanBaru = 4;
  static const int totalMateri = 5;
  static const int totalKuis = 4;
  static const int totalPengguna = 1284;
  static const int penggunaAktif = 312;
  static const int laporanChat = 2;
  static const int videoAIReview = 6;

  // Keluar dari panel admin, kembali ke halaman masuk
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Panel Admin?'),
        content: const Text('Kamu akan kembali ke halaman masuk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Panel Admin', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: 24),
          Text('Ringkasan', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          _buildStatGrid(),
          const SizedBox(height: 24),
          Text('Pengelolaan', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          _menuTile(
            context,
            icon: Icons.flag,
            iconBg: const Color(0xFFFCE4EC),
            iconColor: AppColors.danger,
            title: 'Laporan Pengguna',
            subtitle: '$laporanBaru laporan baru menunggu',
            badge: laporanBaru,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanPenggunaPage())),
          ),
          _menuTile(
            context,
            icon: Icons.forum_outlined,
            iconBg: const Color(0xFFFCE4EC),
            iconColor: AppColors.danger,
            title: 'Moderasi Chat',
            subtitle: '$laporanChat pesan dilaporkan',
            badge: laporanChat,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModerasiChatPage())),
          ),
          _menuTile(
            context,
            icon: Icons.videocam_outlined,
            iconBg: const Color(0xFFF3E8FD),
            iconColor: AppColors.secondary,
            title: 'Review Video AI',
            subtitle: '$videoAIReview video menunggu tinjauan',
            badge: videoAIReview,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewVideoAIPage())),
          ),
          _menuTile(
            context,
            icon: Icons.people_alt_outlined,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.success,
            title: 'Manajemen Pengguna',
            subtitle: '$totalPengguna pengguna terdaftar',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManajemenPenggunaPage())),
          ),
          _menuTile(
            context,
            icon: Icons.emoji_events_outlined,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: AppColors.tertiary,
            title: 'Leaderboard & Poin',
            subtitle: 'Cek kecurangan, reset poin, kunci peringkat',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPoinPage())),
          ),
          _menuTile(
            context,
            icon: Icons.menu_book_outlined,
            iconBg: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFC2185B),
            title: 'Management Materi',
            subtitle: '$totalMateri materi terdaftar',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagementMateriPage())),
          ),
          _menuTile(
            context,
            icon: Icons.assignment_outlined,
            iconBg: const Color(0xFFF3E8FD),
            iconColor: AppColors.secondary,
            title: 'Management Kuis',
            subtitle: '$totalKuis kuis terdaftar',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagementKuisPage())),
          ),
          _menuTile(
            context,
            icon: Icons.campaign_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
            title: 'Broadcast Notifikasi',
            subtitle: 'Kirim pengumuman ke semua pengguna',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastNotifikasiPage())),
          ),
          _menuTile(
            context,
            icon: Icons.image_outlined,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: AppColors.tertiary,
            title: 'Banner & Promo',
            subtitle: 'Atur banner promo di halaman komunitas',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BannerPromoPage())),
          ),
          _menuTile(
            context,
            icon: Icons.receipt_long_outlined,
            iconBg: AppColors.surfaceMuted,
            iconColor: AppColors.textSecondary,
            title: 'Log Aktivitas Admin',
            subtitle: 'Riwayat aksi semua admin',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogAktivitasPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A18), Color(0xFFE91E63)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, Admin',
                    style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Ada ${laporanBaru + laporanChat + videoAIReview} tugas yang perlu ditinjau.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = [
      ('$totalPengguna', 'Total Pengguna', Icons.people_alt),
      ('$penggunaAktif', 'Aktif Hari Ini', Icons.online_prediction),
      ('$totalMateri', 'Materi', Icons.menu_book),
      ('$totalKuis', 'Kuis', Icons.assignment),
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.$3, size: 20, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(s.$1, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(s.$2, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}