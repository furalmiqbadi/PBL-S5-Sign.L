import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../services/admin_service.dart';
import '../../services/image_compress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import 'admin_detail_pages.dart';
import 'admin_tampilan_kuis.dart';

String _pesan(Object e) =>
    e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';

/// Wizard tambah materi: info → bagian satu per satu → preview → simpan.
///
/// Foto dikompres ke WebP lalu diunggah ke bucket `materi-media`. Video
/// dipilih dari galeri (maksimal 2 menit) lalu diunggah apa adanya.
class WizardMateriPage extends StatefulWidget {
  /// Urutan yang disarankan untuk materi baru.
  final int urutanAwal;

  const WizardMateriPage({super.key, this.urutanAwal = 1});

  @override
  State<WizardMateriPage> createState() => _WizardMateriPageState();
}

class _WizardMateriPageState extends State<WizardMateriPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  final _jumlah = TextEditingController(text: '3');

  String? _kameraHuruf;

  String? _gambarUrl;
  String? _gambarLokal;
  bool _unggahGambar = false;

  /// 0 = info materi, 1..n = bagian ke-n, n + 1 = preview.
  int _langkah = 0;
  int _jumlahBagian = 3;
  final List<_BagianIsian> _bagian = [];
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    _jumlah.dispose();
    for (final b in _bagian) {
      b.dispose();
    }
    super.dispose();
  }

  // ---------- Unggah ----------

  Future<void> _pilihGambar() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahGambar = true);
    try {
      final webp = await ImageCompressService.toWebP(hasil.path,
          maxWidth: 1280, quality: 72);
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        _gambarUrl = url;
        _gambarLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahGambar = false);
    }
  }

  Future<void> _pilihFotoBagian(_BagianIsian b) async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => b.unggahFoto = true);
    try {
      final webp = await ImageCompressService.toWebP(hasil.path,
          maxWidth: 1280, quality: 70);
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        b.fotoUrl = url;
        b.fotoLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => b.unggahFoto = false);
    }
  }

  Future<void> _pilihVideoBagian(_BagianIsian b) async {
    final hasil = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (hasil == null) return;
    setState(() => b.unggahVideo = true);
    try {
      final url = await _service.unggahMedia(hasil.path, isVideo: true);
      if (!mounted) return;
      setState(() {
        b.videoUrl = url;
        b.videoLokal = hasil.path;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => b.unggahVideo = false);
    }
  }

  // ---------- Langkah ----------

  void _mulaiBagian() {
    if (_judul.text.trim().isEmpty) {
      toast(context, 'Judul materi wajib diisi.', type: AppSnackType.warning);
      return;
    }
    final jumlah = int.tryParse(_jumlah.text.trim()) ?? 0;
    if (jumlah < 1 || jumlah > 20) {
      toast(context, 'Jumlah bagian harus 1 sampai 20.',
          type: AppSnackType.warning);
      return;
    }
    for (final b in _bagian) {
      b.dispose();
    }
    _bagian
      ..clear()
      ..addAll(List.generate(jumlah, (_) => _BagianIsian()));
    setState(() {
      _jumlahBagian = jumlah;
      _langkah = 1;
    });
  }

  String? _validasiBagian(int index) {
    final b = _bagian[index];
    final adaIsi =
        b.isi.text.trim().isNotEmpty || b.fotoUrl != null || b.videoUrl != null;
    if (!adaIsi) {
      return 'Bagian ${index + 1} butuh teks, foto, atau video.';
    }
    return null;
  }

  void _berikut() {
    final pesan = _validasiBagian(_langkah - 1);
    if (pesan != null) {
      toast(context, pesan, type: AppSnackType.warning);
      return;
    }
    setState(() => _langkah++);
  }

  void _sebelum() {
    if (_langkah > 0) setState(() => _langkah--);
  }

  Future<void> _simpan() async {
    for (var i = 0; i < _bagian.length; i++) {
      final pesan = _validasiBagian(i);
      if (pesan != null) {
        toast(context, pesan, type: AppSnackType.warning);
        setState(() => _langkah = i + 1);
        return;
      }
    }
    setState(() => _menyimpan = true);
    try {
      final judul = _judul.text.trim();
      await _service.buatMateriLengkap(
        judul: judul,
        deskripsi: _deskripsi.text.trim(),
        urutan: widget.urutanAwal,
        gambarUrl: _gambarUrl,
        kameraHuruf: _kameraHuruf,
        bagian: [
          for (var i = 0; i < _bagian.length; i++)
            MateriBagianItem(
              id: '',
              materiId: '',
              urutan: i + 1,
              judul: _bagian[i].judul.text.trim(),
              isi: _bagian[i].isi.text.trim(),
              fotoUrl: _bagian[i].fotoUrl,
              videoUrl: _bagian[i].videoUrl,
              huruf: _bagian[i].huruf,
            ),
        ],
      );
      await _service.catatLog('Menambah materi "$judul" lewat wizard');
      if (!mounted) return;
      toast(context, 'Materi "$judul" tersimpan.', type: AppSnackType.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Tambah Materi', style: AppTextStyles.headlineSmall),
      ),
      body: Column(
        children: [
          _buildProgres(),
          Expanded(
            child: _langkah == 0
                ? _buildInfo()
                : _langkah <= _jumlahBagian
                    ? _buildBagian(_langkah - 1)
                    : _buildPreview(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SingleChildScrollView(child: _buildNavigasi()),
      ),
    );
  }

  Widget _buildProgres() {
    final total = _jumlahBagian + 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: (_langkah / (_jumlahBagian + 1)).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.pinkSoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Langkah ${_langkah + 1} dari $total',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('Info materi', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Isi judul, deskripsi, dan jumlah bagian. Setiap bagian bisa berisi '
          'teks, foto, dan video.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _judul,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Judul materi'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _deskripsi,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Deskripsi singkat'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jumlah,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Jumlah bagian'),
        ),
        const SizedBox(height: 14),
        Text('Kelas kamera materi (opsional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Pilih satu kelas huruf bila seluruh materi berfokus pada huruf itu. '
          'Kosongkan bila materi tidak memakai latihan kamera.',
          style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        pemilihHuruf(
          nilai: _kameraHuruf,
          onChanged: (h) => setState(() => _kameraHuruf = h),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          borderRadius: AppRadii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gambar materi (opsional)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              if (_gambarUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: _previewMedia(
                        lokal: _gambarLokal,
                        url: _gambarUrl!,
                        tinggi: 140,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AppIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Hapus gambar',
                        onPressed: () => setState(() {
                          _gambarUrl = null;
                          _gambarLokal = null;
                        }),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _unggahGambar ? null : _pilihGambar,
                    icon: _unggahGambar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.image_rounded, size: 18),
                    label: Text(_unggahGambar ? 'Mengunggah…' : 'Pilih foto'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBagian(int index) {
    final b = _bagian[index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('Bagian ${index + 1}', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        Text('Kelas huruf bagian ini', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Pilih huruf yang dilatih di bagian ini agar kamera menampilkan isi '
          'bagian saat huruf tersebut terdeteksi.',
          style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        pemilihHuruf(
          nilai: b.huruf,
          onChanged: (h) => setState(() => b.huruf = h),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: b.judul,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Judul bagian'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: b.isi,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              const InputDecoration(hintText: 'Isi materi / penjelasan'),
        ),
        const SizedBox(height: 14),
        Text('Foto bagian (opsional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        if (b.fotoUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: _previewMedia(
                  lokal: b.fotoLokal,
                  url: b.fotoUrl!,
                  tinggi: 150,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Hapus foto',
                  onPressed: () => setState(() {
                    b.fotoUrl = null;
                    b.fotoLokal = null;
                  }),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: b.unggahFoto ? null : () => _pilihFotoBagian(b),
              icon: b.unggahFoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: Text(b.unggahFoto ? 'Mengunggah…' : 'Pilih foto'),
            ),
          ),
        const SizedBox(height: 14),
        Text('Video bagian (opsional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        if (b.videoUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.surfaceMuted,
                  child: b.videoLokal == null
                      ? const Icon(Icons.movie_rounded,
                          color: AppColors.textSecondary, size: 32)
                      : _VideoPratinjau(path: b.videoLokal!),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Hapus video',
                  onPressed: () => setState(() {
                    b.videoUrl = null;
                    b.videoLokal = null;
                  }),
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: b.unggahVideo ? null : () => _pilihVideoBagian(b),
                  icon: b.unggahVideo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.video_library_rounded, size: 18),
                  label: Text(b.unggahVideo ? 'Mengunggah…' : 'Pilih video'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Video maksimal 2 menit, diunggah apa adanya.',
                style: AppTextStyles.labelXSmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
      ],
    );
  }

  Widget _previewMedia({
    required String? lokal,
    required String url,
    required double tinggi,
  }) {
    return gambarPratinjau(lokal: lokal, url: url, tinggi: tinggi);
  }

  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Preview materi', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Periksa semuanya sebelum disimpan.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        kartuInfo(
          gambarUrl: _gambarUrl,
          gambarLokal: _gambarLokal,
          gambarTinggi: 170,
          judul: _judul.text.trim(),
          deskripsi: _deskripsi.text,
          meta: '$_jumlahBagian bagian'
              '${_kameraHuruf == null ? '' : ' • kamera huruf $_kameraHuruf'}',
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _bagian.length; i++)
          kartuBagianPratinjau(
            nomor: i + 1,
            judul: _bagian[i].judul.text,
            isi: _bagian[i].isi.text,
            fotoUrl: _bagian[i].fotoUrl,
            fotoLokal: _bagian[i].fotoLokal,
            videoUrl: _bagian[i].videoUrl,
            videoLokal: _bagian[i].videoLokal,
            huruf: _bagian[i].huruf,
          ),
      ],
    );
  }

  Widget _buildNavigasi() {
    final diPreview = _langkah > _jumlahBagian;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (_langkah > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _menyimpan ? null : _sebelum,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Kembali'),
              ),
            ),
          if (_langkah > 0) const SizedBox(width: 10),
          Expanded(
            flex: _langkah > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _menyimpan
                  ? null
                  : diPreview
                      ? _simpan
                      : (_langkah == 0 ? _mulaiBagian : _berikut),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
              child: _menyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Text(diPreview
                      ? 'Simpan Materi'
                      : (_langkah == 0 ? 'Mulai Isi Bagian' : 'Lanjut')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isian satu bagian materi di wizard.
class _BagianIsian {
  final TextEditingController judul = TextEditingController();
  final TextEditingController isi = TextEditingController();
  String? huruf;
  String? fotoUrl;
  String? fotoLokal;
  String? videoUrl;
  String? videoLokal;
  bool unggahFoto = false;
  bool unggahVideo = false;

  void dispose() {
    judul.dispose();
    isi.dispose();
  }
}

/// Halaman edit materi: info, gambar induk, dan daftar bagian.
///
/// Setiap bagian dibuka di halaman tersendiri ([EditBagianMateriPage]).
class EditMateriAdminPage extends StatefulWidget {
  final MateriAdminItem materi;

  const EditMateriAdminPage({super.key, required this.materi});

  @override
  State<EditMateriAdminPage> createState() => _EditMateriAdminPageState();
}

class _EditMateriAdminPageState extends State<EditMateriAdminPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();

  String? _kameraHuruf;

  String? _gambarUrl;
  String? _gambarLokal;
  bool _unggahGambar = false;

  List<MateriBagianItem> _bagian = const [];
  bool _loading = true;
  String? _error;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _judul.text = widget.materi.judul;
    _deskripsi.text = widget.materi.deskripsi;
    _kameraHuruf = widget.materi.kameraHuruf;
    _gambarUrl = widget.materi.gambarUrl;
    _muat();
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bagian = await _service.fetchBagianMateri(widget.materi.id);
      if (!mounted) return;
      setState(() => _bagian = bagian);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pilihGambar() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahGambar = true);
    try {
      final webp = await ImageCompressService.toWebP(
        hasil.path,
        maxWidth: 1280,
        quality: 72,
      );
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        _gambarUrl = url;
        _gambarLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahGambar = false);
    }
  }

  Future<void> _simpanInfo() async {
    final judul = _judul.text.trim();
    if (judul.isEmpty) {
      toast(context, 'Judul materi wajib diisi.', type: AppSnackType.warning);
      return;
    }
    setState(() => _menyimpan = true);
    try {
      await _service.simpanMateri(
        id: widget.materi.id,
        judul: judul,
        deskripsi: _deskripsi.text.trim(),
        urutan: widget.materi.urutan,
        gambarUrl: _gambarUrl,
        videoUrl: widget.materi.videoUrl,
        kameraHuruf: _kameraHuruf,
      );
      await _service.catatLog('Mengedit materi "$judul"');
      if (!mounted) return;
      toast(context, 'Perubahan materi disimpan.', type: AppSnackType.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _bukaPratinjau() {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _PratinjauMateriPage(
          judul: _judul.text.trim().isEmpty
              ? widget.materi.judul
              : _judul.text.trim(),
          deskripsi: _deskripsi.text.trim(),
          gambarUrl: _gambarUrl,
          gambarLokal: _gambarLokal,
          bagian: _bagian,
        ),
      ),
    );
  }

  Future<void> _bukaBagian(MateriBagianItem? bagian, int nomor) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditBagianMateriPage(
          materiId: widget.materi.id,
          bagian: bagian,
          nomorAwal: nomor,
        ),
      ),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _hapusBagian(MateriBagianItem bagian, int nomor) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus bagian $nomor?',
      message: 'Bagian akan hilang dari materi ini.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusBagianMateri(bagian.id);
      await _service.catatLog(
        'Menghapus bagian ${bagian.urutan > 0 ? bagian.urutan : nomor} '
        'materi "${widget.materi.judul}"',
      );
      if (!mounted) return;
      toast(context, 'Bagian dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Edit Materi', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            onPressed: _loading ? null : _bukaPratinjau,
            tooltip: 'Pratinjau',
            icon: const Icon(Icons.visibility_rounded),
          ),
          TextButton(
            onPressed: _loading || _menyimpan ? null : _simpanInfo,
            child: _menyimpan
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Bagian',
        onPressed: () => _bukaBagian(null, _bagian.length + 1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewPaddingOf(context).bottom + 96,
              ),
              children: [
                Text('Info materi', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _judul,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Judul materi'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deskripsi,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(hintText: 'Deskripsi singkat'),
                ),
                const SizedBox(height: 10),
                Text('Kelas kamera materi (opsional)',
                    style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                pemilihHuruf(
                  nilai: _kameraHuruf,
                  onChanged: (h) => setState(() => _kameraHuruf = h),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: AppRadii.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gambar materi (opsional)',
                          style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      if (_gambarUrl != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: gambarPratinjau(
                                lokal: _gambarLokal,
                                url: _gambarUrl!,
                                tinggi: 140,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: AppIconButton(
                                icon: Icons.close_rounded,
                                tooltip: 'Hapus gambar',
                                onPressed: () => setState(() {
                                  _gambarUrl = null;
                                  _gambarLokal = null;
                                }),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _unggahGambar ? null : _pilihGambar,
                            icon: _unggahGambar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image_rounded, size: 18),
                            label: Text(
                              _unggahGambar ? 'Mengunggah…' : 'Pilih foto',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Bagian materi',
                          style: AppTextStyles.titleMedium),
                    ),
                    Text(
                      '${_bagian.length} bagian',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk bagian untuk mengubah atau menghapus isinya.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                if (_bagian.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Belum ada bagian. Tambahkan lewat tombol di bawah.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  for (var i = 0; i < _bagian.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () => showModalBottomSheet<String>(
                        context: context,
                        backgroundColor: AppColors.background,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadii.lg),
                          ),
                        ),
                        builder: (sheetContext) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'Bagian ${i + 1}',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.edit_rounded,
                                    color: AppColors.primary),
                                title: const Text('Edit bagian'),
                                onTap: () =>
                                    Navigator.pop(sheetContext, 'edit'),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                ),
                                title: const Text('Hapus bagian'),
                                onTap: () =>
                                    Navigator.pop(sheetContext, 'hapus'),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ).then((aksi) {
                        if (aksi == 'edit') _bukaBagian(_bagian[i], i + 1);
                        if (aksi == 'hapus') _hapusBagian(_bagian[i], i + 1);
                      }),
                      child: kartuBagianPratinjau(
                        nomor: i + 1,
                        judul: _bagian[i].judul,
                        isi: _bagian[i].isi,
                        fotoUrl: _bagian[i].fotoUrl,
                        videoUrl: _bagian[i].videoUrl,
                        huruf: _bagian[i].huruf,
                      ),
                    ),
              ],
            ),
    );
  }
}

/// Halaman tambah/edit satu bagian materi: judul, isi, foto, dan video.
class EditBagianMateriPage extends StatefulWidget {
  final String materiId;

  /// `null` berarti bagian baru.
  final MateriBagianItem? bagian;

  /// Urutan untuk bagian baru.
  final int nomorAwal;

  const EditBagianMateriPage({
    super.key,
    required this.materiId,
    required this.nomorAwal,
    this.bagian,
  });

  @override
  State<EditBagianMateriPage> createState() => _EditBagianMateriPageState();
}

class _EditBagianMateriPageState extends State<EditBagianMateriPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _judul = TextEditingController();
  final _isi = TextEditingController();

  String? _huruf;
  String? _fotoUrl;
  String? _fotoLokal;
  String? _videoUrl;
  String? _videoLokal;
  bool _unggahFoto = false;
  bool _unggahVideo = false;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final bagian = widget.bagian;
    if (bagian != null) {
      _judul.text = bagian.judul;
      _isi.text = bagian.isi;
      _huruf = bagian.huruf;
      _fotoUrl = bagian.fotoUrl;
      _videoUrl = bagian.videoUrl;
    }
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahFoto = true);
    try {
      final webp = await ImageCompressService.toWebP(
        hasil.path,
        maxWidth: 1280,
        quality: 70,
      );
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        _fotoUrl = url;
        _fotoLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahFoto = false);
    }
  }

  Future<void> _pilihVideo() async {
    final hasil = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (hasil == null) return;
    setState(() => _unggahVideo = true);
    try {
      final url = await _service.unggahMedia(hasil.path, isVideo: true);
      if (!mounted) return;
      setState(() {
        _videoUrl = url;
        _videoLokal = hasil.path;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahVideo = false);
    }
  }

  Future<void> _simpan() async {
    final isi = _isi.text.trim();
    if (isi.isEmpty && _fotoUrl == null && _videoUrl == null) {
      toast(context, 'Isi bagian butuh teks, foto, atau video.',
          type: AppSnackType.warning);
      return;
    }
    setState(() => _menyimpan = true);
    try {
      await _service.simpanBagianMateri(
        id: widget.bagian?.id,
        materiId: widget.materiId,
        urutan: widget.bagian?.urutan ?? widget.nomorAwal,
        judul: _judul.text.trim(),
        isi: isi,
        fotoUrl: _fotoUrl,
        videoUrl: _videoUrl,
        huruf: _huruf,
      );
      if (!mounted) return;
      toast(
        context,
        widget.bagian == null ? 'Bagian ditambahkan.' : 'Bagian diperbarui.',
        type: AppSnackType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          widget.bagian == null ? 'Tambah Bagian' : 'Edit Bagian',
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Kelas huruf bagian ini', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          pemilihHuruf(
            nilai: _huruf,
            onChanged: (h) => setState(() => _huruf = h),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _judul,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Judul bagian'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _isi,
            maxLines: 6,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(hintText: 'Isi materi / penjelasan'),
          ),
          const SizedBox(height: 16),
          Text('Foto bagian (opsional)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          if (_fotoUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: gambarPratinjau(
                    lokal: _fotoLokal,
                    url: _fotoUrl!,
                    tinggi: 150,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Hapus foto',
                    onPressed: () => setState(() {
                      _fotoUrl = null;
                      _fotoLokal = null;
                    }),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _unggahFoto ? null : _pilihFoto,
                icon: _unggahFoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(_unggahFoto ? 'Mengunggah…' : 'Pilih foto'),
              ),
            ),
          const SizedBox(height: 16),
          Text('Video bagian (opsional)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          if (_videoUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: AppColors.surfaceMuted,
                    child: _videoLokal == null
                        ? const Icon(
                            Icons.movie_rounded,
                            color: AppColors.textSecondary,
                            size: 32,
                          )
                        : _VideoPratinjau(path: _videoLokal!),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Hapus video',
                    onPressed: () => setState(() {
                      _videoUrl = null;
                      _videoLokal = null;
                    }),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _unggahVideo ? null : _pilihVideo,
                    icon: _unggahVideo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.video_library_rounded, size: 18),
                    label: Text(_unggahVideo ? 'Mengunggah…' : 'Pilih video'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Video maksimal 2 menit, diunggah apa adanya.',
                  style: AppTextStyles.labelXSmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _menyimpan ? null : _simpan,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: _menyimpan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Text('Simpan Bagian'),
          ),
        ),
      ),
    );
  }
}

/// Halaman pratinjau materi yang sudah tersimpan (dibuka dari halaman edit).
class _PratinjauMateriPage extends StatelessWidget {
  final String judul;
  final String deskripsi;
  final String? gambarUrl;
  final String? gambarLokal;
  final List<MateriBagianItem> bagian;

  const _PratinjauMateriPage({
    required this.judul,
    required this.deskripsi,
    required this.gambarUrl,
    required this.gambarLokal,
    required this.bagian,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Pratinjau Materi', style: AppTextStyles.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          kartuInfo(
            gambarUrl: gambarUrl,
            gambarLokal: gambarLokal,
            gambarTinggi: 160,
            judul: judul,
            deskripsi: deskripsi.isEmpty ? null : deskripsi,
            meta: '${bagian.length} bagian',
          ),
          const SizedBox(height: 16),
          if (bagian.isEmpty)
            Text(
              'Belum ada bagian pada materi ini.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < bagian.length; i++)
              kartuBagianPratinjau(
                nomor: i + 1,
                judul: bagian[i].judul,
                isi: bagian[i].isi,
                fotoUrl: bagian[i].fotoUrl,
                videoUrl: bagian[i].videoUrl,
              ),
        ],
      ),
    );
  }
}

/// Pratinjau video lokal yang dipilih dari galeri.
class _VideoPratinjau extends StatefulWidget {
  final String path;

  const _VideoPratinjau({required this.path});

  @override
  State<_VideoPratinjau> createState() => _VideoPratinjauState();
}

class _VideoPratinjauState extends State<_VideoPratinjau> {
  VideoPlayerController? _video;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _siapkan();
  }

  Future<void> _siapkan() async {
    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _gagal = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (_gagal) {
      return const Center(
        child: Icon(Icons.movie_rounded, color: AppColors.textSecondary),
      );
    }
    if (video == null) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() {
        video.value.isPlaying ? video.pause() : video.play();
      }),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            ),
          ),
          if (!video.value.isPlaying)
            const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 40),
        ],
      ),
    );
  }
}
