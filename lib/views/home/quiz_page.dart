import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/kuis_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/share_sheet.dart';

/// Layar pengerjaan satu kuis dari tabel `soal`.
///
/// Soal, opsi, dan jawaban benar dibaca langsung dari Supabase. Hasil
/// pengerjaan disimpan ke `hasil_kuis` sebagai nilai 0-100.
class QuizPage extends StatefulWidget {
  final KuisInfo kuis;

  const QuizPage({super.key, required this.kuis});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final KuisService _service = KuisService();

  List<SoalKuis> _soal = const [];
  bool _loading = true;
  String? _error;

  int _index = 0;
  int? _selected;
  bool _checked = false;
  int _benar = 0;
  bool _tersimpan = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final soal = await _service.fetchSoal(widget.kuis.id);
      if (!mounted) return;
      setState(() {
        _soal = soal;
        _loading = false;
        _index = 0;
        _selected = null;
        _checked = false;
        _benar = 0;
        _tersimpan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : '$e';
      });
    }
  }

  SoalKuis get _current => _soal[_index];

  bool get _jawabanBenar =>
      _selected != null && _current.opsi[_selected!] == _current.jawabanBenar;

  void _periksa() {
    if (_selected == null || _checked) return;
    setState(() {
      _checked = true;
      if (_jawabanBenar) _benar++;
    });
  }

  void _lanjut() {
    if (_index >= _soal.length - 1) {
      _tampilHasil();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _checked = false;
    });
  }

  void _ulangi() {
    setState(() {
      _index = 0;
      _selected = null;
      _checked = false;
      _benar = 0;
    });
  }

  int get _skor => _soal.isEmpty ? 0 : (_benar * 100 / _soal.length).round();

  Future<void> _tampilHasil() async {
    final total = _soal.length;
    final skor = _skor;
    final lulus = skor >= 60;

    if (!_tersimpan) {
      _tersimpan = true;
      await _service.simpanHasil(kuisId: widget.kuis.id, skor: skor);
    }
    if (!mounted) return;

    final ulangi = await showAppDialog(
      context,
      title: lulus ? 'Lulus!' : 'Belum Lulus',
      message: lulus
          ? 'Hebat! Kamu sudah menguasai materi ini.'
          : 'Minimal 60 untuk lulus. Pelajari lagi materinya lalu coba kembali.',
      icon: lulus ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied,
      iconColor: lulus ? AppColors.primary : AppColors.textSecondary,
      centerHeader: true,
      confirmLabel: lulus ? 'Selesai' : 'Ulangi',
      cancelLabel: 'Selesai',
      showCancel: !lulus,
      barrierDismissible: false,
      content: Column(
        children: [
          Row(
            children: [
              _statBox(
                Icons.check_circle_rounded,
                'BENAR',
                '$_benar/$total',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _statBox(
                Icons.percent_rounded,
                'SKOR',
                '$skor',
                AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _statBox(
                Icons.star_rounded,
                'XP',
                '+${widget.kuis.xpReward}',
                AppColors.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => showShareSheet(
                context,
                text:
                    'Aku baru menyelesaikan ${widget.kuis.judul} di Sign.L: $_benar/$total soal benar (skor $skor).',
                mediaUrl: widget.kuis.bannerUrl,
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Bagikan Hasil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (lulus) {
      Navigator.pop(context);
    } else if (ulangi == true) {
      _ulangi();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _statBox(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelXSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal memuat soal',
        message: _error!,
        action: OutlinedButton(
          onPressed: _muat,
          child: const Text('Coba Lagi'),
        ),
      );
    }
    if (_soal.isEmpty) {
      return _buildMessage(
        icon: Icons.quiz_outlined,
        title: 'Belum ada soal',
        message:
            'Kuis ini belum memiliki soal. Hubungi admin untuk melengkapinya.',
        action: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildQuestionCard(),
          const SizedBox(height: 16),
          _buildOptions(),
          const SizedBox(height: 20),
          if (_checked) ...[
            _buildFeedback(),
            const SizedBox(height: 12),
          ],
          _buildActionButton(),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTonal,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 26),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              action,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: _soal.isEmpty
                    ? 0
                    : (_index + (_checked ? 1 : 0)) / _soal.length,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'assets/images/diamond_fix.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.secondary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+${widget.kuis.xpReward}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppStatusBadge(
              label: widget.kuis.judul.toUpperCase(),
              color: AppColors.primary,
              backgroundColor: AppColors.pinkSoft,
            ),
            const SizedBox(width: 8),
            Text(
              'Pertanyaan ${_index + 1} dari ${_soal.length}',
              style: AppTextStyles.labelXSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_current.adaGambarPertanyaan) ...[
          _buildGambarPertanyaan(_current.gambarPertanyaan!),
          const SizedBox(height: 10),
        ],
        if (_current.pertanyaan.isNotEmpty)
          Text(_current.pertanyaan, style: AppTextStyles.headlineSmall),
      ],
    );
  }

  Widget _buildGambarPertanyaan(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surfaceTonal,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            color: AppColors.surfaceTonal,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PILIH SATU JAWABAN',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _current.opsi.isNotEmpty
                ? '${_current.opsi.length} pilihan tersedia'
                : 'Opsi belum tersedia',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: List.generate(_current.opsi.length, (i) {
        final opsi = _current.opsi[i];
        final gambar = _current.gambarOpsi(i);
        final selected = _selected == i;
        final isCorrect = opsi == _current.jawabanBenar;

        Color? accent;
        if (_checked) {
          if (isCorrect) {
            accent = AppColors.success;
          } else if (selected) {
            accent = AppColors.danger;
          }
        } else if (selected) {
          accent = AppColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: _checked ? null : () => setState(() => _selected = i),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: AppRadii.md,
            borderColor: accent ?? AppColors.border,
            borderWidth: accent != null ? 2 : 1,
            shadows: accent != null ? AppShadows.card : AppShadows.soft,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent ?? AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: accent != null
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (gambar != null) ...[
                  _buildGambarOpsi(gambar, accent),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    opsi,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                if (accent != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _checked && !isCorrect
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                    color: accent,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGambarOpsi(String url, Color? accent) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceTonal,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: accent != null
            ? Border.all(color: accent, width: 2)
            : Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stack) => const Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final benar = _jawabanBenar;
    final color = benar ? AppColors.success : AppColors.danger;
    final penjelasan = _current.penjelasan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(benar ? Icons.check_circle : Icons.cancel, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benar
                      ? 'Benar! Jawabanmu tepat.'
                      : 'Kurang tepat. Jawaban benar ditandai hijau.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (penjelasan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              penjelasan,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bisaPeriksa = _selected != null;
    final terakhir = _index >= _soal.length - 1;
    final label =
        !_checked ? 'Periksa Jawaban' : (terakhir ? 'Lihat Hasil' : 'Lanjut');

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
            borderRadius: BorderRadius.circular(AppRadii.md),
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
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'Bahasa Isyarat Indonesia (BISINDO)',
          style: AppTextStyles.labelXSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
