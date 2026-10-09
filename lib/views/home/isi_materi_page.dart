import 'package:flutter/material.dart';
import '../../controllers/isi_materi_controller.dart';
import '../../models/gestur_model.dart';
import '../widgets/gestur_description_card.dart';
import '../widgets/gestur_preview.dart';
import '../widgets/isi_materi_bottom_bar.dart';
import '../widgets/isi_materi_header.dart';
import '../widgets/latihan_progress_bar.dart';

class IsiMateriPage extends StatefulWidget {
  final int materiId;
  final int startIndex;
  final String? startHuruf; // contoh: 'G'

  const IsiMateriPage({
    super.key,
    required this.materiId,
    this.startIndex = 0,
    this.startHuruf,
  });

  @override
  State<IsiMateriPage> createState() => _IsiMateriPageState();
}

class _IsiMateriPageState extends State<IsiMateriPage> {
  late final IsiMateriController _controller;

  @override
  void initState() {
    super.initState();

    final list = gesturUntukMateri(widget.materiId);
    var start = widget.startIndex;
    if (widget.startHuruf != null) {
      final found = list.indexWhere((g) => g.huruf == widget.startHuruf);
      if (found >= 0) start = found;
    }

    _controller = IsiMateriController(daftarGestur: list, startIndex: start);
    _controller.onBack = () => Navigator.of(context).pop();
    _controller.onOpenCamera = () {
      // TODO: Navigator.push ke halaman kamera AI
      debugPrint('Buka kamera');
    };
    _controller.onFinished = () {
      // TODO: arahkan ke kuis / dialog selesai
      Navigator.of(context).pop();
    };
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
        final gestur = _controller.gestur;
        return Scaffold(
          backgroundColor: const Color(0xFFFCF9F8),
          body: SafeArea(
            child: Column(
              children: [
                IsiMateriHeader(onBack: _controller.goBack),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    children: [
                      GesturPreview(assetPath: gestur.assetPath),
                      const SizedBox(height: 12),
                      GesturDescriptionCard(gestur: gestur),
                      const SizedBox(height: 16),
                      LatihanProgressBar(gestur: gestur),
                    ],
                  ),
                ),
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
        );
      },
    );
  }
}