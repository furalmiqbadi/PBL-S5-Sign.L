import 'package:flutter/material.dart';

import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/home_header.dart';
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
///
/// Catatan: [PlaceholderScreen] di bawah hanya penanda sementara. Ganti
/// isinya dengan layar asli, mis. `HomeScreen`, `QuizScreen`, `MateriScreen`,
/// `CommunityScreen`, dan `ProfileScreen` sesuai struktur di `lib/views/`.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Pengendali halaman untuk animasi slide antar tab.
  final PageController _pageController = PageController();

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

  // 5 tab dengan urutan visual:
  // 0 Beranda | 1 Kuis | 2 Materi (tengah) | 3 Komunitas | 4 Profil
  // `_items` hanya untuk 4 slot kiri/kanan; tengah diatur terpisah.
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
      // Ikon Komunitas memakai logo SVG kustom (di-tint otomatis).
      svgAsset: 'assets/images/komunitas.svg',
      label: 'Komunitas',
    ),
    // Tab Profil memakai foto profil bulat (tanpa label). Isi [_profilePhotoUrl]
    // dengan foto pengguna; biarkan null untuk memakai foto dummy.
    AppNavItem(imageUrl: _profilePhotoUrl),
  ];

  /// URL foto profil pengguna. `null` = pakai foto dummy bawaan.
  static const String? _profilePhotoUrl = null;

  static const List<Widget> _pages = [
    _HeaderPage(
      header: HomeHeader(),
      body: _CenteredNote(
        'Jalur belajar harian (streak, XP, level) tampil di sini.',
      ),
    ),
    // Header Kuis sama persis dengan header Materi, hanya berbeda judul.
    _HeaderPage(
      header: MateriHeader(title: 'Kuis'),
      body: _CenteredNote('Kuis dan evaluasi pemahaman tampil di sini.'),
    ),
    _HeaderPage(
      header: MateriHeader(),
      body: _CenteredNote('Daftar materi bahasa isyarat tampil di sini.'),
    ),
    _HeaderPage(
      header: KomunitasHeader(),
      body: _CenteredNote('Forum diskusi dan latihan bersama tampil di sini.'),
    ),
    _HeaderPage(
      header: ProfilHeader(),
      body: _CenteredNote(
        'Progres belajar, XP, dan pengaturan akun tampil di sini.',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Semua tab memakai header kustom, jadi AppBar bawaan tidak dipakai.
      //
      // [PageView] memberi animasi slide antar tab; tiap halaman dibungkus
      // [_KeepAlivePage] agar state-nya tidak dibuang saat berada di luar layar.
      body: PageView(
        controller: _pageController,
        // Navigasi hanya lewat navbar, bukan geser manual.
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

/// Membungkus halaman tab agar tetap hidup (state terjaga) meski berada di
/// luar layar di dalam [PageView].
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

/// Halaman tab yang memakai header kustom: header menempel di atas, konten
/// mengisi sisa ruang di bawahnya. Header ikut safe-area bagian atas.
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

/// Catatan sementara di tengah area konten.
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

/// Layar penanda sementara untuk mengisi tiap tab.
///
/// Ganti dengan layar asli sesuai struktur `lib/views/`.
class PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const PlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
