import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chat_controller.dart';
import '../controllers/profile_controller.dart';
import 'chat/chat_list_view.dart';
import 'home/home_page.dart';
import 'home/kuis_page.dart';
import 'home/materi_page.dart';
import 'komunitas/komunitas_page.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';
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

  List<AppNavItem> _navItems(String? avatarUrl) => [
        const AppNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Beranda',
        ),
        const AppNavItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          label: 'Kuis',
        ),
        const AppNavItem(
          svgAsset: 'assets/images/komunitas.svg',
          label: 'Komunitas',
        ),
        AppNavItem(imageUrl: avatarUrl),
      ];

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

  List<Widget> _buildPages(BuildContext context) {
    final chatUnread = context.watch<ChatController>().totalUnreadMessages;

    return [
      HomePage(
        onOpenCommunity: () => _goTo(3), // Indeks 3: Komunitas
        onOpenProfile: () => _goTo(4), // Indeks 4: Profil
      ),
      // Tab Kuis: daftar kuis diambil dari Supabase (tabel `kuis`).
      const _HeaderPage(
        header: MateriHeader(title: 'Kuis'),
        body: KuisPage(),
      ),
      const _HeaderPage(
        header: MateriHeader(),
        body: MateriPage(),
      ),
      _HeaderPage(
        header: KomunitasHeader(
          unreadCount: chatUnread,
          onMessages: () => _openChat(context),
        ),
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
    final profile = context.watch<ProfileController>().profile;

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
            for (final page in _buildPages(context))
              _KeepAlivePage(child: page),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          items: _navItems(profile?.avatarUrl),
          avatarName: profile?.displayName,
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