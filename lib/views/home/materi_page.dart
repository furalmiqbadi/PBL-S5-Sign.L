import 'package:flutter/material.dart';

import '../../controllers/materi_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_ui.dart';
import '../widgets/bab_card.dart';
import '../widgets/current_progress_card.dart';
import '../widgets/filter_chips.dart';
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
  late final MateriController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MateriController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bukaDetail(String materiId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailMateriPage(materiId: materiId)),
    );
    if (mounted) _controller.load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final babList = _controller.filteredBabList;
        final currentBab = _controller.currentBab;

        return RefreshIndicator(
          onRefresh: () => _controller.load(force: true),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              AppBottomNavBar.reservedSpace(context) + 16,
            ),
            children: [
              FilterChips(
                currentFilter: _controller.currentFilter,
                onFilterChanged: _controller.setFilter,
              ),
              const SizedBox(height: 24),
              if (_controller.hasError)
                _buildPesan(
                  icon: Icons.cloud_off_rounded,
                  title: 'Gagal memuat materi',
                  message: _controller.errorMessage!,
                  onRetry: () => _controller.load(force: true),
                )
              else if (_controller.isEmpty)
                _buildPesan(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum ada materi',
                  message:
                      'Admin belum menambahkan materi. Silakan cek kembali nanti.',
                  onRetry: () => _controller.load(force: true),
                )
              else ...[
                if (currentBab != null) ...[
                  CurrentProgressCard(
                    bab: currentBab,
                    onTap: () => _bukaDetail(currentBab.id),
                  ),
                  const SizedBox(height: 24),
                ],
                if (babList.isEmpty)
                  _buildPesan(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'Tidak ada bab',
                    message: 'Belum ada bab yang cocok dengan filter ini.',
                    onRetry: () => _controller.setFilter(FilterType.all),
                    retryLabel: 'Tampilkan semua',
                  )
                else
                  ...babList.map(
                    (bab) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BabCard(
                        bab: bab,
                        onTap: () => _bukaDetail(bab.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TargetCard(
                  completedBab: _controller.completedBab,
                  totalBab: _controller.totalBab,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPesan({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
    String retryLabel = 'Muat ulang',
  }) {
    return AppCard(
      child: Column(
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
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
