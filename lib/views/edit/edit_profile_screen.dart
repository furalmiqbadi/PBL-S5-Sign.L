import 'package:flutter/material.dart';

/// Halaman Edit Profil Sign-L
/// Sesuai referensi Figma & Stitch:
/// - Ubah Foto Profil
/// - Informasi Dasar (Nama, Username, Bio, Email terverifikasi, Nomor Telepon)
/// - Pencapaian Unggulan (Kelola slot maksimal 3 lencana)
/// - Preferensi Isyarat (Tingkat Kemahiran & Motivasi Belajar)
/// - Tingkatan Role Akun (Timeline level Penjelajah 65%)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Brand Colors
  static const Color primaryColor = Color(0xFFC40083);
  static const Color darkTextColor = Color(0xFF302036);
  static const Color mutedTextColor = Color(0xFF826D80);
  static const Color lightBgColor = Color(0xFFF8F6F9);
  static const Color borderColor = Color(0xFFEBE5EE);

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // State Preferensi Isyarat
  String _selectedLevel = 'Tingkat Menengah (Level 2)';
  String _selectedLevelDesc = 'BISINDO & Pemahaman Ekspresif';
  String _selectedLevelCode = 'L2';

  final Set<String> _selectedMotivations = {
    'Komunikasi Keluarga',
    'Pekerjaan',
    'Teman Tuli',
  };

  // State Pencapaian Unggulan (Maksimal 3 slot)
  final List<String> _selectedBadgeIds = [
    'perfect_100',
    'streak_7',
    'fast_signer',
  ];

  // Data Master Lencana Pencapaian
  final List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'perfect_100',
      'title': 'Perfect 100',
      'desc': 'Akurasi 100% pada 10 sesi evaluasi isyarat berturut-turut',
      'icon': Icons.stars_rounded,
      'color': const Color(0xFFE91E63),
      'bg': const Color(0xFFFCE7F3),
      'isUnlocked': true,
      'category': 'Evaluasi',
    },
    {
      'id': 'streak_7',
      'title': '7-Day Streak',
      'desc': 'Berlatih isyarat minimal 15 menit setiap hari selama 7 hari',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFF7E57C2),
      'bg': const Color(0xFFF3E8FF),
      'isUnlocked': true,
      'category': 'Konsistensi',
    },
    {
      'id': 'fast_signer',
      'title': 'Fast Signer',
      'desc': 'Kecepatan respon isyarat di bawah 1.2 detik saat kuis',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFF57C00),
      'bg': const Color(0xFFFFEDD5),
      'isUnlocked': true,
      'category': 'Kecepatan',
    },
    {
      'id': 'kamus_explorer',
      'title': 'Kamus Explorer',
      'desc': 'Mempelajari dan mempraktikkan lebih dari 50 kosakata kamus',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xFF0284C7),
      'bg': const Color(0xFFE0F2FE),
      'isUnlocked': true,
      'category': 'Eksplorasi',
    },
    {
      'id': 'komunitas_bintang',
      'title': 'Komunitas Bintang',
      'desc': 'Aktif berkontribusi di 20 diskusi tanya jawab komunitas',
      'icon': Icons.forum_rounded,
      'color': const Color(0xFF059669),
      'bg': const Color(0xFFD1FAE5),
      'isUnlocked': false,
      'category': 'Komunitas',
    },
    {
      'id': 'master_signer',
      'title': 'Master Isyarat L3',
      'desc': 'Menyelesaikan seluruh modul kurikulum tingkat mahir',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFF9333EA),
      'bg': const Color(0xFFF3E8FF),
      'isUnlocked': false,
      'category': 'Kurikulum',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Sarah Chen');
    _usernameController = TextEditingController(text: '@sarah.creates');
    _bioController = TextEditingController(
      text: 'Pelajar Bahasa Isyarat BISINDO Pemula • Passionate in Accessibility',
    );
    _emailController = TextEditingController(text: 'sarah.chen@example.com');
    _phoneController = TextEditingController(text: '+62 812-3456-7890');

    _bioController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Perubahan profil berhasil disimpan!'),
          ],
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  void _showChangePhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF0FA),
                    child: Icon(Icons.photo_camera_rounded, color: primaryColor),
                  ),
                  title: const Text('Ambil Foto Baru', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamera dibuka...')),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.photo_library_rounded, color: Color(0xFF7E57C2)),
                  ),
                  title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Galeri dibuka...')),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFECEC),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto profil dihapus')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final levels = [
          {
            'code': 'L1',
            'title': 'Tingkat Pemula (Level 1)',
            'desc': 'Alfabet, Angka & Frasa Dasar BISINDO',
          },
          {
            'code': 'L2',
            'title': 'Tingkat Menengah (Level 2)',
            'desc': 'BISINDO & Pemahaman Ekspresif',
          },
          {
            'code': 'L3',
            'title': 'Tingkat Mahir (Level 3)',
            'desc': 'Percakapan Kompleks & Cerita Isyarat',
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Tingkat Kemahiran Isyarat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                for (final lvl in levels)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lvl['title'] == _selectedLevel
                          ? primaryColor
                          : const Color(0xFFF3E8FF),
                      child: Text(
                        lvl['code']!,
                        style: TextStyle(
                          color: lvl['title'] == _selectedLevel
                              ? Colors.white
                              : const Color(0xFF7E57C2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      lvl['title']!,
                      style: TextStyle(
                        fontWeight: lvl['title'] == _selectedLevel
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: darkTextColor,
                      ),
                    ),
                    subtitle: Text(lvl['desc']!, style: const TextStyle(fontSize: 12)),
                    trailing: lvl['title'] == _selectedLevel
                        ? const Icon(Icons.check_circle_rounded, color: primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLevel = lvl['title']!;
                        _selectedLevelDesc = lvl['desc']!;
                        _selectedLevelCode = lvl['code']!;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRoleDetailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text(
              'Detail Role: Penjelajah',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Sarah Chen:',
              style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor),
            ),
            SizedBox(height: 4),
            Text(
              '• Bergabung: 4 bulan lalu\n'
              '• Progres menuju Mahir: 65%\n'
              '• Estimasi naik level: 2 bulan lagi dengan latihan rutin\n'
              '• Benefit aktif: Kustomisasi 3 lencana profil publik',
              style: TextStyle(fontSize: 13, height: 1.5, color: darkTextColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAchievementSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            int filterTabIndex = 0; // 0: Semua (6), 1: Sudah Didapat (4), 2: Belum Terbuka (2)
            String selectedCategory = 'Semua Kategori';

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                // Filter badge list
                List<Map<String, dynamic>> displayedBadges = _allBadges;
                if (filterTabIndex == 1) {
                  displayedBadges = _allBadges.where((b) => b['isUnlocked'] == true).toList();
                } else if (filterTabIndex == 2) {
                  displayedBadges = _allBadges.where((b) => b['isUnlocked'] == false).toList();
                }

                if (selectedCategory != 'Semua Kategori') {
                  displayedBadges = displayedBadges
                      .where((b) => b['category'] == selectedCategory)
                      .toList();
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header Modal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.military_tech_rounded,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelola Pencapaian Unggulan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: darkTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pilih maksimal 3 lencana untuk disematkan di profil publik',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(modalContext),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 18, color: darkTextColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Baris Slot Terpilih & Batas Maksimum
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Slot Terpilih: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: darkTextColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_selectedBadgeIds.length} / 3 Terpilih',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7E22CE),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Batas maksimum: 3',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Pencapaian Filter Pills
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'STATUS PENCAPAIAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: mutedTextColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '6 Total Lencana',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildModalTabPill(
                                    label: 'Semua (6)',
                                    isSelected: filterTabIndex == 0,
                                    onTap: () => setModalState(() => filterTabIndex = 0),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildModalTabPill(
                                    label: 'Sudah Didapat (4)',
                                    isSelected: filterTabIndex == 1,
                                    onTap: () => setModalState(() => filterTabIndex = 1),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildModalTabPill(
                                    label: 'Belum Terbuka (2)',
                                    isSelected: filterTabIndex == 2,
                                    onTap: () => setModalState(() => filterTabIndex = 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filter Kategori Dropdown Pill
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FILTER KATEGORI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: mutedTextColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: lightBgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_outlined, size: 16, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedCategory,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: darkTextColor,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: mutedTextColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status Role Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF9333EA), size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status Role: Penjelajah',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: darkTextColor,
                                      ),
                                    ),
                                    Text(
                                      'Akses kustomisasi 3 lencana profil aktif',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '65% Menuju Mahir',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7E22CE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Daftar Lencana
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: displayedBadges.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final badge = displayedBadges[index];
                            final String id = badge['id'];
                            final bool isSelected = _selectedBadgeIds.contains(id);
                            final bool isUnlocked = badge['isUnlocked'] as bool;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? (badge['color'] as Color)
                                      : borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isUnlocked ? (badge['color'] as Color) : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          badge['icon'] as IconData,
                                          color: isUnlocked ? Colors.white : Colors.grey.shade400,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  badge['title'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: darkTextColor,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? (badge['color'] as Color).withValues(alpha: 0.15)
                                                        : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isSelected
                                                        ? '✓ Terpilih'
                                                        : (isUnlocked ? 'Tersedia untuk Dipilih' : '🔒 Belum Terbuka'),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected
                                                          ? (badge['color'] as Color)
                                                          : mutedTextColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              badge['desc'] as String,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: mutedTextColor,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, thickness: 0.8, color: Color(0xFFF3EDF5)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                                            size: 14,
                                            color: isUnlocked ? const Color(0xFF10B981) : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isUnlocked ? 'Sudah Didapat' : 'Belum Terbuka',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isUnlocked ? const Color(0xFF10B981) : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isSelected)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedBadgeIds.remove(id);
                                            });
                                            setModalState(() {});
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            child: Text(
                                              'Hapus',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isUnlocked)
                                        InkWell(
                                          onTap: () {
                                            if (_selectedBadgeIds.length >= 3) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Batas maksimal 3 lencana terpilih! Hapus salah satu terlebih dahulu.'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _selectedBadgeIds.add(id);
                                            });
                                            setModalState(() {});
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(Icons.add_circle_outline_rounded, size: 14, color: primaryColor),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pilih Ini',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Terkunci',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildModalTabPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : darkTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded, color: primaryColor, size: 18),
              label: const Text(
                'Simpan',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // 1. Avatar Section
            _buildAvatarSection(),
            const SizedBox(height: 24),

            // 2. Card: Informasi Dasar
            _buildCardInformasiDasar(),
            const SizedBox(height: 20),

            // 3. Card: Pencapaian Unggulan
            _buildCardPencapaianUnggulan(),
            const SizedBox(height: 20),

            // 4. Card: Preferensi Isyarat
            _buildCardPreferensiIsyarat(),
            const SizedBox(height: 20),

            // 5. Card: Tingkatan Role Akun
            _buildCardRoleAkun(),
            const SizedBox(height: 32),
            
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=47'),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _showChangePhotoModal,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _showChangePhotoModal,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, color: primaryColor, size: 14),
                SizedBox(width: 6),
                Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardInformasiDasar() {
    return _buildContainerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.contact_page_rounded,
            title: 'Informasi Dasar',
          ),
          const SizedBox(height: 16),

          // Nama Lengkap
          _buildFieldLabel('Nama Lengkap'),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),

          // Username / ID Pengguna
          _buildFieldLabel('Username / ID Pengguna'),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _usernameController,
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 14),

          // Bio Singkat dengan Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Bio Singkat'),
              Text(
                '${_bioController.text.length}/150',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _bioController,
            prefixIcon: Icons.edit_note_rounded,
            maxLines: 2,
            maxLength: 150,
            showCounter: false,
          ),
          const SizedBox(height: 14),

          // Email
          _buildFieldLabel('Email'),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            suffixIcon: const Icon(
              Icons.check_circle_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 14),

          // Nomor Telepon
          _buildFieldLabel('Nomor Telepon'),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildCardPencapaianUnggulan() {
    final selectedBadgesData = _allBadges
        .where((b) => _selectedBadgeIds.contains(b['id']))
        .toList();

    return _buildContainerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pencapaian Unggulan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkTextColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Maksimal 3 lencana disematkan di profil',
                      style: TextStyle(fontSize: 11, color: mutedTextColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedBadgeIds.length} dari 3 dipilih',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Selected Badges
          if (selectedBadgesData.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: lightBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Belum ada lencana yang disematkan.\nPilih dari daftar di bawah!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: mutedTextColor),
              ),
            )
          else
            Column(
              children: [
                for (final badge in selectedBadgesData) ...[
                  _buildFeaturedBadgeCard(badge),
                  const SizedBox(height: 12),
                ],
              ],
            ),

          const SizedBox(height: 4),

          // Tombol Kelola & Lihat Semua Pencapaian
          InkWell(
            onTap: _openAchievementSelectionModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE2F1)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFC40083),
                    child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola & Lihat Semua Pencapaian',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '4 Terbuka, 2 Terkunci • Pilih & Ganti lencana',
                          style: TextStyle(fontSize: 10, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Dashed Outline: + Kelola Lencana Lainnya
          InkWell(
            onTap: _openAchievementSelectionModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 15, color: primaryColor),
                    SizedBox(width: 6),
                    Text(
                      'Kelola Lencana Lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadgeCard(Map<String, dynamic> badge) {
    final Color badgeColor = badge['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          badge['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '✓ Terpilih (Maks 3)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge['desc'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: mutedTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'Selesai • Ditampilkan di profil',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedBadgeIds.remove(badge['id']);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lencana ${badge['title']} dilepas dari profil'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: mutedTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreferensiIsyarat() {
    return _buildContainerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.back_hand_rounded,
            title: 'Preferensi Isyarat',
            iconColor: const Color(0xFFE65100),
          ),
          const SizedBox(height: 16),

          // Tingkat Kemahiran Isyarat
          _buildFieldLabel('Tingkat Kemahiran Isyarat'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showLevelPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8B4FE)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF7E57C2),
                    child: Text(
                      _selectedLevelCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLevel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedLevelDesc,
                          style: const TextStyle(fontSize: 11, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7E57C2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Motivasi Belajar
          _buildFieldLabel('Motivasi Belajar'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMotivationChip('Komunikasi Keluarga', const Color(0xFFC40083), Colors.white),
              _buildMotivationChip('Pekerjaan', const Color(0xFFF3E8FF), const Color(0xFF7E22CE)),
              _buildMotivationChip('Teman Tuli', const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
              _buildMotivationChip('Advokasi Sosial', lightBgColor, darkTextColor),
              _buildMotivationChip('Hobi & Edukasi', lightBgColor, darkTextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationChip(String label, Color bgColor, Color textColor) {
    final bool isSelected = _selectedMotivations.contains(label);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMotivations.remove(label);
          } else {
            _selectedMotivations.add(label);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : lightBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: isSelected ? textColor : mutedTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? textColor : mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRoleAkun() {
    return _buildContainerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF7E57C2), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tingkatan Role Akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkTextColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Loyalitas & Masa Pakai Sign-L',
                      style: TextStyle(fontSize: 11, color: mutedTextColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Penjelajah',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Highlight Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCE7F3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Status Anda: Penjelajah',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: darkTextColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E22CE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bergabung 4 bulan lalu • Menuju Mahir',
                          style: TextStyle(fontSize: 10, color: mutedTextColor),
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '65%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7E22CE),
                          ),
                        ),
                        Text(
                          '2 bulan lagi',
                          style: TextStyle(fontSize: 9, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 7,
                    color: primaryColor,
                    backgroundColor: Color(0xFFF0E5F3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timeline Langkah Role
          _buildRoleTimelineStep(
            icon: Icons.check_rounded,
            iconBgColor: const Color(0xFF10B981),
            title: 'Pemula',
            subtitle: 'Baru bergabung di Sign-L',
            badgeText: 'Tercapai ✓',
            badgeBgColor: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF065F46),
            isDone: true,
            hasLine: true,
            lineColor: const Color(0xFF10B981),
          ),
          _buildRoleTimelineStep(
            icon: Icons.explore_rounded,
            iconBgColor: const Color(0xFF8B5CF6),
            title: 'Penjelajah',
            activePill: true,
            subtitle: 'Aktif 1 - 6 Bulan & menjelajahi kamus\nStatus Sarah Chen: Progres 65% menuju Mahir',
            badgeText: '1 - 6 Bulan',
            badgeBgColor: const Color(0xFFF3E8FF),
            badgeTextColor: const Color(0xFF7E22CE),
            actionLink: 'Ketuk detail',
            onActionTap: _showRoleDetailDialog,
            isDone: true,
            hasLine: true,
            lineColor: Colors.grey.shade300,
          ),
          _buildRoleTimelineStep(
            icon: Icons.lightbulb_outline_rounded,
            iconBgColor: Colors.grey.shade300,
            iconColor: Colors.grey.shade600,
            title: 'Mahir',
            subtitle: 'Aktif 1 - 2 Tahun & kontributor latihan',
            badgeText: '🔒 Belum Terbuka',
            badgeBgColor: Colors.grey.shade100,
            badgeTextColor: mutedTextColor,
            isDone: false,
            hasLine: true,
            lineColor: Colors.grey.shade300,
          ),
          _buildRoleTimelineStep(
            icon: Icons.emoji_events_outlined,
            iconBgColor: Colors.grey.shade300,
            iconColor: Colors.grey.shade600,
            title: 'Master Signer',
            subtitle: 'Aktif 3+ Tahun & mentor duta aksesibilitas',
            badgeText: '🔒 Belum Terbuka',
            badgeBgColor: Colors.grey.shade100,
            badgeTextColor: mutedTextColor,
            isDone: false,
            hasLine: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTimelineStep({
    required IconData icon,
    required Color iconBgColor,
    Color iconColor = Colors.white,
    required String title,
    bool activePill = false,
    required String subtitle,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    String? actionLink,
    VoidCallback? onActionTap,
    required bool isDone,
    required bool hasLine,
    Color? lineColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Ikon & Garis vertikal
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (hasLine)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineColor ?? Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Kolom Konten
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor,
                            ),
                          ),
                          if (activePill) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E22CE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: mutedTextColor,
                      height: 1.3,
                    ),
                  ),
                  if (actionLink != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onActionTap,
                      child: Text(
                        actionLink,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7E22CE),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF8E005F),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveProfile,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildContainerCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    Color iconColor = primaryColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: darkTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: darkTextColor,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        buildCounter: showCounter
            ? null
            : (context, {required currentLength, required isFocused, maxLength}) => null,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        decoration: InputDecoration(
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(prefixIcon, color: mutedTextColor, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.2),
          ),
        ),
      ),
    );
  }
}
