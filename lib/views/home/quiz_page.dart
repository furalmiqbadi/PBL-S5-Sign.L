import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/settings_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/share_sheet.dart';

// ============================================================================
// KONFIGURASI
// ============================================================================

/// Bucket Storage, hanya dipakai bila kolom gambar berisi path (bukan URL penuh).
const String _bucketGambar = 'quiz';

/// Jumlah nyawa per sesi kuis.
const int _nyawaAwal = 5;

/// Skor minimal (0-100) agar kuis dianggap lulus dan kuis berikutnya terbuka.
/// Dipakai juga oleh KuisPage untuk menentukan kuis yang terkunci.
const int skorLulus = 60;

/// Getaran halus saat jawaban benar, getaran kuat saat salah.
/// Mengikuti toggle "Getaran Responsif" di halaman Pengaturan.
void cekJawaban(bool benar, {required bool getaranAktif}) {
  if (!getaranAktif) return;
  if (benar) {
    HapticFeedback.lightImpact();
  } else {
    HapticFeedback.heavyImpact();
  }
}

// ============================================================================
// MODEL
// ============================================================================

class _Opsi {
  final String teks;
  final String? gambar;
  const _Opsi(this.teks, this.gambar);
}

class _Soal {
  final String pertanyaan;
  final String? gambar;
  final List<_Opsi> opsi;
  final _Opsi benar;
  final String penjelasan;

  const _Soal({
    required this.pertanyaan,
    required this.gambar,
    required this.opsi,
    required this.benar,
    required this.penjelasan,
  });

  /// Opsi bergambar bila semua opsi punya gambar.
  bool get pakaiGambar =>
      opsi.every((o) => o.gambar != null && o.gambar!.isNotEmpty);

  /// Salinan dengan urutan opsi diacak.
  _Soal acak(Random rnd) => _Soal(
        pertanyaan: pertanyaan,
        gambar: gambar,
        opsi: List<_Opsi>.from(opsi)..shuffle(rnd),
        benar: benar,
        penjelasan: penjelasan,
      );
}

// ============================================================================
// PAGE
// ============================================================================

class QuizPage extends StatefulWidget {
  /// ID baris di tabel `kuis`. Bila null, dibuka kuis tertua yang sudah
  /// punya soal.
  final String? kuisId;

  const QuizPage({super.key, this.kuisId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Data kuis dari Supabase
  String? _kuisId;
  String _judul = 'Kuis';
  int _xpPerSoal = 10;
  List<_Soal> _bank = []; // soal asli dari database (urut sesuai `urutan`)

  // State sesi
  List<_Soal> _soal = [];
  int _index = 0;
  int? _selected;
  bool _checked = false;
  int _benar = 0;
  int _hearts = _nyawaAwal;
  int _xp = 0;
  bool _hasilTersimpan = false;

  @override
  void initState() {
    super.initState();
    _muatKuis();
  }

  // --------------------------------------------------------------------------
  // AMBIL DATA DARI SUPABASE
  // --------------------------------------------------------------------------

  /// Dipanggil tombol "Coba Lagi".
  void _muatUlang() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _muatKuis();
  }

  Future<void> _muatKuis() async {
    try {
      // 1. Ambil data kuis
      final Map<String, dynamic>? kuis;
      if (widget.kuisId != null) {
        kuis = await _client
            .from('kuis')
            .select('id, judul, xp_reward')
            .eq('id', widget.kuisId!)
            .maybeSingle();
      } else {
        // Tanpa kuisId: ambil kuis tertua yang sudah punya soal.
        final List<dynamic> daftar = await _client
            .from('kuis')
            .select('id, judul, xp_reward, soal(count)')
            .eq('tipe', 'kuis')
            .order('created_at', ascending: true);

        Map<String, dynamic>? pilih;
        for (final k in daftar) {
          final jumlah =
              ((k['soal'] as List?)?.firstOrNull?['count'] as int?) ?? 0;
          if (jumlah > 0) {
            pilih = Map<String, dynamic>.from(k as Map);
            break;
          }
        }
        kuis = pilih;
      }

      if (kuis == null) {
        _gagal('Kuis belum tersedia.');
        return;
      }

      _kuisId = kuis['id'] as String;
      _judul = (kuis['judul'] as String?) ?? 'Kuis';
      _xpPerSoal = (kuis['xp_reward'] as int?) ?? 10;

      // 2. Ambil soal milik kuis tersebut
      final List<dynamic> rows = await _client
          .from('soal')
          .select(
              'pertanyaan, opsi, jawaban_benar, gambar_pertanyaan, opsi_gambar, penjelasan, urutan')
          .eq('kuis_id', _kuisId!)
          .order('urutan', ascending: true);

      _bank = rows
          .map((r) => _parseSoal(Map<String, dynamic>.from(r as Map)))
          .whereType<_Soal>()
          .toList();

      if (_bank.isEmpty) {
        _gagal('Kuis "$_judul" belum punya soal.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _mulaiSesi();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat kuis: $e');
      _gagal('Gagal memuat kuis. Periksa koneksi internet kamu.');
    }
  }

  void _gagal(String pesan) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = pesan;
    });
  }

  /// Mengubah satu baris tabel `soal` menjadi [_Soal].
  /// Mendukung `opsi` berupa array (["A","B"]) atau object ({"A": "..."}),
  /// dan `jawaban_benar` berupa teks opsi, key/label (A-D), atau URL gambar.
  _Soal? _parseSoal(Map<String, dynamic> row) {
    dynamic raw = row['opsi'];
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = <dynamic>[];
      }
    }

    final kunci = <String>[];
    final teks = <String>[];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        kunci.add(String.fromCharCode(65 + i));
        teks.add('${raw[i]}'.trim());
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        kunci.add('$k'.trim());
        teks.add('$v'.trim());
      });
    }

    final gambarRaw = ((row['opsi_gambar'] as List?) ?? const [])
        .map((e) => '$e'.trim())
        .toList();

    final n = max(teks.length, gambarRaw.length);
    if (n < 2) return null;

    final opsi = List<_Opsi>.generate(n, (i) {
      final g = i < gambarRaw.length && gambarRaw[i].isNotEmpty
          ? _urlGambar(gambarRaw[i])
          : null;
      return _Opsi(i < teks.length ? teks[i] : '', g);
    });

    // Cari index jawaban benar
    final j = '${row['jawaban_benar'] ?? ''}'.trim().toLowerCase();
    int idx = teks.indexWhere((t) => t.toLowerCase() == j);
    if (idx < 0) idx = kunci.indexWhere((k) => k.toLowerCase() == j);
    if (idx < 0) idx = gambarRaw.indexWhere((g) => g.toLowerCase() == j);
    if (idx < 0 && j.length == 1) {
      final huruf = j.codeUnitAt(0) - 97; // 'a' -> 0
      if (huruf >= 0 && huruf < n) idx = huruf;
    }
    if (idx < 0 || idx >= n) {
      debugPrint('Soal dilewati, jawaban_benar tidak cocok: ${row['pertanyaan']}');
      return null;
    }

    final gambarSoal = (row['gambar_pertanyaan'] as String?)?.trim();

    return _Soal(
      pertanyaan: (row['pertanyaan'] as String?) ?? '',
      gambar: (gambarSoal == null || gambarSoal.isEmpty)
          ? null
          : _urlGambar(gambarSoal),
      opsi: opsi,
      benar: opsi[idx],
      penjelasan: (row['penjelasan'] as String?) ?? '',
    );
  }

  /// Kolom gambar boleh berisi URL penuh atau path di Storage.
  String _urlGambar(String nilai) {
    if (nilai.startsWith('http')) return nilai;
    return _client.storage.from(_bucketGambar).getPublicUrl(nilai);
  }

  /// Simpan hasil ke `hasil_kuis` dan tambahkan XP ke `profiles`.
  Future<void> _simpanHasil() async {
    if (_hasilTersimpan) return;
    _hasilTersimpan = true;

    final user = _client.auth.currentUser;
    if (user == null || _kuisId == null) return;

    try {
      await _client.from('hasil_kuis').insert({
        'user_id': user.id,
        'kuis_id': _kuisId,
        'skor': _skor,
        'xp_gained': _xp,
      });

      if (_xp > 0) {
        final p = await _client
            .from('profiles')
            .select('xp')
            .eq('id', user.id)
            .single();
        final xpLama = (p['xp'] as int?) ?? 0;
        await _client
            .from('profiles')
            .update({'xp': xpLama + _xp}).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan hasil kuis: $e');
    }
  }

  // --------------------------------------------------------------------------
  // LOGIKA KUIS
  // --------------------------------------------------------------------------

  void _mulaiSesi() {
    final rnd = Random();
    _soal = _bank.map((s) => s.acak(rnd)).toList();
    _index = 0;
    _selected = null;
    _checked = false;
    _benar = 0;
    _hearts = _nyawaAwal;
    _xp = 0;
    _hasilTersimpan = false;
  }

  _Soal get _current => _soal[_index];

  /// Skor 0-100 dari jumlah jawaban benar.
  int get _skor => ((_benar / _soal.length) * 100).round();
  bool get _jawabanBenar =>
      _selected != null && identical(_current.opsi[_selected!], _current.benar);

  void _periksa() {
    if (_selected == null || _checked) return;
    cekJawaban(
      _jawabanBenar,
      getaranAktif: context.read<SettingsController>().settings.haptic,
    );
    setState(() {
      _checked = true;
      if (_jawabanBenar) {
        _benar++;
        _xp += _xpPerSoal;
      } else {
        _hearts--;
      }
    });
  }

  void _lanjut() {
    final habis = _hearts <= 0;
    final terakhir = _index >= _soal.length - 1;
    if (habis || terakhir) {
      _tampilHasil();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _checked = false;
    });
  }

  void _tampilHasil() {
    _simpanHasil();

    final lulus = _skor >= skorLulus;
    final String pesan = lulus
        ? 'Hebat! Kamu lulus kuis "$_judul". Kuis berikutnya sudah terbuka.'
        : (_hearts <= 0
            ? 'Nyawa habis, coba lagi ya.'
            : 'Skor kamu $_skor. Minimal skor $skorLulus untuk lulus.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Kartu utama
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 44),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lulus ? 'Lulus!' : 'Belum Lulus',
                    style: TextStyle(
                      color: lulus ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statBox(
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 22),
                        'BENAR',
                        '$_benar/${_soal.length}',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _statBox(
                        _svgIcon('assets/images/diamond_fix.svg', 22,
                            AppColors.secondary),
                        'DIAMOND',
                        '$_xp',
                        AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _statBox(
                        _svgIcon(
                            'assets/images/heart_fix.svg', 22, AppColors.danger),
                        'HATI',
                        '$_hearts',
                        AppColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => showShareSheet(
                        context,
                        text:
                            'Aku baru menyelesaikan kuis "$_judul" di Sign.L: $_benar/${_soal.length} soal benar dan dapat $_xp diamond! 💪',
                      ),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Bagikan Hasil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (lulus)
                    _gradientButton('Selesai', () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    })
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor: AppColors.fieldFill,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _gradientButton('Ulangi', () {
                            Navigator.pop(ctx);
                            setState(_mulaiSesi);
                          }),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Ikon bulat di atas kartu
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lulus ? AppColors.primary : AppColors.textSecondary,
                border: Border.all(color: AppColors.surface, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                lulus ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: Colors.white,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGET
  // --------------------------------------------------------------------------

  /// Ikon SVG yang di-tint sesuai [color] agar konsisten dengan token tema.
  Widget _svgIcon(String asset, double size, Color color) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _statBox(Widget icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppColors.fieldFill,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.fieldFill,
        child: const Icon(Icons.pan_tool_alt_outlined,
            color: AppColors.textSecondary, size: 40),
      ),
    );
  }

  /// Warna border/badge opsi ke-[i] sesuai status.
  Color _accentFor(int i) {
    final selected = _selected == i;
    final isCorrect = identical(_current.opsi[i], _current.benar);
    if (_checked) {
      if (isCorrect) return AppColors.success;
      if (selected) return AppColors.danger;
      return Colors.transparent;
    }
    return selected ? AppColors.primary : Colors.transparent;
  }

  Widget _labelBulat(int i, Color accent) {
    final aktif = accent != Colors.transparent;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: aktif ? accent : AppColors.fieldFill,
        shape: BoxShape.circle,
      ),
      child: Text(
        String.fromCharCode(65 + i),
        style: TextStyle(
          color: aktif ? Colors.white : AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : (_error != null ? _buildError() : _buildKuis()),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Memuat soal...',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined,
                      size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 160,
                    child: _gradientButton('Coba Lagi', _muatUlang),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKuis() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildPertanyaanCard(),
                const SizedBox(height: 16),
                _current.pakaiGambar ? _buildOpsiGambar() : _buildOpsiTeks(),
                const SizedBox(height: 20),
                if (_checked) _buildFeedback(),
                _buildActionButton(),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: (_index + (_checked ? 1 : 0)) / _soal.length,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _svgIcon('assets/images/heart_fix.svg', 18, AppColors.danger),
          const SizedBox(width: 4),
          Text('$_hearts',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          _svgIcon('assets/images/diamond_fix.svg', 18, AppColors.secondary),
          const SizedBox(width: 4),
          Text('$_xp',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              _judul.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Pertanyaan ${_index + 1} dari ${_soal.length}',
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPertanyaanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERTANYAAN',
            style: TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _current.pertanyaan,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.4,
            ),
          ),
          if (_current.gambar != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _networkImage(_current.gambar!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Opsi berupa gambar (grid 2 kolom).
  Widget _buildOpsiGambar() {
    final opsi = _current.opsi;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: opsi.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final accent = _accentFor(i);
        final aktif = accent != Colors.transparent;
        final isCorrect = identical(opsi[i], _current.benar);

        return GestureDetector(
          onTap: _checked ? null : () => setState(() => _selected = i),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(width: 2, color: accent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _networkImage(opsi[i].gambar!),
                  Positioned(left: 4, top: 4, child: _labelBulat(i, accent)),
                  if (aktif)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _checked && !isCorrect ? Icons.close : Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Opsi berupa teks (daftar vertikal).
  Widget _buildOpsiTeks() {
    final opsi = _current.opsi;
    return Column(
      children: [
        for (var i = 0; i < opsi.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(builder: (_) {
              final accent = _accentFor(i);
              final aktif = accent != Colors.transparent;
              final isCorrect = identical(opsi[i], _current.benar);
              return GestureDetector(
                onTap: _checked ? null : () => setState(() => _selected = i),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        width: 2,
                        color: aktif ? accent : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _labelBulat(i, accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opsi[i].teks,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (aktif)
                        Icon(
                          _checked && !isCorrect
                              ? Icons.cancel
                              : Icons.check_circle,
                          color: accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildFeedback() {
    final benar = _jawabanBenar;
    final warna = benar ? AppColors.success : AppColors.danger;
    final penjelasan = _current.penjelasan.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(benar ? Icons.check_circle : Icons.cancel, color: warna),
              const SizedBox(width: 8),
              if (benar) ...[
                _svgIcon(
                    'assets/images/diamond_fix.svg', 14, AppColors.secondary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  benar
                      ? 'Benar! +$_xpPerSoal'
                      : 'Kurang tepat. Jawaban yang benar ditandai hijau.',
                  style: TextStyle(color: warna, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (penjelasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              penjelasan,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bool bisaPeriksa = _selected != null;
    final bool terakhir = _index >= _soal.length - 1;
    final String label = !_checked
        ? 'Periksa Jawaban'
        : (terakhir || _hearts <= 0 ? 'Lihat Hasil' : 'Lanjut');

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _checked ? _lanjut : (bisaPeriksa ? _periksa : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Text(
          'Bahasa Isyarat Indonesia (BISINDO)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}