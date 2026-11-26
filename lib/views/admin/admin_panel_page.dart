import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_views.dart' show LoginPage;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'admin_detail_pages.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _db = Supabase.instance.client;

  // ===== DATA ASLI DARI SUPABASE (null = gagal dimuat / belum ada) =====
  int? laporanBaru;
  int? laporanChat;
  int? totalMateri;
  int? totalKuis;
  int? totalPengguna;
  int? penggunaAktif;

  bool _loading = true;
  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_channel != null) _db.removeChannel(_channel!);
    super.dispose();
  }

  // Dengarkan perubahan tabel; kalau ada, muat ulang angka (ditunda biar tidak spam)
  void _subscribe() {
    var ch = _db.channel('admin-ringkasan');
    for (final t in ['profiles', 'materi', 'kuis', 'laporan']) {
      ch = ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: t,
        callback: (_) => _jadwalMuat(),
      );
    }
    _channel = ch.subscribe();
  }

  void _jadwalMuat() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) _load(tampilLoading: false);
    });
  }

  // Menjalankan satu hitungan; kalau gagal (mis. izin belum ada) hasilnya null
  Future<int?> _aman(Future<int> Function() f, String nama) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('Gagal menghitung $nama: $e');
      return null;
    }
  }

  Future<void> _load({bool tampilLoading = true}) async {
    if (!mounted) return;
    if (tampilLoading) setState(() => _loading = true);

    final now = DateTime.now();
    final awalHari = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    final hasil = await Future.wait<int?>([
      _aman(() async {
        final r = await _db.from('profiles').select('id').limit(1).count(CountOption.exact);
        return r.count;
      }, 'pengguna'),
      _aman(() async {
        final r = await _db
            .from('profiles')
            .select('id')
            .gte('last_seen_at', awalHari)
            .limit(1)
            .count(CountOption.exact);
        return r.count;
      }, 'pengguna aktif'),
      _aman(() async {
        final r = await _db.from('materi').select('id').limit(1).count(CountOption.exact);
        return r.count;
      }, 'materi'),
      _aman(() async {
        final r = await _db.from('kuis').select('id').limit(1).count(CountOption.exact);
        return r.count;
      }, 'kuis'),
      _aman(() async {
        final r = await _db
            .from('laporan')
            .select('id')
            .eq('status', 'baru')
            .neq('tipe', 'chat')
            .limit(1)
            .count(CountOption.exact);
        return r.count;
      }, 'laporan pengguna'),
      _aman(() async {
        final r = await _db
            .from('laporan')
            .select('id')
            .eq('status', 'baru')
            .eq('tipe', 'chat')
            .limit(1)
            .count(CountOption.exact);
        return r.count;
      }, 'laporan chat'),
    ]);

    if (!mounted) return;
    setState(() {
      totalPengguna = hasil[0];
      penggunaAktif = hasil[1];
      totalMateri = hasil[2];
      totalKuis = hasil[3];
      laporanBaru = hasil[4];
      laporanChat = hasil[5];
      _loading = false;
    });
  }

  String _n(int? v) => v == null ? '-' : '$v';

  // Buka halaman lain; setelah kembali, angka dimuat ulang
  Future<void> _buka(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load(tampilLoading: false);
  }

  // Keluar dari akun Supabase, lalu kembali ke halaman masuk
  Future<void> _logout() async {
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
    if (ok != true || !mounted) return;
    try {
      await _db.auth.signOut();
    } catch (e) {
      debugPrint('Gagal sign out: $e');
    }
    if (!mounted) return;
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
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(tampilLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              subtitle: '${_n(laporanBaru)} laporan baru menunggu',
              badge: laporanBaru ?? 0,
              onTap: () => _buka(const LaporanPenggunaPage()),
            ),
            _menuTile(
              context,
              icon: Icons.forum_outlined,
              iconBg: const Color(0xFFFCE4EC),
              iconColor: AppColors.danger,
              title: 'Moderasi Chat',
              subtitle: '${_n(laporanChat)} pesan dilaporkan',
              badge: laporanChat ?? 0,
              onTap: () => _buka(const ModerasiChatPage()),
            ),
            _menuTile(
              context,
              icon: Icons.people_alt_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: AppColors.success,
              title: 'Manajemen Pengguna',
              subtitle: '${_n(totalPengguna)} pengguna terdaftar',
              onTap: () => _buka(const ManajemenPenggunaPage()),
            ),
            _menuTile(
              context,
              icon: Icons.emoji_events_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: AppColors.tertiary,
              title: 'Leaderboard & Poin',
              subtitle: 'Cek kecurangan, reset poin, kunci peringkat',
              onTap: () => _buka(const LeaderboardPoinPage()),
            ),
            _menuTile(
              context,
              icon: Icons.menu_book_outlined,
              iconBg: const Color(0xFFFCE4EC),
              iconColor: const Color(0xFFC2185B),
              title: 'Management Materi',
              subtitle: '${_n(totalMateri)} materi terdaftar',
              onTap: () => _buka(const ManagementMateriPage()),
            ),
            _menuTile(
              context,
              icon: Icons.assignment_outlined,
              iconBg: const Color(0xFFF3E8FD),
              iconColor: AppColors.secondary,
              title: 'Management Kuis',
              subtitle: '${_n(totalKuis)} kuis terdaftar',
              onTap: () => _buka(const ManagementKuisPage()),
            ),
            _menuTile(
              context,
              icon: Icons.campaign_outlined,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: Colors.blue,
              title: 'Broadcast Notifikasi',
              subtitle: 'Kirim pengumuman ke semua pengguna',
              onTap: () => _buka(const BroadcastNotifikasiPage()),
            ),
            _menuTile(
              context,
              icon: Icons.image_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: AppColors.tertiary,
              title: 'Banner & Promo',
              subtitle: 'Atur banner promo di halaman komunitas',
              onTap: () => _buka(const BannerPromoPage()),
            ),
            _menuTile(
              context,
              icon: Icons.receipt_long_outlined,
              iconBg: AppColors.surfaceMuted,
              iconColor: AppColors.textSecondary,
              title: 'Log Aktivitas Admin',
              subtitle: 'Riwayat aksi semua admin',
              onTap: () => _buka(const LogAktivitasPage()),
            ),

            // ===== TOMBOL KELUAR DARI AKUN =====
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.pinkSofter,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pinkSoft),
              ),
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: Text(
                  'Keluar dari Akun',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    final tugas = (laporanBaru ?? 0) + (laporanChat ?? 0);
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
                Text(
                  'Halo, Admin',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading
                      ? 'Memuat data...'
                      : (tugas == 0
                          ? 'Tidak ada tugas yang perlu ditinjau.'
                          : 'Ada $tugas tugas yang perlu ditinjau.'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
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
      (_n(totalPengguna), 'Total Pengguna', Icons.people_alt),
      (_n(penggunaAktif), 'Aktif Hari Ini', Icons.online_prediction),
      (_n(totalMateri), 'Materi', Icons.menu_book),
      (_n(totalKuis), 'Kuis', Icons.assignment),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.$3, size: 20, color: AppColors.primary),
                const SizedBox(height: 8),
                _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        s.$1,
                        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: 2),
                Text(
                  s.$2,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
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
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}