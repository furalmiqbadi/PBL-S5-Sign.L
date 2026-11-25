import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/bab_model.dart';
import '../../models/nama_tampil.dart';
import '../../models/profil_model.dart';
import '../../services/materi_service.dart';
import '../../services/post_service.dart';
import '../../services/profil_service.dart';
import '../chat/chat_list_view.dart';
import '../komunitas/komunitas_page.dart';
import '../notification/notification_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_ui.dart';
import '../widgets/home_header.dart';
import '../widgets/leaderboard.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/user_avatar.dart';
import 'detail_materi_page.dart';

/// Halaman Beranda: sapaan, statistik belajar, lanjut belajar, ringkasan
/// komunitas, dan papan peringkat.
///
/// Semua data diambil dari Supabase: `profiles` (streak, XP, poin),
/// `materi`/`progres_materi` (lanjut belajar), `posts` (komunitas).
class HomePage extends StatefulWidget {
  final VoidCallback? onOpenCommunity;
  final VoidCallback? onOpenProfile;

  const HomePage({
    super.key,
    this.onOpenCommunity,
    this.onOpenProfile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfilService _profilService = ProfilService();
  final MateriService _materiService = MateriService();
  final PostService _postService = PostService();

  final PageController _communityPageController = PageController();
  int _currentCommunityPage = 0;

  ProfilPengguna? _profil;
  List<Bab> _bab = const [];
  List<PostRingkas> _posts = const [];
  List<ProfilPengguna> _papan = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _communityPageController.dispose();
    super.dispose();
  }

  Future<void> _muat({bool force = false}) async {
    // Semua permintaan dijalankan paralel supaya Beranda tampil lebih cepat.
    final profilFuture = _profilService.profilSaya(force: force);
    final babFuture = _materiService.fetchBabList().catchError(
          (_) => <Bab>[],
        );
    final postsFuture = _postService.fetchTerbaru(batas: 3);
    final papanFuture = _profilService.fetchLeaderboard(batas: 3).catchError(
          (_) => <ProfilPengguna>[],
        );

    final profil = await profilFuture;
    final bab = await babFuture;
    final posts = await postsFuture;
    final papan = await papanFuture;
    if (!mounted) return;
    setState(() {
      _profil = profil;
      _bab = bab;
      _posts = posts;
      _papan = papan;
      _loading = false;
      if (_currentCommunityPage >= posts.length) {
        _currentCommunityPage = 0;
      }
    });
  }

  /// Bab yang sedang dikerjakan, atau bab pertama yang sudah terbuka.
  Bab? get _babAktif {
    for (final bab in _bab) {
      if (bab.isInProgress) return bab;
    }
    for (final bab in _bab) {
      if (!bab.isLocked) return bab;
    }
    return null;
  }

  int get _modulSelesai => _bab.where((b) => b.isCompleted).length;

  String get _nama => _profil?.nama ?? labelNamaNetral;
  String? get _avatar =>
      (_profil?.avatarUrl ?? '').isEmpty ? null : _profil!.avatarUrl;

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  Future<void> _continueLearning() async {
    final bab = _babAktif;
    if (bab == null) {
      showAppSnackBar(context, 'Belum ada materi untuk dilanjutkan.');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailMateriPage(materiId: bab.id)),
    );
    if (mounted) _muat();
  }

  void _openCommunity() {
    if (widget.onOpenCommunity != null) {
      widget.onOpenCommunity!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KomunitasPage()),
      );
    }
  }

  void _openProfile() {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
    } else {
      showAppSnackBar(context, 'Beralih ke halaman Profil...');
    }
  }

  void _openLeaderboard() {
    showLeaderboardSheet(context);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _muat(force: true),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              AppBottomNavBar.reservedSpace(context) + 16,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildStatsBar(),
                const SizedBox(height: 20),
                _buildContinueLearningCard(),
                const SizedBox(height: 20),
                _buildCommunitySnippetCard(),
                const SizedBox(height: 20),
                _buildLeaderboardSnippetCard(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return HomeHeader(
      // ListView sudah memberi padding 20/12, jadi header tidak menambah
      // padding horizontal agar logo rata dengan kartu di bawahnya.
      padding: EdgeInsets.zero,
      notificationCount: context.watch<NotificationController>().unreadCount,
      avatarUrl: _avatar,
      userName: _nama,
      onNotifications: _openNotifications,
      onMessages: _openChat,
      onAvatarTap: _openProfile,
    );
  }

  Widget _buildStatsBar() {
    return LiquidGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: AppRadii.lg,
      child: Row(
        children: [
          _buildStatItem(Icons.local_fire_department_rounded,
              AppColors.tertiary, 'Streak', '${_profil?.streak ?? 0} Hari'),
          _buildStatDivider(),
          _buildStatItem(Icons.bolt_rounded, AppColors.primary, 'XP',
              ProfilPengguna.formatAngka(_profil?.xp ?? 0)),
          _buildStatDivider(),
          _buildStatItem(Icons.diamond_rounded, AppColors.secondary, 'Poin',
              ProfilPengguna.formatAngka(_profil?.points ?? 0)),
          _buildStatDivider(),
          _buildStatItem(Icons.auto_stories_rounded, AppColors.info, 'Modul',
              '$_modulSelesai/${_bab.length}'),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 28, color: AppColors.border);

  Widget _buildStatItem(
      IconData icon, Color iconColor, String label, String value) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.labelMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearningCard() {
    final bab = _babAktif;
    final percent = bab == null ? 0.0 : bab.progress;
    final percentText = '${(percent * 100).round()}% Selesai';
    final judul =
        bab == null ? 'Belum ada materi' : 'Bab ${bab.number}: ${bab.title}';
    final keterangan = bab == null
        ? 'Materi akan muncul di sini setelah admin menambahkannya.'
        : bab.progressText;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LANJUTKAN BELAJAR',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                percentText,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            judul,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            keterangan,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    color: AppColors.pinkSoft,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              AppCard(
                onTap: _continueLearning,
                color: AppColors.primary,
                borderColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: AppRadii.md,
                shadows: AppShadows.floating,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: AppColors.textOnPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text('Lanjut',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLink(String label, VoidCallback onTap) {
    final radius = BorderRadius.circular(AppRadii.sm);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 15, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySnippetCard() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.forum_outlined,
                    color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Komunitas',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _buildSectionLink('Lihat semua', _openCommunity),
            ],
          ),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Belum ada kiriman komunitas.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            )
          else ...[
            SizedBox(
              height: 132,
              child: PageView(
                controller: _communityPageController,
                onPageChanged: (index) {
                  setState(() => _currentCommunityPage = index);
                },
                children: [
                  for (final post in _posts) _buildCommunityPostItem(post),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_posts.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentCommunityPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentCommunityPage == index
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommunityPostItem(PostRingkas post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openCommunity,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: post.avatarUrl.isEmpty ? null : post.avatarUrl,
                      name: post.namaTampil,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.namaTampil,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatWaktuSingkat(post.dibuat),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  post.konten.isEmpty ? 'Kiriman media' : post.konten,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Buka komunitas',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardSnippetCard() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.emoji_events_outlined,
                    color: AppColors.tertiary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Papan Peringkat',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _buildSectionLink('Lihat peringkat', _openLeaderboard),
            ],
          ),
          const SizedBox(height: 16),
          if (_papan.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada peringkat.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            )
          else
            for (int i = 0; i < _papan.length; i++)
              _buildLeaderboardItem(i + 1, _papan[i]),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, ProfilPengguna p) {
    final isMe = p.id == _profil?.id;
    final Color medalColor;
    if (rank == 1) {
      medalColor = AppColors.warning;
    } else if (rank == 2) {
      medalColor = AppColors.textMuted;
    } else {
      medalColor = AppColors.tertiary;
    }
    final nilai = p.points > 0 ? p.points : p.xp;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.pinkSofter : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech, color: medalColor, size: 28),
          const SizedBox(width: 12),
          if (isMe) ...[
            UserAvatar(
              imageUrl: _avatar,
              name: _nama,
              size: 32,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? 'Kamu' : p.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isMe ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Kamu',
                          style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Peringkat $rank',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.bolt,
                  color: isMe ? AppColors.primary : AppColors.secondary,
                  size: 16),
              Text(
                '${ProfilPengguna.formatAngka(nilai)} XP',
                style: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Waktu relatif singkat untuk kartu komunitas di Beranda.
String formatWaktuSingkat(DateTime? waktu) {
  if (waktu == null) return '';
  final diff = DateTime.now().difference(waktu.toLocal());
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
  if (diff.inHours < 24) return '${diff.inHours}j lalu';
  if (diff.inDays == 1) return 'Kemarin';
  return '${diff.inDays}h lalu';
}
