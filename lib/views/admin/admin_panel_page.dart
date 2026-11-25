import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/friend_controller.dart';
import '../../models/chat_model.dart';
import '../../models/profil_model.dart';
import '../../services/admin_service.dart';
import '../../services/profil_service.dart';
import '../auth/auth_views.dart' show konfirmasiKeluar;
import '../chat/chat_list_view.dart';
import '../chat/chat_room_view.dart';
import '../chat/new_chat_sheet.dart';
import '../friend/friend_page.dart';
import '../komunitas/komunitas_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_ui.dart';
import '../widgets/komunitas_header.dart';
import '../widgets/section_header.dart';
import '../widgets/user_avatar.dart';
import 'admin_detail_pages.dart';

/// Panel admin dengan lima tab:
/// `0 Dasbor · 1 Laporan · 2 Materi (tengah) · 3 Komunitas · 4 Profil`.
///
/// Admin memakai navbar yang sama dengan pengguna sehingga bisa ikut
/// berinteraksi di komunitas, sementara modul moderasi (laporan, chat) dan
/// pengelolaan konten dikumpulkan di tab khusus.
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  static const int _tabDasbor = 0;
  static const int _tabLaporan = 1;
  static const int _tabMateri = 2;

  final AdminService _service = AdminService();
  final ProfilService _profilService = ProfilService();
  late final PageController _pageController;

  int _index = _tabDasbor;
  int _laporanTab = 0;
  int _materiTab = 0;

  AdminRingkasan _ringkasan = const AdminRingkasan();
  ProfilPengguna? _profil;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    _muat();
    _muatProfil();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ringkasan = await _service.fetchRingkasan();
      if (!mounted) return;
      setState(() => _ringkasan = ringkasan);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : '$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _muatProfil() async {
    final profil = await _profilService.profilSaya(force: true);
    if (!mounted) return;
    setState(() => _profil = profil);
  }

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _buka(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Admin memilih satu pengguna lalu membuka ruang chat dua arah.
  Future<void> _kirimPesan() async {
    final contact = await showModalBottomSheet<ChatContact>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.dialog),
        ),
      ),
      builder: (_) => const NewChatSheet(),
    );
    if (contact == null || !mounted) return;
    final chat = context.read<ChatController>();
    try {
      final room = await chat.startChat(contact);
      if (!mounted) return;
      _buka(ChatRoomScreen(room: room));
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e',
        type: AppSnackType.error,
      );
    }
  }

  void _bukaTeman() => _buka(const FriendPage());

  Future<void> _logout() => konfirmasiKeluar(
        context,
        title: 'Keluar dari Panel Admin?',
        message: 'Kamu akan kembali ke halaman masuk.',
      );

  String get _namaAdmin {
    final nama = _profil?.nama.trim() ?? '';
    return nama.isEmpty ? 'Admin' : nama;
  }

  List<AppNavItem> get _items => [
        const AppNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dasbor',
        ),
        const AppNavItem(
          icon: Icons.flag_outlined,
          activeIcon: Icons.flag_rounded,
          label: 'Laporan',
        ),
        const AppNavItem(
          svgAsset: 'assets/images/komunitas.svg',
          label: 'Komunitas',
        ),
        AppNavItem(
          imageUrl: _profil?.avatarUrl,
          name: _namaAdmin,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _index == _tabDasbor,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != _tabDasbor) _goTo(_tabDasbor);
      },
      child: Scaffold(
        extendBody: true,
        body: AppBackground(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KeepAlivePage(child: _buildDasbor(context)),
              _KeepAlivePage(child: _buildLaporan(context)),
              _KeepAlivePage(child: _buildMateri(context)),
              _KeepAlivePage(child: _buildKomunitas(context)),
              _KeepAlivePage(child: _buildProfil(context)),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          items: _items,
          selectedIndex: _index,
          onSelect: _goTo,
          onCenterTap: () => _goTo(AppBottomNavBar.centerIndex),
          centerIcon: Icons.menu_book_rounded,
          centerLabel: 'Materi',
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 0. DASBOR
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildDasbor(BuildContext context) {
    final bottom = AppBottomNavBar.reservedSpace(context) + 16;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: SectionHeader(
            title: 'Panel Admin',
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                semanticLabel: 'Muat ulang',
                onTap: _muat,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _muat,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
              children: [
                _buildHeaderBanner(),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildErrorRingkasan()
                else ...[
                  Text('Ringkasan', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  _buildStatGrid(),
                ],
                const SizedBox(height: 24),
                Text('Pengelolaan', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                _AdminMenuTile(
                  icon: Icons.flag_rounded,
                  iconBg: AppColors.dangerSoft,
                  iconColor: AppColors.danger,
                  title: 'Laporan Pengguna',
                  subtitle: '${_ringkasan.laporanBaru} laporan baru menunggu',
                  badge: _ringkasan.laporanBaru,
                  onTap: () {
                    setState(() => _laporanTab = 0);
                    _goTo(_tabLaporan);
                  },
                ),
                _AdminMenuTile(
                  icon: Icons.forum_outlined,
                  iconBg: AppColors.dangerSoft,
                  iconColor: AppColors.danger,
                  title: 'Moderasi Chat',
                  subtitle: '${_ringkasan.laporanChat} pesan dilaporkan',
                  badge: _ringkasan.laporanChat,
                  onTap: () {
                    setState(() => _laporanTab = 1);
                    _goTo(_tabLaporan);
                  },
                ),
                _AdminMenuTile(
                  icon: Icons.videocam_outlined,
                  iconBg: AppColors.purpleSoft,
                  iconColor: AppColors.secondary,
                  title: 'Review Video & Foto',
                  subtitle:
                      '${_ringkasan.reviewMenunggu} kiriman menunggu tinjauan',
                  badge: _ringkasan.reviewMenunggu,
                  onTap: () => _buka(const ReviewVideoAIPage()),
                ),
                _AdminMenuTile(
                  icon: Icons.people_alt_outlined,
                  iconBg: AppColors.successSoft,
                  iconColor: AppColors.success,
                  title: 'Manajemen Pengguna',
                  subtitle: '${_ringkasan.totalPengguna} pengguna terdaftar',
                  onTap: () => _buka(const ManajemenPenggunaPage()),
                ),
                _AdminMenuTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: AppColors.pinkSoft,
                  iconColor: AppColors.primary,
                  title: 'Kirim Pesan ke Pengguna',
                  subtitle: 'Balas atau hubungi pengguna langsung',
                  onTap: _kirimPesan,
                ),
                _AdminMenuTile(
                  icon: Icons.emoji_events_outlined,
                  iconBg: AppColors.orangeSoft,
                  iconColor: AppColors.tertiary,
                  title: 'Leaderboard & Poin',
                  subtitle: 'Reset poin dan pantau peringkat',
                  onTap: () => _buka(const LeaderboardPoinPage()),
                ),
                _AdminMenuTile(
                  icon: Icons.menu_book_outlined,
                  iconBg: AppColors.pinkSoft,
                  iconColor: AppColors.primary,
                  title: 'Management Materi',
                  subtitle: '${_ringkasan.totalMateri} materi terdaftar',
                  onTap: () {
                    setState(() => _materiTab = 0);
                    _goTo(_tabMateri);
                  },
                ),
                _AdminMenuTile(
                  icon: Icons.assignment_outlined,
                  iconBg: AppColors.purpleSoft,
                  iconColor: AppColors.secondary,
                  title: 'Management Kuis',
                  subtitle: '${_ringkasan.totalKuis} kuis terdaftar',
                  onTap: () {
                    setState(() => _materiTab = 1);
                    _goTo(_tabMateri);
                  },
                ),
                _AdminMenuTile(
                  icon: Icons.campaign_outlined,
                  iconBg: AppColors.infoSoft,
                  iconColor: AppColors.info,
                  title: 'Broadcast Notifikasi',
                  subtitle: 'Kirim pengumuman ke pengguna',
                  onTap: () => _buka(const BroadcastNotifikasiPage()),
                ),
                _AdminMenuTile(
                  icon: Icons.image_outlined,
                  iconBg: AppColors.orangeSoft,
                  iconColor: AppColors.tertiary,
                  title: 'Banner & Promo',
                  subtitle: 'Atur banner promo aplikasi',
                  onTap: () => _buka(const BannerPromoPage()),
                ),
                _AdminMenuTile(
                  icon: Icons.receipt_long_outlined,
                  iconBg: AppColors.surfaceMuted,
                  iconColor: AppColors.textSecondary,
                  title: 'Log Aktivitas Admin',
                  subtitle: 'Riwayat aksi admin',
                  onTap: () => _buka(const LogAktivitasPage()),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign.L Admin Panel • Versi 1.0.0',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRingkasan() {
    return AppCard(
      child: Column(
        children: [
          Text('Gagal memuat ringkasan', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _muat,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return AppCard(
      color: AppColors.primary,
      borderColor: Colors.transparent,
      borderRadius: AppRadii.xl,
      shadows: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.24),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $_namaAdmin',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ringkasan.tugasMenunggu == 0
                      ? 'Semua tugas sudah ditinjau.'
                      : 'Ada ${_ringkasan.tugasMenunggu} tugas yang perlu ditinjau.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
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
      ('${_ringkasan.totalPengguna}', 'Pengguna', Icons.people_alt_rounded),
      ('${_ringkasan.totalMateri}', 'Materi', Icons.menu_book_rounded),
      ('${_ringkasan.totalKuis}', 'Kuis', Icons.assignment_rounded),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.pinkSofter,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child:
                        Icon(stats[i].$3, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stats[i].$1,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].$2,
                    style: AppTextStyles.labelXSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 1. LAPORAN
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildLaporan(BuildContext context) {
    final bottom = AppBottomNavBar.reservedSpace(context);
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: SectionHeader(title: 'Laporan'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              AppChoiceChip(
                label: 'Laporan Pengguna',
                isSelected: _laporanTab == 0,
                onTap: () => setState(() => _laporanTab = 0),
              ),
              const SizedBox(width: 8),
              AppChoiceChip(
                label: 'Moderasi Chat',
                isSelected: _laporanTab == 1,
                onTap: () => setState(() => _laporanTab = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: IndexedStack(
              index: _laporanTab,
              children: const [
                LaporanPenggunaPage(embedded: true),
                ModerasiChatPage(embedded: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 2. MATERI & KUIS (tengah)
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildMateri(BuildContext context) {
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: SectionHeader(title: 'Materi'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              AppChoiceChip(
                label: 'Materi',
                icon: Icons.menu_book_rounded,
                isSelected: _materiTab == 0,
                onTap: () => setState(() => _materiTab = 0),
              ),
              const SizedBox(width: 8),
              AppChoiceChip(
                label: 'Kuis & Latihan',
                icon: Icons.assignment_rounded,
                isSelected: _materiTab == 1,
                onTap: () => setState(() => _materiTab = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _materiTab,
            children: const [
              ManagementMateriPage(embedded: true),
              ManagementKuisPage(embedded: true),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 3. KOMUNITAS
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildKomunitas(BuildContext context) {
    return Consumer2<ChatController, FriendController>(
      builder: (context, chat, teman, _) => Column(
        children: [
          SafeArea(
            bottom: false,
            child: KomunitasHeader(
              unreadCount: chat.totalUnreadMessages,
              permintaanTeman: teman.jumlahPermintaan,
              onTeman: _bukaTeman,
              onMessages: () => _buka(const ChatListScreen()),
            ),
          ),
          const Expanded(child: KomunitasPage()),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // 4. PROFIL
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildProfil(BuildContext context) {
    final profil = _profil;
    final bottom = AppBottomNavBar.reservedSpace(context) + 16;
    return Column(
      children: [
        Consumer<FriendController>(
          builder: (context, teman, _) => SafeArea(
            bottom: false,
            child: SectionHeader(
              title: 'Profil',
              actions: [
                HeaderIconButton(
                  icon: Icons.people_alt_outlined,
                  semanticLabel: 'Teman',
                  badge: teman.jumlahPermintaan > 0
                      ? '${teman.jumlahPermintaan}'
                      : null,
                  onTap: _bukaTeman,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
            children: [
              AppCard(
                borderRadius: AppRadii.xl,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          imageUrl: profil?.avatarUrl,
                          name: _namaAdmin,
                          size: 62,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _namaAdmin,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profil?.usernameText ?? '-',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const AppStatusBadge(
                                label: 'Admin',
                                color: AppColors.primary,
                                backgroundColor: AppColors.pinkSoft,
                                icon: Icons.shield_rounded,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Akses Cepat', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              _AdminMenuTile(
                icon: Icons.receipt_long_outlined,
                iconBg: AppColors.surfaceMuted,
                iconColor: AppColors.textSecondary,
                title: 'Log Aktivitas Admin',
                subtitle: 'Riwayat aksi admin',
                onTap: () => _buka(const LogAktivitasPage()),
              ),
              _AdminMenuTile(
                icon: Icons.campaign_outlined,
                iconBg: AppColors.infoSoft,
                iconColor: AppColors.info,
                title: 'Broadcast Notifikasi',
                subtitle: 'Kirim pengumuman ke pengguna',
                onTap: () => _buka(const BroadcastNotifikasiPage()),
              ),
              _AdminMenuTile(
                icon: Icons.image_outlined,
                iconBg: AppColors.orangeSoft,
                iconColor: AppColors.tertiary,
                title: 'Banner & Promo',
                subtitle: 'Atur banner promo aplikasi',
                onTap: () => _buka(const BannerPromoPage()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.dangerSoft),
                    backgroundColor: AppColors.pinkSofter,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Baris menu admin: ikon berwarna, judul, subjudul, dan lencana jumlah.
class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _AdminMenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadii.md,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (badge > 0) ...[
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '$badge',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelXSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// Menyimpan state halaman tab agar tidak dibangun ulang saat berpindah tab.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
