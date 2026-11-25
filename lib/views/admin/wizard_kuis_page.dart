import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/admin_service.dart';
import '../../services/image_compress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import 'admin_detail_pages.dart';
import 'admin_tampilan_kuis.dart';

String _pesan(Object e) =>
    e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';

/// Wizard tambah kuis: info → soal satu per satu → preview → simpan.
class WizardKuisPage extends StatefulWidget {
  final List<MateriAdminItem> materi;

  const WizardKuisPage({super.key, required this.materi});

  @override
  State<WizardKuisPage> createState() => _WizardKuisPageState();
}

class _WizardKuisPageState extends State<WizardKuisPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _judul = TextEditingController();
  final _xp = TextEditingController(text: '15');
  final _jumlah = TextEditingController(text: '5');

  late String _materiId = widget.materi.first.id;
  String? _bannerUrl;
  String? _bannerLokal;
  bool _unggahBanner = false;

  /// Langkah 0 = info kuis, 1..n = soal ke-n, n + 1 = preview.
  int _langkah = 0;
  int _jumlahSoal = 5;
  final List<_SoalIsian> _soal = [];
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    _xp.dispose();
    _jumlah.dispose();
    for (final s in _soal) {
      s.dispose();
    }
    super.dispose();
  }

  // ---------- Banner ----------

  Future<void> _pilihBanner() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahBanner = true);
    try {
      final webp = await ImageCompressService.toWebP(hasil.path,
          maxWidth: 1280, quality: 72);
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        _bannerUrl = url;
        _bannerLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahBanner = false);
    }
  }

  // ---------- Langkah ----------

  void _mulaiSoal() {
    final judul = _judul.text.trim();
    if (judul.isEmpty) {
      toast(context, 'Nama kuis wajib diisi.', type: AppSnackType.warning);
      return;
    }
    final jumlah = int.tryParse(_jumlah.text.trim()) ?? 0;
    if (jumlah < 1 || jumlah > maksSoalPerKuis) {
      toast(context, 'Jumlah soal harus 1 sampai $maksSoalPerKuis.',
          type: AppSnackType.warning);
      return;
    }
    for (final s in _soal) {
      s.dispose();
    }
    _soal
      ..clear()
      ..addAll(List.generate(jumlah, (_) => _SoalIsian()));
    setState(() {
      _jumlahSoal = jumlah;
      _langkah = 1;
    });
  }

  /// Memvalidasi soal aktif; mengembalikan pesan kesalahan atau null.
  String? _validasiSoal(int index) {
    final s = _soal[index];
    if (s.pertanyaan.text.trim().isEmpty && s.gambarUrl == null) {
      return 'Pertanyaan soal ${index + 1} wajib diisi.';
    }
    for (var i = 0; i < 4; i++) {
      if (s.opsi[i].text.trim().isEmpty) {
        return 'Pilihan ${String.fromCharCode(65 + i)} soal ${index + 1} '
            'masih kosong.';
      }
    }
    return null;
  }

  void _berikut() {
    final pesan = _validasiSoal(_langkah - 1);
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
    for (var i = 0; i < _soal.length; i++) {
      final pesan = _validasiSoal(i);
      if (pesan != null) {
        toast(context, pesan, type: AppSnackType.warning);
        setState(() => _langkah = i + 1);
        return;
      }
    }
    setState(() => _menyimpan = true);
    try {
      final judul = _judul.text.trim();
      await _service.buatKuisLengkap(
        materiId: _materiId,
        judul: judul,
        xpReward: int.tryParse(_xp.text.trim()) ?? 15,
        bannerUrl: _bannerUrl,
        soal: [
          for (final s in _soal)
            SoalDraft(
              pertanyaan: s.pertanyaan.text.trim(),
              opsi: [for (final o in s.opsi) o.text.trim()],
              jawabanBenar: String.fromCharCode(65 + s.jawaban),
              gambarPertanyaan: s.gambarUrl,
              penjelasan: s.penjelasan.text.trim(),
            ),
        ],
      );
      await _service.catatLog('Menambah kuis "$judul" lewat wizard');
      if (!mounted) return;
      toast(context, 'Kuis "$judul" tersimpan.', type: AppSnackType.success);
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
    final total = _jumlahSoal + 1;
    final prosess = _langkah <= _jumlahSoal
        ? 'Soal ${_langkah + 1} dari $_jumlahSoal'
        : 'Preview';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Tambah Kuis', style: AppTextStyles.headlineSmall),
      ),
      body: Column(
        children: [
          _buildProgres(),
          Expanded(
            child: _langkah == 0
                ? _buildInfo()
                : _langkah <= _jumlahSoal
                    ? _buildSoal(_langkah - 1)
                    : _buildPreview(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: _buildNavigasi(prosess, total),
        ),
      ),
    );
  }

  Widget _buildProgres() {
    final total = _jumlahSoal + 2;
    final nilai = _langkah / (_jumlahSoal + 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: nilai.clamp(0.0, 1.0),
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
        Text('Info kuis', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Isi nama kuis, materi induk, reward XP, dan jumlah soal. '
          'Banner opsional.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _judul,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nama kuis'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _materiId,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Materi'),
          items: widget.materi
              .map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.judul, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _materiId = v);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _xp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'XP reward'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _jumlah,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Jumlah soal (maks 20)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBanner(),
      ],
    );
  }

  Widget _buildBanner() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      borderRadius: AppRadii.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Banner kuis (opsional)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          if (_bannerUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: gambarPratinjau(
                    lokal: _bannerLokal,
                    url: _bannerUrl!,
                    tinggi: 140,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Hapus banner',
                    onPressed: () => setState(() {
                      _bannerUrl = null;
                      _bannerLokal = null;
                    }),
                  ),
                ),
              ],
            ),
          if (_bannerUrl == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _unggahBanner ? null : _pilihBanner,
                icon: _unggahBanner
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_rounded, size: 18),
                label: Text(
                  _unggahBanner ? 'Mengunggah…' : 'Pilih foto banner',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoal(int index) {
    final s = _soal[index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('Soal ${index + 1}', style: AppTextStyles.titleMedium),
        const SizedBox(height: 10),
        TextField(
          controller: s.pertanyaan,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Pertanyaan'),
        ),
        const SizedBox(height: 10),
        _FotoSoal(
          url: s.gambarUrl,
          pathLokal: s.pathLokal,
          sedangUnggah: s.unggahGambar,
          onPilih: () => _pilihFotoSoal(s),
          onHapus: () => setState(() {
            s.gambarUrl = null;
            s.pathLokal = null;
          }),
        ),
        const SizedBox(height: 16),
        Text('Pilihan jawaban', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _kotakHuruf(String.fromCharCode(65 + i), s.jawaban == i),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: s.opsi[i],
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Pilihan ${String.fromCharCode(65 + i)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text('Jawaban benar', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              AppChoiceChip(
                label: String.fromCharCode(65 + i),
                isSelected: s.jawaban == i,
                onTap: () => setState(() => s.jawaban = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: s.penjelasan,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Penjelasan (opsional)'),
        ),
      ],
    );
  }

  Future<void> _pilihFotoSoal(_SoalIsian s) async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => s.unggahGambar = true);
    try {
      final webp = await ImageCompressService.toWebP(hasil.path, quality: 70);
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        s.gambarUrl = url;
        s.pathLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => s.unggahGambar = false);
    }
  }

  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Preview kuis', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Periksa semuanya sebelum disimpan.',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        kartuInfo(
          gambarUrl: _bannerUrl,
          gambarLokal: _bannerLokal,
          gambarTinggi: 150,
          judul: _judul.text.trim(),
          meta:
              '${widget.materi.where((m) => m.id == _materiId).map((m) => m.judul).firstOrNull ?? '-'}'
              ' • $_jumlahSoal soal • +${int.tryParse(_xp.text.trim()) ?? 15} XP',
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _soal.length; i++)
          kartuSoalPratinjau(
            nomor: i + 1,
            pertanyaan: _soal[i].pertanyaan.text,
            opsi: [for (final o in _soal[i].opsi) o.text],
            jawaban: _soal[i].jawaban,
            gambarUrl: _soal[i].gambarUrl,
            gambarLokal: _soal[i].pathLokal,
            penjelasan: _soal[i].penjelasan.text,
          ),
      ],
    );
  }

  Widget _kotakHuruf(String huruf, bool benar) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: benar ? AppColors.successSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        huruf,
        style: AppTextStyles.labelLarge.copyWith(
          color: benar ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNavigasi(String info, int total) {
    final diPreview = _langkah > _jumlahSoal;
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
                      : (_langkah == 0 ? _mulaiSoal : _berikut),
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
                      ? 'Simpan Kuis'
                      : (_langkah == 0 ? 'Mulai Isi Soal' : 'Lanjut')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isian satu soal di wizard.
class _SoalIsian {
  final TextEditingController pertanyaan = TextEditingController();
  final List<TextEditingController> opsi =
      List.generate(4, (_) => TextEditingController());
  final TextEditingController penjelasan = TextEditingController();
  int jawaban = 0;
  String? gambarUrl;
  String? pathLokal;
  bool unggahGambar = false;

  void dispose() {
    pertanyaan.dispose();
    for (final o in opsi) {
      o.dispose();
    }
    penjelasan.dispose();
  }
}

/// Tombol foto pertanyaan pada satu soal.
class _FotoSoal extends StatelessWidget {
  final String? url;
  final String? pathLokal;
  final bool sedangUnggah;
  final VoidCallback onPilih;
  final VoidCallback onHapus;

  const _FotoSoal({
    required this.url,
    required this.pathLokal,
    required this.sedangUnggah,
    required this.onPilih,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: pathLokal != null
                ? Image.file(
                    File(pathLokal!),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    url!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: AppIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Hapus foto',
              onPressed: onHapus,
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: sedangUnggah ? null : onPilih,
        icon: sedangUnggah
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_rounded, size: 18),
        label: Text(sedangUnggah ? 'Mengunggah…' : 'Tambah foto soal'),
      ),
    );
  }
}

/// Bottom sheet berisi tombol aksi satu soal pada halaman edit.
Future<void> _sheetAksiSoal(
  BuildContext context, {
  required int nomor,
  required VoidCallback onEdit,
  required VoidCallback onHapus,
}) async {
  final aksi = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text('Soal $nomor', style: AppTextStyles.titleMedium),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
            title: const Text('Edit soal'),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            title: const Text('Hapus soal'),
            onTap: () => Navigator.pop(sheetContext, 'hapus'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (aksi == 'edit') onEdit();
  if (aksi == 'hapus') onHapus();
}

/// Halaman edit satu kuis: info, banner, dan seluruh soal (tambah/edit/hapus).
///
/// Setiap soal dibuka di halaman tersendiri ([EditSoalKuisPage]) agar isian
/// lega dan tidak tertutup navigasi.
class EditKuisAdminPage extends StatefulWidget {
  final KuisAdminItem kuis;

  const EditKuisAdminPage({super.key, required this.kuis});

  @override
  State<EditKuisAdminPage> createState() => _EditKuisAdminPageState();
}

class _EditKuisAdminPageState extends State<EditKuisAdminPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _judul = TextEditingController();
  final _xp = TextEditingController();

  List<MateriAdminItem> _materi = const [];
  late String _materiId = widget.kuis.materiId;
  String? _bannerUrl;
  String? _bannerLokal;
  bool _unggahBanner = false;

  List<SoalAdminItem> _soal = const [];
  bool _loading = true;
  String? _error;
  bool _menyimpan = false;

  bool get _penuh => _soal.length >= maksSoalPerKuis;

  @override
  void initState() {
    super.initState();
    _judul.text = widget.kuis.judul;
    _xp.text = '${widget.kuis.xpReward}';
    _bannerUrl = widget.kuis.bannerUrl;
    _muat();
  }

  @override
  void dispose() {
    _judul.dispose();
    _xp.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final materiFuture = _service.fetchMateriAdmin();
      final soalFuture = _service.fetchSoalAdmin(widget.kuis.id);
      final materi = await materiFuture;
      final soal = await soalFuture;
      if (!mounted) return;
      setState(() {
        _materi = materi;
        _soal = soal;
        if (_materiId.isEmpty ||
            (materi.isNotEmpty && !materi.any((m) => m.id == _materiId))) {
          _materiId = materi.isEmpty ? '' : materi.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pilihBanner() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahBanner = true);
    try {
      final webp = await ImageCompressService.toWebP(
        hasil.path,
        maxWidth: 1280,
        quality: 72,
      );
      final url = await _service.unggahMedia(webp);
      if (!mounted) return;
      setState(() {
        _bannerUrl = url;
        _bannerLokal = webp;
      });
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _unggahBanner = false);
    }
  }

  Future<void> _simpanInfo() async {
    final judul = _judul.text.trim();
    if (judul.isEmpty) {
      toast(context, 'Nama kuis wajib diisi.', type: AppSnackType.warning);
      return;
    }
    if (_materiId.isEmpty) {
      toast(context, 'Materi induk wajib dipilih.', type: AppSnackType.warning);
      return;
    }
    setState(() => _menyimpan = true);
    try {
      await _service.simpanKuis(
        id: widget.kuis.id,
        materiId: _materiId,
        judul: judul,
        xpReward: int.tryParse(_xp.text.trim()) ?? widget.kuis.xpReward,
        bannerUrl: _bannerUrl,
      );
      await _service.catatLog('Mengedit kuis "$judul"');
      if (!mounted) return;
      toast(context, 'Perubahan kuis disimpan.', type: AppSnackType.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _bukaPratinjau() {
    final materi = _materi.where((m) => m.id == _materiId);
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _PratinjauKuisPage(
          judul: _judul.text.trim().isEmpty
              ? widget.kuis.judul
              : _judul.text.trim(),
          materiNama: materi.isEmpty ? '-' : materi.first.judul,
          xp: int.tryParse(_xp.text.trim()) ?? widget.kuis.xpReward,
          bannerUrl: _bannerUrl,
          bannerLokal: _bannerLokal,
          soal: _soal,
        ),
      ),
    );
  }

  Future<void> _bukaSoal(SoalAdminItem? soal, int nomor) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSoalKuisPage(
          kuisId: widget.kuis.id,
          judulKuis: _judul.text.trim().isEmpty
              ? widget.kuis.judul
              : _judul.text.trim(),
          soal: soal,
          nomorAwal: nomor,
        ),
      ),
    );
    if (berubah == true && mounted) _muat();
  }

  Future<void> _hapus(SoalAdminItem item, int nomor) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus soal $nomor?',
      message: 'Soal akan hilang dari kuis ini.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusSoal(item.id);
      await _service.catatLog('Menghapus soal "${widget.kuis.judul}"');
      if (!mounted) return;
      toast(context, 'Soal dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _aksiSoal(SoalAdminItem item, int nomor) => _sheetAksiSoal(
        context,
        nomor: nomor,
        onEdit: () => _bukaSoal(item, nomor),
        onHapus: () => _hapus(item, nomor),
      );

  void _tambahSoal() {
    if (_penuh) {
      toast(
        context,
        'Batas $maksSoalPerKuis soal sudah tercapai. Hapus soal lain dulu.',
        type: AppSnackType.warning,
      );
      return;
    }
    _bukaSoal(null, _soal.length + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Edit Kuis', style: AppTextStyles.headlineSmall),
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
        label: _penuh ? 'Batas $maksSoalPerKuis soal' : 'Soal',
        icon: _penuh ? Icons.block_rounded : Icons.add_rounded,
        muted: _penuh,
        onPressed: _tambahSoal,
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
                Text('Info kuis', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _judul,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Nama kuis'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _materiId.isEmpty ? null : _materiId,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Materi'),
                  items: _materi
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child:
                                Text(m.judul, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _materiId = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _xp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'XP reward'),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: AppRadii.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Banner kuis (opsional)',
                          style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      if (_bannerUrl != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: gambarPratinjau(
                                lokal: _bannerLokal,
                                url: _bannerUrl!,
                                tinggi: 140,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: AppIconButton(
                                icon: Icons.close_rounded,
                                tooltip: 'Hapus banner',
                                onPressed: () => setState(() {
                                  _bannerUrl = null;
                                  _bannerLokal = null;
                                }),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _unggahBanner ? null : _pilihBanner,
                            icon: _unggahBanner
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image_rounded, size: 18),
                            label: Text(
                              _unggahBanner
                                  ? 'Mengunggah…'
                                  : 'Pilih foto banner',
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
                      child:
                          Text('Soal kuis', style: AppTextStyles.titleMedium),
                    ),
                    Text(
                      '${_soal.length}/$maksSoalPerKuis',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk soal untuk mengubah atau menghapus isinya.',
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
                if (_soal.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Belum ada soal. Tambahkan lewat tombol di bawah.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  for (var i = 0; i < _soal.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () => _aksiSoal(_soal[i], i + 1),
                      child: kartuSoalPratinjau(
                        nomor: i + 1,
                        pertanyaan: _soal[i].pertanyaan,
                        opsi: _opsi4(_soal[i].opsi),
                        jawaban: _indeksJawaban(_soal[i].jawabanBenar),
                        gambarUrl: _soal[i].gambarPertanyaan,
                        penjelasan: _soal[i].penjelasan,
                      ),
                    ),
              ],
            ),
    );
  }
}

List<String> _opsi4(List<String> opsi) {
  final hasil = List<String>.from(opsi);
  while (hasil.length < 4) {
    hasil.add('');
  }
  return hasil.sublist(0, 4);
}

/// Ubah kunci jawaban 'A'..'D' menjadi indeks 0..3.
int _indeksJawaban(String huruf) {
  final indeks = huruf.trim().toUpperCase().codeUnitAt(0) - 65;
  return (indeks < 0 || indeks > 3) ? 0 : indeks;
}

/// Halaman tambah/edit satu soal kuis (dipakai dari halaman edit kuis).
class EditSoalKuisPage extends StatefulWidget {
  final String kuisId;
  final String judulKuis;

  /// `null` berarti soal baru.
  final SoalAdminItem? soal;

  /// Nomor soal saat ini, dipakai sebagai urutan soal baru.
  final int nomorAwal;

  const EditSoalKuisPage({
    super.key,
    required this.kuisId,
    required this.judulKuis,
    required this.nomorAwal,
    this.soal,
  });

  @override
  State<EditSoalKuisPage> createState() => _EditSoalKuisPageState();
}

class _EditSoalKuisPageState extends State<EditSoalKuisPage> {
  final AdminService _service = AdminService();
  final ImagePicker _picker = ImagePicker();

  final _pertanyaan = TextEditingController();
  final _penjelasan = TextEditingController();
  final List<TextEditingController> _opsi =
      List.generate(4, (_) => TextEditingController());

  late int _jawaban = _indeksJawaban(widget.soal?.jawabanBenar ?? 'A');
  String? _gambarUrl;
  String? _gambarLokal;
  bool _unggahGambar = false;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final soal = widget.soal;
    if (soal != null) {
      _pertanyaan.text = soal.pertanyaan;
      _penjelasan.text = soal.penjelasan;
      final opsi = _opsi4(soal.opsi);
      for (var i = 0; i < 4; i++) {
        _opsi[i].text = opsi[i];
      }
      _gambarUrl = soal.gambarPertanyaan;
    }
  }

  @override
  void dispose() {
    _pertanyaan.dispose();
    _penjelasan.dispose();
    for (final o in _opsi) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    final hasil = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (hasil == null) return;
    setState(() => _unggahGambar = true);
    try {
      final webp = await ImageCompressService.toWebP(
        hasil.path,
        maxWidth: 1280,
        quality: 70,
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

  Future<void> _simpan() async {
    final pertanyaan = _pertanyaan.text.trim();
    if (pertanyaan.isEmpty && _gambarUrl == null) {
      toast(context, 'Pertanyaan atau foto soal wajib diisi.',
          type: AppSnackType.warning);
      return;
    }
    for (var i = 0; i < 4; i++) {
      if (_opsi[i].text.trim().isEmpty) {
        toast(context, 'Pilihan ${hurufOpsi(i)} masih kosong.',
            type: AppSnackType.warning);
        return;
      }
    }
    setState(() => _menyimpan = true);
    try {
      await _service.simpanSoal(
        id: widget.soal?.id,
        kuisId: widget.kuisId,
        pertanyaan: pertanyaan,
        opsi: [for (final o in _opsi) o.text.trim()],
        jawabanBenar: hurufOpsi(_jawaban),
        gambarPertanyaan: _gambarUrl,
        opsiGambar: widget.soal?.opsiGambar ?? const ['', '', '', ''],
        penjelasan: _penjelasan.text.trim(),
        urutan: widget.soal?.urutan ?? widget.nomorAwal,
      );
      final judul = widget.judulKuis;
      await _service.catatLog(
        '${widget.soal == null ? 'Menambah' : 'Mengedit'} soal "$judul"',
      );
      if (!mounted) return;
      toast(
        context,
        widget.soal == null ? 'Soal ditambahkan.' : 'Soal diperbarui.',
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
          widget.soal == null ? 'Tambah Soal' : 'Edit Soal',
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            widget.judulKuis,
            style:
                AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pertanyaan,
            maxLines: 4,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Pertanyaan'),
          ),
          const SizedBox(height: 10),
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
                    tooltip: 'Hapus foto',
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
                onPressed: _unggahGambar ? null : _pilihFoto,
                icon: _unggahGambar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(
                  _unggahGambar ? 'Mengunggah…' : 'Tambah foto soal',
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Pilihan jawaban', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  kotakHuruf(hurufOpsi(i), _jawaban == i),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _opsi[i],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Pilihan ${hurufOpsi(i)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text('Jawaban benar', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 4; i++)
                AppChoiceChip(
                  label: hurufOpsi(i),
                  isSelected: _jawaban == i,
                  onTap: () => setState(() => _jawaban = i),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _penjelasan,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Penjelasan jawaban (opsional)',
            ),
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
                : const Text('Simpan Soal'),
          ),
        ),
      ),
    );
  }
}

/// Halaman pratinjau kuis yang sudah tersimpan (dibuka dari halaman edit).
class _PratinjauKuisPage extends StatelessWidget {
  final String judul;
  final String materiNama;
  final int xp;
  final String? bannerUrl;
  final String? bannerLokal;
  final List<SoalAdminItem> soal;

  const _PratinjauKuisPage({
    required this.judul,
    required this.materiNama,
    required this.xp,
    required this.bannerUrl,
    required this.bannerLokal,
    required this.soal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Pratinjau Kuis', style: AppTextStyles.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          kartuInfo(
            gambarUrl: bannerUrl,
            gambarLokal: bannerLokal,
            gambarTinggi: 150,
            judul: judul,
            meta: '$materiNama • ${soal.length} soal • +$xp XP',
          ),
          const SizedBox(height: 16),
          if (soal.isEmpty)
            Text(
              'Belum ada soal pada kuis ini.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < soal.length; i++)
              kartuSoalPratinjau(
                nomor: i + 1,
                pertanyaan: soal[i].pertanyaan,
                opsi: _opsi4(soal[i].opsi),
                jawaban: _indeksJawaban(soal[i].jawabanBenar),
                gambarUrl: soal[i].gambarPertanyaan,
                penjelasan: soal[i].penjelasan,
              ),
        ],
      ),
    );
  }
}
