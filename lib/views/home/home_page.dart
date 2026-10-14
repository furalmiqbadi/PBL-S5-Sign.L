import 'package:flutter/material.dart';
import '../chat/chat_list_view.dart';
import '../komunitas/komunitas_page.dart';
import 'detail_materi_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onOpenCommunity;
  final VoidCallback? onOpenProfile; // <-- TAMBAHAN CALLBACK PROFIL

  const HomePage({
    super.key, 
    this.onOpenCommunity,
    this.onOpenProfile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _communityPageController = PageController();
  int _currentCommunityPage = 0;

  @override
  void dispose() {
    _communityPageController.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _continueLearning() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DetailMateriPage()),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beralih ke halaman Profil...')),
      );
    }
  }

  void _openLeaderboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuka Papan Peringkat Lengkap...')),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuka Notifikasi...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsBar(),
            const SizedBox(height: 24),
            _buildContinueLearningCard(),
            const SizedBox(height: 24),
            _buildCommunitySnippetCard(),
            const SizedBox(height: 24),
            _buildLeaderboardSnippetCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.pinkSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sign_language, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Sign.L',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Color(0xFF1C1B1B)),
              onPressed: _openNotifications,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.send_outlined, color: Color(0xFF1C1B1B)),
              onPressed: _openChat,
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // FOTO PROFIL SUDAH DISAMBUNGKAN KE PAGE PROFIL
        GestureDetector(
          onTap: _openProfile,
          child: const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FA),
        border: Border.all(color: const Color(0xFFF3E5ED)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.local_fire_department, Colors.orange, 'Streak', '7 Hari'),
          Container(width: 1, height: 32, color: const Color(0xFFE0D4D9)),
          _buildStatItem(Icons.favorite, AppColors.primary, 'Nyawa', '5/5'),
          Container(width: 1, height: 32, color: const Color(0xFFE0D4D9)),
          _buildStatItem(Icons.diamond, Colors.purpleAccent, 'Diamond', '420'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContinueLearningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E5ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'LANJUTKAN BELAJAR',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '68% Selesai',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bab 1: Alfabet Isyarat',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Materi Terakhir: Huruf J s/d R & Latihan Refleks',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFEEEEEE),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.68,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [Colors.purpleAccent, AppColors.primary],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _continueLearning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySnippetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E5ED)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_outlined, color: Color(0xFF3E1128)),
                  const SizedBox(width: 8),
                  Text(
                    'Komunitas',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _openCommunity,
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua\nKomunitas',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: PageView(
              controller: _communityPageController,
              onPageChanged: (index) {
                setState(() => _currentCommunityPage = index);
              },
              children: [
                _buildCommunityPostItem(),
                _buildCommunityPostItem(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentCommunityPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentCommunityPage == index ? AppColors.primary : const Color(0xFFE0D4D9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rian Pratama',
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '10m lalu',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Ada yang tahu perbedaan gestur 'Terima Kasih' vs 'Sama-Sama' di BISINDO daerah...",
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text('24 suka', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF9E9E9E), size: 14),
              const SizedBox(width: 4),
              Text('8 balasan', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSnippetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3E5ED)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Papan Peringkat\nPekan Ini',
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openLeaderboard,
                child: Row(
                  children: [
                    Text(
                      'Lihat Peringkat\nPenuh',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLeaderboardItem(1, 'Budi Santoso', '1,420 XP', false),
          _buildLeaderboardItem(2, 'Dina S.', '1,280 XP', false),
          _buildLeaderboardItem(3, 'Sarah Chen', '1,150 XP', true),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String name, String xp, bool isCurrentUser) {
    Widget medalIcon;
    if (rank == 1) {
      medalIcon = const Icon(Icons.military_tech, color: Colors.amber, size: 28);
    } else if (rank == 2) {
      medalIcon = const Icon(Icons.military_tech, color: Colors.grey, size: 28);
    } else {
      medalIcon = const Icon(Icons.military_tech, color: Colors.brown, size: 28);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.pinkSoft.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
        boxShadow: isCurrentUser
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          medalIcon,
          const SizedBox(width: 12),
          if (isCurrentUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Kamu',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isCurrentUser ? 'Peringkat $rank (+2 posisi hari ini)' : 'Peringkat $rank',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.bolt, color: isCurrentUser ? AppColors.primary : Colors.purpleAccent, size: 16),
              Text(
                xp,
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}