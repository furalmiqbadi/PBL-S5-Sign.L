import 'package:flutter/material.dart';

import 'chat/chat_list_view.dart';
import 'home/home_page.dart';
import 'home/kuis_page.dart';
import 'home/materi_page.dart';
import 'komunitas/komunitas_page.dart';
import 'profile/profile_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/komunitas_header.dart';
import 'widgets/materi_header.dart';
import 'widgets/profil_header.dart';

/// Kerangka utama aplikasi yang menampilkan [AppBottomNavBar] di semua
/// halaman tab.
///
/// Lima tab dengan urutan visual:
/// `0 Beranda · 1 Kuis · 2 Materi (tengah) · 3 Komunitas · 4 Profil`.
///
/// Semua halaman utama di-host di dalam [PageView], sehingga state tiap
/// halaman tetap terjaga saat berpindah tab dan navbar selalu terlihat.
///
/// Perpindahan tab dianimasikan sebagai *page turn* horizontal (slide),
/// mengikuti arah urutan tab. Geser manual dinonaktifkan agar navigasi
/// sepenuhnya lewat navbar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Pengendali halaman untuk animasi slide antar tab.
  final PageController _pageController = PageController();

  /// Indeks tab Komunitas dan Profil pada urutan visual.
  static const int _komunitasTabIndex = 3;
  static const int _profilTabIndex = 4;

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

  /// Buka layar Chat (tombol DM di header Komunitas).
  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
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

  /// Halaman tiap tab. `late final` agar dibuat sekali, dan bisa memakai
  /// callback yang butuh context milik State ini.
  late final List<Widget> _pages = [
    // Beranda punya header sendiri di dalam ListView-nya (logo, notifikasi,
    // DM, avatar), jadi tidak dibungkus _HeaderPage. Header itu ikut
    // tergulir bersama konten.
    HomePage(
      onOpenCommunity: () => _goTo(_komunitasTabIndex),
      onOpenProfile: () => _goTo(_profilTabIndex),
    ),
    // Header Kuis sama persis dengan header Materi, hanya berbeda judul.
    const _HeaderPage(
      header: MateriHeader(title: 'Kuis'),
      body: KuisPage(),
    ),
    const _HeaderPage(
      header: MateriHeader(),
      body: MateriPage(),
    ),
    _HeaderPage(
      header: KomunitasHeader(onMessages: _openChat),
      body: const KomunitasPage(),
    ),
    const _HeaderPage(
      header: ProfilHeader(),
      body: ProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final page in _pages) _KeepAlivePage(child: page),
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

/// Halaman tab yang memakai header kustom: header menempel di atas dan ikut
/// menyembunyikan diri saat konten di-scroll ke bawah, lalu muncul kembali
/// saat di-scroll ke atas. Konten mengisi sisa ruang di bawahnya.
class _HeaderPage extends StatefulWidget {
  final Widget header;
  final Widget body;

  const _HeaderPage({required this.header, required this.body});

  @override
  State<_HeaderPage> createState() => _HeaderPageState();
}

class _HeaderPageState extends State<_HeaderPage> {
  /// Ambang delta scroll (px). Gerakan lebih kecil dari ini diabaikan supaya
  /// header tidak berkedip saat scroll pelan.
  static const double _threshold = 8;

  bool _headerVisible = true;

  bool _onScroll(ScrollNotification notification) {
    // Hanya bereaksi pada scroll vertikal konten, bukan geser horizontal
    // (mis. carousel di dalam konten).
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > _threshold && _headerVisible) {
        setState(() => _headerVisible = false);
      } else if (delta < -_threshold && !_headerVisible) {
        setState(() => _headerVisible = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Column(
        children: [
          // SafeArea dipertahankan agar konten tidak naik ke area status bar
          // saat header disembunyikan.
          SafeArea(
            bottom: false,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _headerVisible
                  ? widget.header
                  : const SizedBox(width: double.infinity),
            ),
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
