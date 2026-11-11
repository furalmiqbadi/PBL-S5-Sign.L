import 'package:flutter/material.dart';

import 'chat/chat_list_view.dart';
import 'home/home_page.dart';
import 'home/materi_page.dart';
import 'home/quiz_page.dart';
import 'komunitas/komunitas_page.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/komunitas_header.dart';
import 'widgets/materi_header.dart';
import 'widgets/profil_header.dart';

/// Kerangka utama aplikasi yang menampilkan [AppBottomNavBar] di semua
/// halaman tab dan mengintegrasikan seluruh alur navigasi dari semua modul.
///
/// Lima tab dengan urutan visual:
/// `0 Beranda · 1 Kuis · 2 Materi (tengah) · 3 Komunitas · 4 Profil`.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  late final PageController _pageController;

  static const Color _pink = AppColors.primary;


  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Pindah ke tab [index] dengan animasi slide.
  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  static const List<AppNavItem> _items = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    AppNavItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Kuis',
    ),
    AppNavItem(
      svgAsset: 'assets/images/komunitas.svg',
      label: 'Komunitas',
    ),
    AppNavItem(imageUrl: _profilePhotoUrl),
  ];

  static const String? _profilePhotoUrl = null;

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingScreen()),
    );
  }

  void _openQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizPage()),
    );
  }

  Widget _buildQuizView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'KUIS INTERAKTIF · 10 SOAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  const Text('+100 XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Kuis tebak gestur isyarat (A - J)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih gambar gestur tangan yang tepat untuk setiap huruf target. Dilengkapi sistem nyawa hati dan XP.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _pink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openQuiz(context),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Mulai kuis sekarang',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Kuis harian gestur',
          description: 'Uji daya ingat 10 gestur acak hari ini dan dapatkan 50 XP!',
          buttonText: 'Mulai Kuis Harian',
          onTap: () => _openQuiz(context),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Tantangan kilat 60 detik',
          description: 'Bentuk sebanyak mungkin gestur isyarat yang diminta sebelum waktu habis.',
          buttonText: 'Mulai Tantangan',
          onTap: () => _openQuiz(context),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Evaluasi modul huruf vokal',
          description: 'Selesaikan evaluasi untuk klaim sertifikat modul pemula.',
          buttonText: 'Mulai Evaluasi',
          onTap: () => _openQuiz(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onTap,
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context) {
    return [
      HomePage(
        onOpenCommunity: () => _goTo(3), // Indeks 3: Komunitas
        onOpenProfile: () => _goTo(4),   // Indeks 4: Profil
      ),
      _HeaderPage(
        header: const MateriHeader(title: 'Kuis'),
        body: _buildQuizView(context),
      ),
      const _HeaderPage(
        header: MateriHeader(),
        body: MateriPage(),
      ),
      _HeaderPage(
        header: KomunitasHeader(onMessages: () => _openChat(context)),
        body: const KomunitasPage(),
      ),
      _HeaderPage(
        header: ProfilHeader(
          onSettings: () => _openSettings(context),
        ),
        body: const ProfileScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != 0) {
          _goTo(0);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final page in _buildPages(context)) _KeepAlivePage(child: page),
          ],
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
}

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

class _HeaderPage extends StatelessWidget {
  final Widget header;
  final Widget body;

  const _HeaderPage({required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(bottom: false, child: header),
        Expanded(child: body),
      ],
    );
  }
}
