import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/detail_materi_controller.dart';
import '../../models/bab_model.dart';
import '../../services/kuis_service.dart';
import '../../services/materi_service.dart';
import '../camera/camera_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/app_ui.dart';
import '../widgets/detail_header.dart';
import '../widgets/quiz_card.dart';
import '../widgets/section_header.dart';
import 'isi_materi_page.dart';
import 'quiz_page.dart';

/// Halaman detail satu materi: ringkasan bab, latihan huruf, dan kuis milik
/// materi tersebut. Semua data berasal dari Supabase lewat
/// [DetailMateriController].
class DetailMateriPage extends StatefulWidget {
  /// UUID materi. Bila null, controller memilih bab yang sedang berjalan.
  final String? materiId;

  const DetailMateriPage({super.key, this.materiId});

  @override
  State<DetailMateriPage> createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  late final DetailMateriController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DetailMateriController(materiId: widget.materiId);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bukaLatihan(Bab bab) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsiMateriPage(
          materiId: bab.id,
          judulMateri: bab.title,
          bagian: _controller.bagian,
        ),
      ),
    );
    if (mounted) _controller.load(force: true);
  }

  Future<void> _bukaKuis(KuisInfo kuis) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizPage(kuis: kuis)),
    );
    if (mounted) _controller.load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final bab = _controller.bab;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildTopBar(bab),
                  ),
                  Expanded(child: _buildBody(bab)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Bab? bab) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.hasError || bab == null) {
      return _buildPesan(
        icon: Icons.cloud_off_rounded,
        title: 'Gagal memuat materi',
        message: _controller.errorMessage ?? 'Materi tidak ditemukan.',
        onRetry: () => _controller.load(force: true),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildRingkasan(bab),
        if (_controller.bagian.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(_labelHuruf('A'), AppColors.info,
              title: 'Materi Bagian'),
          const SizedBox(height: 12),
          for (final bagian in _controller.bagian)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBagian(bagian),
            ),
        ],
        if (bab.hasLetterPractice) ...[
          const SizedBox(height: 24),
          _sectionTitle(_labelHuruf(_controller.bagian.isEmpty ? 'A' : 'B'),
              AppColors.primary,
              title: 'Latihan Ejaan Tangan'),
          const SizedBox(height: 12),
          _buildLatihanCard(bab),
        ],
        const SizedBox(height: 24),
        _sectionTitle(
            _labelHuruf(_nextHuruf(
              materi: _controller.bagian.isNotEmpty,
              latihan: bab.hasLetterPractice,
            )),
            AppColors.tertiary,
            title: 'Ujian Materi',
            trailing: _controller.kuis.isEmpty
                ? null
                : Text(
                    '${_controller.kuisSelesai} dari ${_controller.kuis.length} selesai',
                    style: AppTextStyles.labelXSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )),
        const SizedBox(height: 12),
        if (_controller.kuis.isEmpty)
          _buildPesan(
            icon: Icons.quiz_outlined,
            title: 'Belum ada kuis',
            message:
                'Materi ini belum memiliki kuis. Silakan cek kembali nanti.',
            onRetry: () => _controller.load(force: true),
          )
        else
          ..._controller.kuis.map(
            (kuis) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuizCard(
                kuis: kuis,
                onStart: kuis.bisaDikerjakan ? () => _bukaKuis(kuis) : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(Bab? bab) {
    void kembali() {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }

    if (bab == null) {
      return SizedBox(
        height: SectionHeader.contentHeight,
        child: Row(
          children: [
            HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Kembali',
              onTap: kembali,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Detail Materi', style: AppTextStyles.headlineSmall),
            ),
          ],
        ),
      );
    }
    return DetailHeader(bab: bab, onBack: kembali);
  }

  Widget _buildRingkasan(Bab bab) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Permukaan tonal solid: satu bahasa dengan kartu lain, tanpa
              // gradasi dekoratif.
              color: AppColors.surfaceTonal,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(
                    Icons.sign_language_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Materi pembelajaran',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bab.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AppStatusBadge(
                label: babStatusLabel(bab.status),
                color: babStatusColor(bab.status),
                backgroundColor:
                    babStatusColor(bab.status).withValues(alpha: 0.12),
              ),
              const Spacer(),
              Text(
                'Bab ${bab.number}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bab.title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (bab.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bab.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ],
          if (bab.adaGambar) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Image.network(
                bab.gambarUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ],
          if (bab.adaVideo) ...[
            const SizedBox(height: 14),
            _tombolVideo(bab),
          ],
          if (bab.adaKamera) ...[
            const SizedBox(height: 14),
            _kartuKamera(bab),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTonal,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  bab.hasLetterPractice ? 'Total Huruf' : 'Total Kuis',
                  '${bab.totalMateri}',
                  AppColors.textPrimary,
                ),
                _buildDivider(),
                _buildInfoColumn(
                  'Selesai',
                  '${bab.completedMateri}',
                  AppColors.primary,
                ),
                _buildDivider(),
                _buildInfoColumn(
                  'Kuis',
                  '${bab.kuisSelesai}/${bab.kuisTotal}',
                  AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelXSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLatihanCard(Bab bab) {
    return AppCard(
      onTap: () => _bukaLatihan(bab),
      borderColor: AppColors.primary.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pinkSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latihan huruf isyarat',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bab.progressText,
                      style: AppTextStyles.labelXSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(bab.progress * 100).round()}%',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: bab.progress,
              minHeight: 8,
              backgroundColor: AppColors.pinkSoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _bukaLatihan(bab),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                bab.isCompleted ? 'Ulangi Latihan' : 'Mulai Latihan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolVideo(Bab bab) {
    return AppCard(
      onTap: () => _putarVideo(bab),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadii.md,
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video materi', style: AppTextStyles.titleSmall),
                Text(
                  'Tonton penjelasan sebelum berlatih',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Future<void> _putarVideo(Bab bab) async {
    final url = bab.videoUrl;
    if (url == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoMateriPage(judul: bab.title, url: url),
      ),
    );
  }

  Widget _kartuKamera(Bab bab) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            huruf: bab.kameraHuruf ?? 'A',
            bagian: _controller.bagian,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadii.md,
      borderColor: AppColors.tertiary.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child:
                const Icon(Icons.camera_alt_rounded, color: AppColors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latihan kamera: huruf ${bab.kameraHuruf}',
                    style: AppTextStyles.titleSmall),
                Text(
                  'Posisikan tangan di depan kamera',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildBagian(MateriBagian bagian) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bagian.judul.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    bagian.judul,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (bagian.huruf != null) ...[
                  const SizedBox(width: 8),
                  AppStatusBadge(
                    label: 'Kelas ${bagian.huruf}',
                    color: AppColors.primary,
                    backgroundColor: AppColors.pinkSoft,
                  ),
                ],
              ],
            ),
            if (bagian.isi.isNotEmpty) const SizedBox(height: 8),
          ],
          if (bagian.isi.isNotEmpty)
            Text(
              bagian.isi,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          if (bagian.adaFoto) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Image.network(
                bagian.fotoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth:
                    (300 * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ],
          if (bagian.adaVideo) ...[
            const SizedBox(height: 12),
            AppCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _VideoMateriPage(
                    judul: bagian.judul.isEmpty ? 'Video materi' : bagian.judul,
                    url: bagian.videoUrl!,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: AppRadii.md,
              borderColor: AppColors.info.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded,
                      color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Putar video bagian ini',
                        style: AppTextStyles.titleSmall),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _labelHuruf(String huruf) => '$huruf.';

  /// Huruf section berikutnya: A bila tidak ada materi/latihan, B, lalu C.
  String _nextHuruf({required bool materi, required bool latihan}) {
    final lewat = (materi ? 1 : 0) + (latihan ? 1 : 0);
    return String.fromCharCode('A'.codeUnitAt(0) + lewat);
  }

  Widget _sectionTitle(
    String huruf,
    Color dotColor, {
    String? title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$huruf ${title ?? ''}'.trim(),
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildPesan({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Muat ulang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pemutar video materi sederhana dengan kontrol putar/jeda.
class _VideoMateriPage extends StatefulWidget {
  final String judul;
  final String url;

  const _VideoMateriPage({required this.judul, required this.url});

  @override
  State<_VideoMateriPage> createState() => _VideoMateriPageState();
}

class _VideoMateriPageState extends State<_VideoMateriPage> {
  VideoPlayerController? _video;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _siapkan();
  }

  Future<void> _siapkan() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
      await controller.play();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  height: SectionHeader.contentHeight,
                  child: Row(
                    children: [
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Kembali',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _gagal
                      ? const _EditorialPesan()
                      : video == null
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AspectRatio(
                                  aspectRatio: video.value.aspectRatio,
                                  child: VideoPlayer(video),
                                ),
                                const SizedBox(height: 16),
                                ValueListenableBuilder<VideoPlayerValue>(
                                  valueListenable: video,
                                  builder: (context, value, _) =>
                                      ElevatedButton.icon(
                                    onPressed: () => value.isPlaying
                                        ? video.pause()
                                        : video.play(),
                                    icon: Icon(
                                      value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    label: Text(
                                      value.isPlaying ? 'Jeda' : 'Putar',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialPesan extends StatelessWidget {
  const _EditorialPesan();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Video tidak dapat diputar', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Periksa tautan video materi lalu coba lagi.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
