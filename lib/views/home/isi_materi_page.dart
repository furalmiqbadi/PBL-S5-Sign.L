import 'package:flutter/material.dart';

import '../../controllers/isi_materi_controller.dart';
import '../../models/gestur_model.dart';
import '../../services/materi_service.dart';
import '../camera/camera_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/app_ui.dart';
import '../widgets/gestur_description_card.dart';
import '../widgets/gestur_preview.dart';
import '../widgets/isi_materi_bottom_bar.dart';
import '../widgets/isi_materi_header.dart';
import '../widgets/latihan_progress_bar.dart';

/// Halaman latihan huruf untuk satu materi.
///
/// Materi non-alfabet tidak punya latihan huruf sehingga halaman ini
/// menampilkan pesan kosong. Progres disimpan ke `progres_materi` setiap
/// pengguna menyelesaikan latihan terakhir.
class IsiMateriPage extends StatefulWidget {
  final String materiId;
  final String judulMateri;
  final int startIndex;
  final String? startHuruf; // contoh: 'G'

  /// Bagian materi dengan kelas huruf masing-masing, dipakai layar kamera.
  final List<MateriBagian> bagian;

  const IsiMateriPage({
    super.key,
    required this.materiId,
    required this.judulMateri,
    this.startIndex = 0,
    this.startHuruf,
    this.bagian = const [],
  });

  @override
  State<IsiMateriPage> createState() => _IsiMateriPageState();
}

class _IsiMateriPageState extends State<IsiMateriPage> {
  final MateriService _materiService = MateriService();
  late final IsiMateriController _controller;

  @override
  void initState() {
    super.initState();

    final list = gesturUntukMateri(widget.judulMateri);
    var start = widget.startIndex;
    if (widget.startHuruf != null) {
      final found = list.indexWhere((g) => g.huruf == widget.startHuruf);
      if (found >= 0) start = found;
    }

    _controller = IsiMateriController(daftarGestur: list, startIndex: start);
    _controller.onBack = () => Navigator.of(context).pop();
    _controller.onOpenCamera = () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            huruf: _controller.gestur.huruf,
            bagian: widget.bagian,
          ),
        ),
      );
    };
    _controller.onFinished = _simpanProgres;
  }

  /// Menyimpan jumlah huruf yang sudah dipelajari lalu menutup halaman.
  void _simpanProgres() {
    final total = _controller.daftarGestur.length;
    _materiService.simpanProgresHuruf(
      materiId: widget.materiId,
      hurufDipelajari: total,
      totalHuruf: total,
    );
    showAppSnackBar(
      context,
      'Latihan selesai. Progres tersimpan.',
      type: AppSnackType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  IsiMateriHeader(onBack: _controller.goBack),
                  Expanded(
                    child: _controller.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            children: [
                              GesturPreview(
                                  assetPath: _controller.gestur.assetPath),
                              const SizedBox(height: 12),
                              GesturDescriptionCard(gestur: _controller.gestur),
                              const SizedBox(height: 16),
                              LatihanProgressBar(gestur: _controller.gestur),
                            ],
                          ),
                  ),
                  if (!_controller.isEmpty)
                    IsiMateriBottomBar(
                      onPrevious: _controller.previousGestur,
                      onCamera: _controller.openCamera,
                      onNext: _controller.nextGestur,
                      isFirst: _controller.isFirst,
                      isLast: _controller.isLast,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTonal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada latihan huruf',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Materi "${widget.judulMateri}" hanya berisi kuis. '
              'Buka tab Kuis untuk mengerjakannya.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
