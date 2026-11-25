import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_compress_service.dart';
import '../../services/profil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/auth_widgets.dart';
import 'auth_views.dart';

/// Langkah kedua pendaftaran: melengkapi foto profil dan nama tampilan.
///
/// Dibuka otomatis setelah akun berhasil dibuat. Bila pengguna melewati
/// langkah ini, akun tetap selesai dan langsung masuk ke beranda.
class RegisterProfilePage extends StatefulWidget {
  /// Username yang baru didaftarkan (dipakai sebagai saran nama awal).
  final String username;

  const RegisterProfilePage({super.key, required this.username});

  @override
  State<RegisterProfilePage> createState() => _RegisterProfilePageState();
}

class _RegisterProfilePageState extends State<RegisterProfilePage> {
  final ProfilService _profilService = ProfilService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nama = TextEditingController();

  String? _avatarPath;
  bool _simpan = false;
  bool _lewati = false;

  @override
  void initState() {
    super.initState();
    _nama.text = widget.username;
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  ImageProvider<Object>? get _avatarImage =>
      _avatarPath == null ? null : FileImage(File(_avatarPath!));

  String get _inisial {
    final nama = _nama.text.trim();
    if (nama.isEmpty) return '?';
    final kata = nama.split(RegExp(r'\s+'));
    if (kata.length == 1) {
      return String.fromCharCode(kata.first.runes.first).toUpperCase();
    }
    return '${String.fromCharCode(kata.first.runes.first)}'
            '${String.fromCharCode(kata[1].runes.first)}'
        .toUpperCase();
  }

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (file == null || !mounted) return;
      final webp = await ImageCompressService.toWebP(
        file.path,
        maxWidth: 512,
        quality: 70,
      );
      if (!mounted) return;
      setState(() => _avatarPath = webp);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gagal membuka kamera atau galeri.',
        type: AppSnackType.error,
      );
    }
  }

  void _pilihSumberFoto() {
    showAppBottomSheet<void>(
      context,
      title: 'Pilih Foto Profil',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetOptionTile(
            icon: Icons.photo_camera_rounded,
            iconColor: AppColors.primary,
            iconBackground: AppColors.pinkSoft,
            title: 'Ambil Foto',
            onTap: () {
              Navigator.pop(ctx);
              _pilihFoto(ImageSource.camera);
            },
          ),
          AppSheetOptionTile(
            icon: Icons.photo_library_rounded,
            iconColor: AppColors.secondary,
            iconBackground: AppColors.purpleSoft,
            title: 'Pilih dari Galeri',
            onTap: () {
              Navigator.pop(ctx);
              _pilihFoto(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selesaikan() async {
    if (_simpan || _lewati) return;

    final nama = _nama.text.trim();
    if (nama.length < 3) {
      showAppSnackBar(
        context,
        'Nama tampilan minimal 3 karakter.',
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _simpan = true);
    try {
      String? avatarUrl;
      if (_avatarPath != null) {
        avatarUrl = await _profilService.unggahAvatar(_avatarPath!);
      }
      await _profilService.simpanProfil(
        nama: nama,
        username: widget.username,
        bio: '',
        phone: '',
        level: 1,
        motivation: const [],
        featuredBadges: const [],
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      await openSesuaiRole(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _simpan = false);
      showAppSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _lewatkan() async {
    if (_simpan || _lewati) return;
    setState(() => _lewati = true);
    await openSesuaiRole(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      back: false,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Lengkapi Profilmu',
            subtitle:
                'Tambahkan foto dan nama agar teman komunitas mudah mengenalmu. Bisa diubah kapan saja.',
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pinkSoft,
                    boxShadow: AppShadows.card,
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
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pilihSumberFoto,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AuthField(
            label: 'Nama Tampilan',
            hint: 'Nama yang dilihat pengguna lain',
            icon: Icons.person_outline_rounded,
            controller: _nama,
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            text: _simpan ? 'Menyimpan...' : 'Simpan & Mulai',
            onTap: _simpan || _lewati ? null : _selesaikan,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _simpan || _lewati ? null : _lewatkan,
            child: Text(
              _lewati ? 'Melanjutkan...' : 'Lewati untuk sekarang',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
