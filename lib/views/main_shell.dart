import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'auth/auth_views.dart';
import 'home/quiz_page.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/komunitas_header.dart';
import 'widgets/materi_header.dart';
import 'widgets/profil_header.dart';

/// Kerangka utama aplikasi yang menampilkan [AppBottomNavBar] di semua
/// halaman tab dan mengintegrasikan seluruh alur navigasi serta profil/logout.
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

  static const Color _pink = Color(0xFFC40083);
  static const Color _bgSoft = Color(0xFFFFF7FC);
  static const Color _cardBorder = Color(0xFFF2D9EB);

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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // 4 slot kiri & kanan navbar; slot tengah (Materi) diatur terpisah
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
    AppNavItem(imageUrl: null),
  ];

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: _pink),
                SizedBox(width: 8),
                Text(
                  'Notifikasi Kamu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFFFE5F5),
                child: Text('🔥'),
              ),
              title: Text('Pertahankan Streak Belajar!'),
              subtitle: Text('Kamu sudah belajar 3 hari berturut-turut.'),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE5F6FF),
                child: Text('✋'),
              ),
              title: Text('Modul Baru Terbuka'),
              subtitle: Text('Modul Alfabet Bahasa Isyarat siap dipelajari.'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: _pink),
            SizedBox(width: 8),
            Text('Pesan Masuk'),
          ],
        ),
        content: const Text(
          'Belum ada pesan langsung baru. Kamu bisa berinteraksi di tab Komunitas!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _goTo(3); // Buka tab Komunitas
            },
            child: const Text('Ke Komunitas'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengaturan Aplikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline, color: _pink),
              title: const Text('Edit Profil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _goTo(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_up_outlined, color: _pink),
              title: const Text('Efek Suara & Haptic Feedback'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar? Kemajuan belajar kamu tetap tersimpan dengan aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthController>();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  void _showCameraComingSoonDialog(BuildContext context, String moduleTitle) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.camera_alt_rounded, color: _pink),
            const SizedBox(width: 8),
            Expanded(child: Text(moduleTitle)),
          ],
        ),
        content: const Text(
          'Fitur kamera deteksi gestur AI on-device (TensorFlow Lite) sedang disiapkan oleh tim ML. '
          'Kamu akan segera dapat melatih gestur tangan secara real-time!',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Pill status gamifikasi harian
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C2C1234),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🔥', '3', 'Streak'),
              Container(width: 1, height: 28, color: _cardBorder),
              _buildStatItem('💎', '120', 'Permata'),
              Container(width: 1, height: 28, color: _cardBorder),
              _buildStatItem('⭐', '450', 'Total XP'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Banner modul aktif
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC40083), Color(0xFF9825B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33C40083),
                blurRadius: 12,
                offset: Offset(0, 6),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'UNIT 1 · PEMULA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.sign_language_rounded, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Mengenal Huruf Isyarat A - E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kuasai bentuk 5 gestur pertama dan verifikasi lewat kamera AI.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => _showCameraComingSoonDialog(context, 'Latihan Isyarat Unit 1'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Mulai Latihan Sekarang',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Jalur Belajar (Learning Path)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        _buildLevelTile(
          title: 'Tingkat 1: Huruf Vokal',
          subtitle: 'A, I, U, E, O · Selesai 100%',
          status: 'Selesai',
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          onTap: () => _showCameraComingSoonDialog(context, 'Tingkat 1: Huruf Vokal'),
        ),
        _buildLevelTile(
          title: 'Tingkat 2: Huruf Konsonan Dasar',
          subtitle: 'B, C, D, F, G · Sedang Dipelajari',
          status: 'Aktif',
          icon: Icons.play_circle_fill_rounded,
          iconColor: _pink,
          onTap: () => _showCameraComingSoonDialog(context, 'Tingkat 2: Huruf Konsonan'),
        ),
        _buildLevelTile(
          title: 'Tingkat 3: Angka 1 sampai 10',
          subtitle: 'Selesaikan Tingkat 2 untuk membuka',
          status: 'Terkunci',
          icon: Icons.lock_rounded,
          iconColor: Colors.grey,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selesaikan Tingkat 2 terlebih dahulu!')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String val, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              val,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLevelTile({
    required String title,
    required String subtitle,
    required String status,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: _cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: iconColor, size: 30),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizPage()),
    );
  }

  Widget _buildQuizView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC40083), Color(0xFF9825B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33C40083),
                blurRadius: 10,
                offset: Offset(0, 4),
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
                  const Text('⭐ +100 XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Kuis Tebak Gestur Isyarat (A - J) ✋',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _openQuiz(context),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Mulai Kuis Sekarang  ▶',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Kuis Harian Gestur 🎯',
          description: 'Uji daya ingat 10 gestur acak hari ini dan dapatkan 50 XP!',
          buttonText: 'Mulai Kuis Harian',
          onTap: () => _openQuiz(context),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Tantangan Kilat 60 Detik ⚡',
          description: 'Bentuk sebanyak mungkin gestur isyarat yang diminta sebelum waktu habis.',
          buttonText: 'Mulai Tantangan',
          onTap: () => _openQuiz(context),
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Evaluasi Modul Huruf Vokal 📝',
          description: 'Selesaikan evaluasi untuk klaim sertifikat modul pemula.',
          buttonText: 'Mulai Evaluasi',
          onTap: () => _openQuiz(context),
        ),
      ],
    );
  }


  Widget _buildMateriView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMateriItem(
          title: 'Alfabet Bahasa Isyarat (A - Z)',
          desc: 'Panduan visual lengkap 26 huruf isyarat BISINDO / SIBI.',
          count: '26 Materi',
          onTap: () => _showCameraComingSoonDialog(context, 'Alfabet A - Z'),
        ),
        _buildMateriItem(
          title: 'Angka Isyarat (0 - 10)',
          desc: 'Pengenalan simbol jari untuk berhitung dasar.',
          count: '11 Materi',
          onTap: () => _showCameraComingSoonDialog(context, 'Angka 0 - 10'),
        ),
        _buildMateriItem(
          title: 'Kata Sapaan & Kesopanan',
          desc: 'Halo, Terima Kasih, Sama-sama, Maaf, dan Sampai Jumpa.',
          count: '8 Materi',
          onTap: () => _showCameraComingSoonDialog(context, 'Kata Sapaan'),
        ),
        _buildMateriItem(
          title: 'Ekspresi Sehari-hari',
          desc: 'Keluarga, Waktu, Makanan, dan Perasaan.',
          count: '15 Materi',
          onTap: () => _showCameraComingSoonDialog(context, 'Ekspresi Sehari-hari'),
        ),
      ],
    );
  }

  Widget _buildMateriItem({
    required String title,
    required String desc,
    required String count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: _cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_rounded, color: _pink),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(desc, style: const TextStyle(fontSize: 11.5)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D9EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(count, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _pink)),
          ),
          onTap: onTap,
        ),
      ),
    );
  }


  Widget _buildKomunitasView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCommunityCard(
          author: 'Salma (Frontend)',
          tag: 'Diskusi UI',
          time: '1 jam lalu',
          title: 'Tips mengingat bentuk huruf R dan U agar tidak tertukar',
          content: 'Huruf R menyilangkan jari telunjuk dan tengah, sedangkan huruf U merapatkan kedua jari lurus ke atas.',
        ),
        const SizedBox(height: 12),
        _buildCommunityCard(
          author: 'Ghofur (ML Team)',
          tag: 'Model AI',
          time: '3 jam lalu',
          title: 'Model TFLite untuk 26 alfabet sedang tahap validasi akurasi',
          content: 'Kami sedang mengoptimalkan inference time agar responsif di bawah 50ms di perangkat Android.',
        ),
        const SizedBox(height: 12),
        _buildCommunityCard(
          author: 'Rifo & Fatah (Backend)',
          tag: 'Pengumuman',
          time: 'Kemarin',
          title: 'Struktur data leaderboard dan progres pengguna sudah siap',
          content: 'Skema Cloud Firestore untuk sinkronisasi XP dan modul telah terintegrasi dengan arsitektur.',
        ),
      ],
    );
  }

  Widget _buildCommunityCard({
    required String author,
    required String tag,
    required String time,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFE5F5),
                child: Text(author[0], style: const TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2D9EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 10, color: _pink, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildProfilView(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userName = auth.currentName.isNotEmpty ? auth.currentName : 'Budi Pratama';
    final userEmail = auth.currentEmail.isNotEmpty ? auth.currentEmail : 'budi@gmail.com';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Kartu Profil Utama
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C2C1234),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_pink, Color(0xFF9825B4)]),
                    ),
                    child: const CircleAvatar(
                      radius: 38,
                      backgroundImage: NetworkImage(kDummyAvatarUrl),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('⭐', '450', 'XP Diperoleh'),
                  Container(width: 1, height: 26, color: _cardBorder),
                  _buildStatItem('🔥', '3', 'Hari Streak'),
                  Container(width: 1, height: 26, color: _cardBorder),
                  _buildStatItem('🏆', '#4', 'Liga Perunggu'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Akun & Preferensi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        _buildProfileTile(
          icon: Icons.person_outline,
          title: 'Pengaturan Akun',
          subtitle: 'Ubah nama pengguna dan kata sandi',
          onTap: () => _showSettingsSheet(context),
        ),
        _buildProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Pengingat Belajar',
          subtitle: 'Atur jadwal notifikasi latihan harian',
          onTap: () => _showNotificationSheet(context),
        ),
        _buildProfileTile(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Sign.L',
          subtitle: 'Versi 1.0.0+1 · PBL S5 Mobile App',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Sign.L',
              applicationVersion: '1.0.0+1',
              applicationLegalese: '© 2026 Tim PBL Sign.L',
            );
          },
        ),

        const SizedBox(height: 16),

        // Tombol Log Out
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Color(0xFFFFBCCB), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: _cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: _pink),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }


  Widget _buildActionCard({
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      _HeaderPage(
        header: HomeHeader(
          notificationCount: 3,
          onNotifications: () => _showNotificationSheet(context),
          onMessages: () => _showMessageDialog(context),
          onAvatarTap: () => _goTo(4), // Klik avatar di header langsung ke tab profil
        ),
        body: _buildHomeView(context),
      ),
      _HeaderPage(
        header: const MateriHeader(title: 'Kuis'),
        body: _buildQuizView(context),
      ),
      _HeaderPage(
        header: const MateriHeader(),
        body: _buildMateriView(context),
      ),
      _HeaderPage(
        header: const KomunitasHeader(),
        body: _buildKomunitasView(context),
      ),
      _HeaderPage(
        header: ProfilHeader(
          onMessages: () => _showMessageDialog(context),
          onSettings: () => _showSettingsSheet(context),
        ),
        body: _buildProfilView(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);

    return PopScope<void>(
      // Jika di tab selain 0, tombol back kembali ke tab Beranda
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != 0) {
          _goTo(0);
        }
      },
      child: Scaffold(
        backgroundColor: _bgSoft,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final page in pages) _KeepAlivePage(child: page),
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

/// Membungkus halaman tab agar state tetap terjaga saat berganti tab.
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

/// Halaman tab dengan header kustom menempel di atas SafeArea.
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
