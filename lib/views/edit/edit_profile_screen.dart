import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/nama_tampil.dart';
import '../../models/profil_model.dart';
import '../../services/auth_service.dart';
import '../../services/image_compress_service.dart';
import '../../services/profil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';

/// Halaman Edit Profil Sign-L
/// Sesuai referensi Figma & Stitch:
/// - Ubah Foto Profil
/// - Informasi Dasar (Nama, Username, Bio, Email terverifikasi, Nomor Telepon)
/// - Pencapaian Unggulan (Kelola slot maksimal 3 lencana)
/// - Preferensi Isyarat (Tingkat Kemahiran & Motivasi Belajar)
/// - Tingkatan Role Akun (timeline 3 tingkat berdasarkan `profiles.level`)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfilService _profilService = ProfilService();
  final AuthService _authService = AuthService();

  // Foto profil: berkas lokal yang baru dipilih, atau URL tersimpan di server.
  final ImagePicker _picker = ImagePicker();
  String? _avatarPath;
  String _avatarUrl = '';

  ProfilPengguna? _profil;
  bool _loading = true;
  bool _saving = false;

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;

  /// Email akun diambil dari sesi Supabase Auth (tidak dapat diubah di sini).
  String get _email => _authService.currentUser?.email ?? '';

  /// Tingkat kemahiran isyarat disimpan di kolom `profiles.level`.
  int _level = 1;

  final Set<String> _selectedMotivations = {};

  // State Pencapaian Unggulan (maksimal 3 slot)
  final List<String> _selectedBadgeIds = [];

  static const List<Map<String, dynamic>> _daftarLevel = [
    {
      'level': 1,
      'code': 'L1',
      'title': 'Tingkat Pemula (Level 1)',
      'desc': 'Alfabet, Angka & Frasa Dasar BISINDO',
    },
    {
      'level': 2,
      'code': 'L2',
      'title': 'Tingkat Menengah (Level 2)',
      'desc': 'BISINDO & Pemahaman Ekspresif',
    },
    {
      'level': 3,
      'code': 'L3',
      'title': 'Tingkat Mahir (Level 3)',
      'desc': 'Percakapan Kompleks & Cerita Isyarat',
    },
  ];

  static const List<String> _daftarMotivasi = [
    'Komunikasi Keluarga',
    'Pekerjaan',
    'Teman Tuli',
    'Advokasi Sosial',
    'Hobi & Edukasi',
  ];

  // Katalog lencana. Status terbuka dihitung dari data profil nyata.
  static const List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'perfect_100',
      'title': 'Perfect 100',
      'desc': 'Akurasi 100% pada 10 sesi evaluasi isyarat berturut-turut',
      'icon': Icons.stars_rounded,
      'color': AppColors.primary,
      'bg': AppColors.pinkSoft,
      'category': 'Evaluasi',
    },
    {
      'id': 'streak_7',
      'title': '7-Day Streak',
      'desc': 'Berlatih isyarat minimal 15 menit setiap hari selama 7 hari',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.secondary,
      'bg': AppColors.purpleSoft,
      'category': 'Konsistensi',
    },
    {
      'id': 'fast_signer',
      'title': 'Fast Signer',
      'desc': 'Kecepatan respon isyarat di bawah 1.2 detik saat kuis',
      'icon': Icons.bolt_rounded,
      'color': AppColors.tertiary,
      'bg': AppColors.orangeSoft,
      'category': 'Kecepatan',
    },
    {
      'id': 'kamus_explorer',
      'title': 'Kamus Explorer',
      'desc': 'Mempelajari dan mempraktikkan lebih dari 50 kosakata kamus',
      'icon': Icons.auto_stories_rounded,
      'color': AppColors.info,
      'bg': AppColors.infoSoft,
      'category': 'Eksplorasi',
    },
    {
      'id': 'komunitas_bintang',
      'title': 'Komunitas Bintang',
      'desc': 'Aktif berkontribusi di 20 diskusi tanya jawab komunitas',
      'icon': Icons.forum_rounded,
      'color': AppColors.success,
      'bg': AppColors.successSoft,
      'category': 'Komunitas',
    },
    {
      'id': 'master_signer',
      'title': 'Master Isyarat L3',
      'desc': 'Menyelesaikan seluruh modul kurikulum tingkat mahir',
      'icon': Icons.workspace_premium_rounded,
      'color': AppColors.secondary,
      'bg': AppColors.purpleSoft,
      'category': 'Kurikulum',
    },
  ];

  ImageProvider<Object>? get _avatarImage {
    if (_avatarPath != null) return FileImage(File(_avatarPath!));
    if (_avatarUrl.isNotEmpty) return NetworkImage(_avatarUrl);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();

    _bioController.addListener(() {
      setState(() {});
    });
    _nameController.addListener(() {
      if (_avatarImage == null) setState(() {});
    });

    _muatProfil();
  }

  /// Mengisi formulir dengan data profil nyata dari Supabase.
  Future<void> _muatProfil() async {
    setState(() => _loading = true);
    final profil = await _profilService.profilSaya(force: true);
    if (!mounted) return;
    setState(() {
      _profil = profil;
      _loading = false;
      if (profil != null) {
        _nameController.text = profil.nama;
        _usernameController.text =
            profil.username.isEmpty ? '' : '@${profil.username}';
        _bioController.text = profil.bio;
        _phoneController.text = profil.phone;
        _avatarUrl = profil.avatarUrl;
        _level = profil.level.clamp(1, 3);
        _selectedMotivations
          ..clear()
          ..addAll(profil.motivation);
        _selectedBadgeIds
          ..clear()
          ..addAll(profil.featuredBadges.take(3));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    final nama = _nameController.text.trim();
    final username = _usernameController.text.trim();
    if (nama.isEmpty) {
      showAppSnackBar(context, 'Nama lengkap wajib diisi.',
          type: AppSnackType.warning);
      return;
    }
    if (username.isEmpty) {
      showAppSnackBar(context, 'Username wajib diisi.',
          type: AppSnackType.warning);
      return;
    }

    setState(() => _saving = true);
    try {
      String? avatarUrl;
      if (_avatarPath != null) {
        avatarUrl = await _profilService.unggahAvatar(_avatarPath!);
      }

      final profil = await _profilService.simpanProfil(
        nama: nama,
        username: username,
        bio: _bioController.text,
        phone: _phoneController.text,
        level: _level,
        motivation: _selectedMotivations.toList(),
        featuredBadges: _selectedBadgeIds,
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _avatarPath = null;
        _avatarUrl = profil?.avatarUrl ?? _avatarUrl;
      });
      showAppSnackBar(
        context,
        'Perubahan profil berhasil disimpan!',
        type: AppSnackType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Memilih foto profil lalu mengompresnya agar file tersimpan kecil
  /// (maksimal 512 px, kualitas 70%).
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (file == null || !mounted) return;
      // Simpan sebagai WebP agar file benar-benar kecil.
      final webpPath = await ImageCompressService.toWebP(
        file.path,
        maxWidth: 512,
        quality: 70,
      );
      if (!mounted) return;
      setState(() => _avatarPath = webpPath);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gagal membuka kamera/galeri.',
        type: AppSnackType.error,
      );
    }
  }

  void _showChangePhotoModal() {
    showAppBottomSheet<void>(
      context,
      title: 'Ubah Foto Profil',
      icon: Icons.photo_camera_outlined,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetOptionTile(
              icon: Icons.photo_camera_rounded,
              iconColor: AppColors.primary,
              iconBackground: AppColors.pinkSoft,
              title: 'Ambil Foto Baru',
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            AppSheetOptionTile(
              icon: Icons.photo_library_rounded,
              iconColor: AppColors.secondary,
              iconBackground: AppColors.purpleSoft,
              title: 'Pilih dari Galeri',
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            AppSheetOptionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.danger,
              iconBackground: AppColors.dangerSoft,
              title: 'Hapus Foto Profil',
              titleColor: AppColors.danger,
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _avatarPath = null;
                  _avatarUrl = '';
                });
                showAppSnackBar(context, 'Foto profil dihapus');
              },
            ),
          ],
        );
      },
    );
  }

  void _showLevelPicker() {
    showAppBottomSheet<void>(
      context,
      title: 'Tingkat Kemahiran Isyarat',
      icon: Icons.school_outlined,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lvl in _daftarLevel)
              AppSheetOptionTile(
                icon: switch (lvl['level']) {
                  1 => Icons.looks_one_rounded,
                  2 => Icons.looks_two_rounded,
                  _ => Icons.looks_3_rounded,
                },
                iconColor: lvl['level'] == _level
                    ? AppColors.primary
                    : AppColors.secondary,
                iconBackground: lvl['level'] == _level
                    ? AppColors.pinkSoft
                    : AppColors.purpleSoft,
                title: lvl['title'] as String,
                subtitle: lvl['desc'] as String,
                isSelected: lvl['level'] == _level,
                onTap: () {
                  setState(() => _level = lvl['level'] as int);
                  Navigator.pop(ctx);
                },
              ),
          ],
        );
      },
    );
  }

  /// Status terbuka lencana diturunkan dari data nyata: streak dan level.
  bool _badgeTerbuka(Map<String, dynamic> badge) {
    final profil = _profil;
    if (profil == null) return false;
    return switch (badge['id']) {
      'streak_7' => profil.streak >= 7,
      'master_signer' => _level >= 3,
      'kamus_explorer' => profil.xp >= 500,
      _ => false,
    };
  }

  int get _jumlahTerbuka => _allBadges.where(_badgeTerbuka).length;

  int get _jumlahTerkunci => _allBadges.length - _jumlahTerbuka;

  int get _jumlahTotalLencana => _allBadges.length;

  /// "4 bulan" sejak `profiles.created_at`.
  String get _lamaBergabung {
    final dibuat = _profil?.dibuat;
    if (dibuat == null) return 'Baru bergabung';
    final hari = DateTime.now().difference(dibuat).inDays;
    if (hari < 30) return 'Bergabung $hari hari lalu';
    final bulan = (hari / 30).floor();
    if (bulan < 12) return 'Bergabung $bulan bulan lalu';
    return 'Bergabung ${(bulan / 12).floor()} tahun lalu';
  }

  /// Role akun dari tabel `profiles.role`.
  String get _roleLabel => _profil?.roleLabel ?? 'Pembelajar';

  /// Inisial nama untuk fallback avatar.
  String get _inisial {
    final nama = _nameController.text.trim();
    final sumber = nama.isNotEmpty ? nama : (_profil?.nama ?? '');
    if (sumber.trim().isEmpty) return '?';
    final kata = sumber.trim().split(RegExp(r'\s+'));
    if (kata.length == 1) {
      return String.fromCharCode(kata.first.runes.first).toUpperCase();
    }
    return '${String.fromCharCode(kata.first.runes.first)}'
            '${String.fromCharCode(kata[1].runes.first)}'
        .toUpperCase();
  }

  void _showRoleDetailDialog() {
    showAppDialog(
      context,
      icon: Icons.explore_rounded,
      iconColor: AppColors.secondary,
      iconBackground: AppColors.purpleSoft,
      title: 'Detail Role: $_roleLabel',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status ${_profil?.nama ?? labelNamaNetral}:',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '• $_lamaBergabung\n'
            '• Total XP: ${ProfilPengguna.formatAngka(_profil?.xp ?? 0)}\n'
            '• Streak: ${_profil?.streak ?? 0} hari\n'
            '• Tingkat kemahiran: Level $_level',
            style: const TextStyle(
                fontSize: 13, height: 1.55, color: AppColors.textSecondary),
          ),
        ],
      ),
      showCancel: false,
      confirmLabel: 'Mengerti',
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
            int filterTabIndex =
                0; // 0: Semua, 1: Sudah Didapat, 2: Belum Terbuka
            String selectedCategory = 'Semua Kategori';

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                // Filter badge list
                List<Map<String, dynamic>> displayedBadges = _allBadges;
                if (filterTabIndex == 1) {
                  displayedBadges = _allBadges.where(_badgeTerbuka).toList();
                } else if (filterTabIndex == 2) {
                  displayedBadges =
                      _allBadges.where((b) => !_badgeTerbuka(b)).toList();
                }

                if (selectedCategory != 'Semua Kategori') {
                  displayedBadges = displayedBadges
                      .where((b) => b['category'] == selectedCategory)
                      .toList();
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: AppColors.border,
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
                                color: AppColors.pinkSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.military_tech_rounded,
                                color: AppColors.primary,
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pilih maksimal 3 lencana untuk disematkan di profil publik',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
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
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.textPrimary),
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.purpleSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_selectedBadgeIds.length} / 3 Terpilih',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Batas maksimum: 3',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'STATUS PENCAPAIAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '$_jumlahTotalLencana Total Lencana',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
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
                                    label: 'Semua ($_jumlahTotalLencana)',
                                    isSelected: filterTabIndex == 0,
                                    onTap: () =>
                                        setModalState(() => filterTabIndex = 0),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildModalTabPill(
                                    label: 'Sudah Didapat ($_jumlahTerbuka)',
                                    isSelected: filterTabIndex == 1,
                                    onTap: () =>
                                        setModalState(() => filterTabIndex = 1),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildModalTabPill(
                                    label: 'Belum Terbuka ($_jumlahTerkunci)',
                                    isSelected: filterTabIndex == 2,
                                    onTap: () =>
                                        setModalState(() => filterTabIndex = 2),
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
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.fieldFill,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_outlined,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedCategory,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 18, color: AppColors.textSecondary),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.purpleSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.secondary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status Role: $_roleLabel',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Lencana terbuka: $_jumlahTerbuka dari $_jumlahTotalLencana',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Level $_level',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: displayedBadges.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final badge = displayedBadges[index];
                            final String id = badge['id'];
                            final bool isSelected =
                                _selectedBadgeIds.contains(id);
                            final bool isUnlocked = _badgeTerbuka(badge);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: isSelected
                                    ? Border.all(
                                        color: badge['color'] as Color,
                                        width: 1.5,
                                      )
                                    : null,
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
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isUnlocked
                                              ? (badge['color'] as Color)
                                              : AppColors.fieldFill,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          badge['icon'] as IconData,
                                          color: isUnlocked
                                              ? AppColors.textOnPrimary
                                              : AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  badge['title'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? (badge['color']
                                                                as Color)
                                                            .withValues(
                                                                alpha: 0.15)
                                                        : AppColors.fieldFill,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (!isSelected &&
                                                          !isUnlocked) ...[
                                                        const Icon(
                                                          Icons
                                                              .lock_outline_rounded,
                                                          size: 12,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                      ],
                                                      Text(
                                                        isSelected
                                                            ? 'Terpilih'
                                                            : (isUnlocked
                                                                ? 'Tersedia untuk Dipilih'
                                                                : 'Belum Terbuka'),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isSelected
                                                              ? (badge['color']
                                                                  as Color)
                                                              : AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              badge['desc'] as String,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: AppColors.border),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isUnlocked
                                                ? Icons.check_circle_rounded
                                                : Icons.lock_outline_rounded,
                                            size: 14,
                                            color: isUnlocked
                                                ? AppColors.success
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isUnlocked
                                                ? 'Sudah Didapat'
                                                : 'Belum Terbuka',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isUnlocked
                                                  ? AppColors.success
                                                  : AppColors.textMuted,
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
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 14),
                                            child: Text(
                                              'Hapus',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isUnlocked)
                                        InkWell(
                                          onTap: () {
                                            if (_selectedBadgeIds.length >= 3) {
                                              showAppSnackBar(
                                                context,
                                                'Batas maksimal 3 lencana terpilih! Hapus salah satu terlebih dahulu.',
                                                type: AppSnackType.warning,
                                                duration:
                                                    const Duration(seconds: 2),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _selectedBadgeIds.add(id);
                                            });
                                            setModalState(() {});
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 14),
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    size: 14,
                                                    color: AppColors.primary),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Pilih Ini',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Terkunci',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
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
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profil'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: (_saving || _loading) ? null : _saveProfile,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 18),
              label: Text(
                _saving ? 'Menyimpan' : 'Simpan',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pinkSoft,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _avatarImage,
                    child: _avatarImage == null
                        ? Text(
                            _inisial,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showChangePhotoModal,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.textOnPrimary,
                        size: 16,
                      ),
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
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, color: AppColors.primary, size: 14),
                SizedBox(width: 6),
                Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
                  color: AppColors.textSecondary,
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

          // Email (read-only, dari akun Supabase)
          _buildFieldLabel('Email'),
          const SizedBox(height: 6),
          _buildReadOnlyField(
            value: _email.isEmpty ? 'Belum tersedia' : _email,
            prefixIcon: Icons.mail_outline_rounded,
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
    final selectedBadgesData =
        _allBadges.where((b) => _selectedBadgeIds.contains(b['id'])).toList();

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
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.military_tech_rounded,
                    color: AppColors.primary, size: 20),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Maksimal 3 lencana disematkan di profil',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedBadgeIds.length} dari 3 dipilih',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Belum ada lencana yang disematkan.\nPilih dari daftar di bawah!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.pinkSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 18),
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '4 Terbuka, 2 Terkunci • Pilih & Ganti lencana',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Dashed Outline: + Kelola Lencana Lainnya
          InkWell(
            onTap: _openAchievementSelectionModal,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Kelola Lencana Lainnya',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
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
                  color: AppColors.textOnPrimary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Terpilih (Maks 3)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
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
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Selesai • Ditampilkan di profil',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedBadgeIds.remove(badge['id']);
                  });
                  showAppSnackBar(
                    context,
                    'Lencana ${badge['title']} dilepas dari profil',
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
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
    final Map<String, dynamic> levelAktif = _daftarLevel.firstWhere(
      (l) => l['level'] == _level,
      orElse: () => _daftarLevel.first,
    );

    return _buildContainerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.back_hand_rounded,
            title: 'Preferensi Isyarat',
            iconColor: AppColors.tertiary,
          ),
          const SizedBox(height: 16),

          // Tingkat Kemahiran Isyarat
          _buildFieldLabel('Tingkat Kemahiran Isyarat'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showLevelPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      levelAktif['code'] as String,
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
                          levelAktif['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          levelAktif['desc'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.secondary),
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
              for (final m in _daftarMotivasi) _buildMotivationChip(m),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationChip(String label) {
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
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
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
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.secondary, size: 20),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Loyalitas & Masa Pakai Sign-L',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _roleLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Highlight Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(20),
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
                            Text(
                              'Status Anda: $_roleLabel',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _lamaBergabung,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Level $_level',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Text(
                          'dari 3 tingkat',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _level / 3,
                    minHeight: 7,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timeline Tingkat Kemahiran (dari kolom `profiles.level`)
          _buildRoleTimelineStep(
            icon: Icons.check_rounded,
            iconBgColor: AppColors.success,
            title: 'Pemula (Level 1)',
            subtitle: 'Alfabet, angka & frasa dasar BISINDO',
            badgeText: _level >= 1 ? 'Tercapai' : 'Belum Terbuka',
            badgeBgColor: AppColors.successSoft,
            badgeTextColor: AppColors.success,
            isDone: _level >= 1,
            hasLine: true,
            lineColor: _level >= 2 ? AppColors.success : AppColors.border,
          ),
          _buildRoleTimelineStep(
            icon: Icons.explore_rounded,
            iconBgColor:
                _level >= 2 ? AppColors.secondary : AppColors.fieldFill,
            iconColor: _level >= 2 ? Colors.white : AppColors.textMuted,
            title: 'Menengah (Level 2)',
            activePill: _level == 2,
            subtitle: 'BISINDO & pemahaman ekspresif',
            badgeText: _level >= 2 ? 'Tercapai' : 'Belum Terbuka',
            badgeIcon: _level >= 2 ? null : Icons.lock_outline_rounded,
            badgeBgColor:
                _level >= 2 ? AppColors.purpleSoft : AppColors.fieldFill,
            badgeTextColor:
                _level >= 2 ? AppColors.secondary : AppColors.textSecondary,
            actionLink: 'Ketuk detail',
            onActionTap: _showRoleDetailDialog,
            isDone: _level >= 2,
            hasLine: true,
            lineColor: _level >= 3 ? AppColors.success : AppColors.border,
          ),
          _buildRoleTimelineStep(
            icon: Icons.lightbulb_outline_rounded,
            iconBgColor:
                _level >= 3 ? AppColors.secondary : AppColors.fieldFill,
            iconColor: _level >= 3 ? Colors.white : AppColors.textMuted,
            title: 'Mahir (Level 3)',
            activePill: _level == 3,
            subtitle: 'Percakapan kompleks & cerita isyarat',
            badgeText: _level >= 3 ? 'Tercapai' : 'Belum Terbuka',
            badgeIcon: _level >= 3 ? null : Icons.lock_outline_rounded,
            badgeBgColor:
                _level >= 3 ? AppColors.purpleSoft : AppColors.fieldFill,
            badgeTextColor:
                _level >= 3 ? AppColors.secondary : AppColors.textSecondary,
            isDone: _level >= 3,
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
    IconData? badgeIcon,
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
                    color: lineColor ?? AppColors.border,
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (activePill) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badgeIcon != null) ...[
                              Icon(badgeIcon, size: 12, color: badgeTextColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (actionLink != null) ...[
                    InkWell(
                      onTap: onActionTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          actionLink,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                            decoration: TextDecoration.underline,
                          ),
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

  // Helper Widgets
  Widget _buildContainerCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    Color iconColor = AppColors.primary,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required IconData prefixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: showCounter
          ? null
          : (context,
                  {required currentLength, required isFocused, maxLength}) =>
              null,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
