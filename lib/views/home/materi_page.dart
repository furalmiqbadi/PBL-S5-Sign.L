import 'package:flutter/material.dart';
import '../../controllers/materi_controller.dart';
import '../widgets/filter_chips.dart';
import '../widgets/current_progress_card.dart';
import '../widgets/bab_card.dart';
import '../widgets/target_card.dart';
import 'detail_materi_page.dart';

/// Konten tab Materi: filter, progres saat ini, daftar bab, dan target belajar.
///
/// Widget ini hanya berisi konten (tanpa AppBar maupun bottom navigation)
/// karena header dan navbar disediakan oleh `MainShell`.
class MateriPage extends StatefulWidget {
  const MateriPage({super.key});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  final MateriController _controller = MateriController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            FilterChips(
              currentFilter: _controller.currentFilter,
              onFilterChanged: _controller.setFilter,
            ),
            const SizedBox(height: 24),
            CurrentProgressCard(bab: _controller.currentBab!),
            const SizedBox(height: 24),
            ..._controller.filteredBabList.map((bab) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BabCard(
                    bab: bab,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DetailMateriPage(),
                        ),
                      );
                    },
                  ),
                )),
            const SizedBox(height: 8),
            TargetCard(
              completedBab: _controller.completedBab,
              totalBab: _controller.totalBab,
            ),
          ],
        );
      },
    );
  }
}
