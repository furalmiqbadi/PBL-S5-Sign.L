import 'package:flutter/material.dart';

import 'chat/chat_list_view.dart';
import 'home/home_page.dart';
import 'home/materi_page.dart';
import 'komunitas/komunitas_page.dart'; 
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/komunitas_header.dart';
import 'widgets/materi_header.dart';
import 'widgets/profil_header.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  List<Widget> _buildPages(BuildContext context) {
    void openChat() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
      );
    }

    return [
      HomePage(
        onOpenCommunity: () => _goTo(3), // Indeks 3: Komunitas
        onOpenProfile: () => _goTo(4),   // Indeks 4: Profil
      ),
      const _HeaderPage(
        header: MateriHeader(title: 'Kuis'),
        body: _CenteredNote('Kuis dan evaluasi pemahaman tampil di sini.'),
      ),
      const _HeaderPage(
        header: MateriHeader(),
        body: MateriPage(),
      ),
      _HeaderPage(
        header: KomunitasHeader(onMessages: openChat),
        body: const KomunitasPage(),
      ),
      const _HeaderPage(
        header: ProfilHeader(), 
        body: ProfileScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

class _CenteredNote extends StatelessWidget {
  final String message;

  const _CenteredNote(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}