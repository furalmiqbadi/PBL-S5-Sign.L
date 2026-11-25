import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/gestur_model.dart';
import '../../services/materi_service.dart';
import '../../services/ml_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/section_header.dart';

/// Halaman kamera latihan isyarat.
///
/// Alur: tekan "Deteksi" -> hitung mundur 3 detik -> kamera mengambil foto ->
/// foto tampil sebagai pratinjau -> model TFLite menilai hasilnya -> laporan
/// benar/salah muncul di bottom sheet. Bila huruf berhasil dikenali dan materi
/// bagian untuk huruf itu ada, isi materinya ikut ditampilkan. Bila berkas
/// model belum tersedia, muncul keterangan agar pengguna menghubungi ML
/// Engineer, bukan crash.
class CameraScreen extends StatefulWidget {
  /// Huruf target, mis. `A`. Default huruf pertama alfabet latihan.
  final String huruf;

  /// Bagian materi yang tiap bagiannya mewakili satu kelas huruf.
  final List<MateriBagian> bagian;

  const CameraScreen({super.key, this.huruf = 'A', this.bagian = const []});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _menyiapkan = true;
  bool _memproses = false;
  String? _error;

  /// Sisa hitung mundur sebelum foto diambil. Null = tidak sedang menghitung.
  int? _menghitung;

  /// Foto hasil jepretan yang sedang ditampilkan sebagai pratinjau.
  XFile? _foto;

  /// Hasil deteksi terakhir, dipakai untuk ringkasan di panel bawah.
  HasilDeteksi? _hasil;

  Timer? _timerHitung;

  @override
  void initState() {
    super.initState();
    _siapkan();
    MlService.instance.siapkan().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _siapkan() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _menyiapkan = false;
            _error = 'Tidak ada kamera yang tersedia di perangkat ini.';
          });
        }
        return;
      }
      final depan = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        depan,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _menyiapkan = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _menyiapkan = false;
        _error = e.description ??
            'Kamera tidak bisa dibuka. Periksa izin kamera di pengaturan.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menyiapkan = false;
        _error = 'Kamera tidak bisa dibuka: $e';
      });
    }
  }

  /// Mulai alur deteksi: siapkan model, lalu hitung mundur 3 detik.
  Future<void> _mulaiDeteksi() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_memproses || _menghitung != null) return;

    if (!MlService.instance.siap) {
      final siap = await MlService.instance.siapkan();
      if (!mounted) return;
      if (!siap) {
        showAppSnackBar(
          context,
          MlService.instance.pesanGagal ?? 'Model deteksi belum tersedia.',
          type: AppSnackType.warning,
        );
        return;
      }
      setState(() {});
    }

    setState(() {
      _foto = null;
      _hasil = null;
      _menghitung = 3;
    });
    _timerHitung?.cancel();
    _timerHitung = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final sisa = (_menghitung ?? 1) - 1;
      if (sisa <= 0) {
        timer.cancel();
        setState(() => _menghitung = null);
        _ambilFoto();
      } else {
        setState(() => _menghitung = sisa);
      }
    });
  }

  /// Mengambil foto, menampilkan pratinjaunya, lalu menilai dengan model.
  Future<void> _ambilFoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _memproses = true);
    try {
      final foto = await controller.takePicture();
      if (!mounted) return;
      // Pratinjau foto langsung tampil sebelum laporan benar/salah keluar.
      setState(() => _foto = foto);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      final hasil = await MlService.instance.deteksi(
        foto.path,
        target: widget.huruf,
      );
      if (!mounted) return;
      setState(() => _hasil = hasil);
      await _tampilkanHasil(hasil);
    } on ModelTidakTersedia catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.pesan, type: AppSnackType.warning);
    } on CameraException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        e.description ?? 'Gagal mengambil gambar dari kamera.',
        type: AppSnackType.error,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Deteksi gagal dijalankan. Coba lagi.',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  Future<void> _tampilkanHasil(HasilDeteksi hasil) async {
    final cocok = hasil.huruf == widget.huruf.toUpperCase();
    final bagian = _bagianUntuk(hasil.huruf);
    await showAppBottomSheet<void>(
      context,
      title: cocok ? 'Tepat sekali!' : 'Belum cocok',
      subtitle: cocok
          ? 'Bentuk tanganmu terbaca sebagai huruf ${hasil.huruf}.'
          : 'Terbaca huruf ${hasil.huruf}, targetnya ${widget.huruf}.',
      icon: cocok ? Icons.check_circle_rounded : Icons.refresh_rounded,
      iconColor: cocok ? AppColors.success : AppColors.tertiary,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pratinjau foto yang dinilai, supaya laporan benar/salah bisa
            // langsung dibandingkan dengan gerakan yang tadi ditampilkan.
            if (_foto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Image.file(
                  File(_foto!.path),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child:
                      Text('Keyakinan model', style: AppTextStyles.bodySmall),
                ),
                Text('${hasil.persen}%', style: AppTextStyles.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: hasil.keyakinan,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cocok ? AppColors.success : AppColors.tertiary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (bagian != null) ...[
              _IsiBagianDeteksi(bagian: bagian),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                cocok
                    ? 'Lanjutkan ke huruf berikutnya atau ulangi untuk menguatkan.'
                    : 'Posisikan tangan di tengah bingkai, lalu tekan Deteksi lagi.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 18),
            ],
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(cocok ? 'Lanjut' : 'Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bagian materi yang kelas hurufnya sama dengan huruf terdeteksi.
  MateriBagian? _bagianUntuk(String huruf) {
    final kunci = huruf.toUpperCase();
    for (final b in widget.bagian) {
      if (b.huruf?.toUpperCase() == kunci) return b;
    }
    return null;
  }

  @override
  void dispose() {
    _timerHitung?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPreview()),
            _buildPanel(),
          ],
        ),
      ),
    );
  }

  /// Header chrome yang sama dengan halaman lain: tombol 48x48, judul 20px.
  Widget _buildHeader() {
    return Padding(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latihan Kamera',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target huruf ${widget.huruf}',
                    style: AppTextStyles.labelXSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _controller;
    if (_menyiapkan) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded,
                    size: 32, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('Kamera tidak aktif', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  _error ?? 'Kamera belum siap.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final foto = _foto;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              child: foto == null
                  ? CameraPreview(controller)
                  : Image.file(
                      File(foto.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: AppColors.textMuted, size: 32),
                      ),
                    ),
            ),
          ),
        ),
        // Bingkai panduan hanya relevan saat kamera masih live.
        if (foto == null)
          Center(
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
              ),
            ),
          ),
        if (_menghitung != null) _buildHitungMundur(),
        if (_memproses && foto != null) _buildMenilai(),
      ],
    );
  }

  /// Lapisan hitung mundur 3 detik sebelum foto diambil.
  Widget _buildHitungMundur() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '$_menghitung',
                key: ValueKey<int>(_menghitung ?? 0),
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 96,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tahan posisi tangan',
              style: AppTextStyles.titleSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Penanda bahwa model sedang menilai foto yang baru diambil.
  Widget _buildMenilai() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Menilai gerakan…',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final hasil = _hasil;
    final cocok = hasil != null && hasil.huruf == widget.huruf.toUpperCase();
    final sibuk = _memproses || _menghitung != null;
    final warnaHasil = cocok ? AppColors.success : AppColors.tertiary;

    final String label;
    if (_menghitung != null) {
      label = 'Bersiap…';
    } else if (_memproses) {
      label = _foto == null ? 'Mengambil foto…' : 'Menilai…';
    } else if (_foto != null) {
      label = 'Foto Ulang';
    } else {
      label = 'Deteksi';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Image.asset(
                  gesturAssetPath(widget.huruf),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    color: AppColors.pinkSoft,
                    child: Text(
                      widget.huruf,
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bentuk huruf ${widget.huruf}',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      _foto == null
                          ? 'Letakkan tangan di dalam bingkai, lalu tekan Deteksi.'
                          : 'Foto sudah diambil. Tekan Foto Ulang untuk mencoba lagi.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasil != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: warnaHasil.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  Icon(
                    cocok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: warnaHasil,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cocok
                          ? 'Benar, terbaca huruf ${hasil.huruf}.'
                          : 'Salah, terbaca huruf ${hasil.huruf} · target ${widget.huruf}.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${hasil.persen}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: warnaHasil,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: sibuk ? null : _mulaiDeteksi,
              icon: sibuk
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _foto != null
                          ? Icons.camera_alt_rounded
                          : Icons.camera_rounded,
                      size: 20,
                    ),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isi materi bagian yang kelas hurufnya cocok dengan huruf terdeteksi.
class _IsiBagianDeteksi extends StatelessWidget {
  final MateriBagian bagian;

  const _IsiBagianDeteksi({required this.bagian});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bagian.judul.isEmpty ? 'Materi huruf ${bagian.huruf}' : bagian.judul,
          style: AppTextStyles.titleSmall,
        ),
        if (bagian.isi.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            bagian.isi,
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
        ],
        if (bagian.adaFoto) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Image.network(
              bagian.fotoUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                alignment: Alignment.center,
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.broken_image_rounded,
                    color: AppColors.textMuted),
              ),
            ),
          ),
        ],
        if (bagian.adaVideo) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: _VideoBagian(url: bagian.videoUrl!),
          ),
        ],
      ],
    );
  }
}

/// Pemutar video bagian yang ringkas, dipakai di dalam hasil deteksi.
class _VideoBagian extends StatefulWidget {
  final String url;

  const _VideoBagian({required this.url});

  @override
  State<_VideoBagian> createState() => _VideoBagianState();
}

class _VideoBagianState extends State<_VideoBagian> {
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
      return Container(
        height: 90,
        alignment: Alignment.center,
        color: AppColors.surfaceMuted,
        child:
            Text('Video tidak dapat diputar', style: AppTextStyles.bodySmall),
      );
    }
    if (video == null) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
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
          AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
          if (!video.value.isPlaying)
            const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 40),
        ],
      ),
    );
  }
}
