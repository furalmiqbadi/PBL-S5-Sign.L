import 'package:flutter/material.dart';
import '../../controllers/detail_materi_controller.dart';
import '../widgets/detail_header.dart';
import '../widgets/materi_card.dart';
import '../widgets/quiz_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../home/isi_materi_page.dart';
import '../home/quiz_page.dart';

class DetailMateriPage extends StatefulWidget {
  const DetailMateriPage({super.key});

  @override
  State<DetailMateriPage> createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  final DetailMateriController _controller = DetailMateriController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bukaIsiMateri(int materiId, {int startIndex = 0, String? startHuruf}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsiMateriPage(
          materiId: materiId,
          startIndex: startIndex,
          startHuruf: startHuruf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),
                _buildModuleInfo(),
                const SizedBox(height: 24),
                _buildSectionA(),
                const SizedBox(height: 24),
                _buildSectionB(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Kembali',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        const SizedBox(width: 4),
        const Expanded(child: DetailHeader()),
      ],
    );
  }

  Widget _sectionTitle(String text, Color dotColor, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildModuleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'MODUL DASAR',
              style: AppTextStyles.labelXSmall.copyWith(
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kuasai 26 gestur ejaan jari alfabet bahasa isyarat & verifikasi langsung kelenturan lekuk jarimu via panduan kamera AI real-time.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.63,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn('Total Materi', '5 Sesi', AppColors.textPrimary),
              _buildInfoColumn('Latihan AI', 'Aktif', AppColors.primary),
              _buildInfoColumn('Kelulusan', 'Tes Refleks', AppColors.tertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelXSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'A. Ejaan Alfabet Tangan',
          AppColors.primary,
          trailing: Text(
            '${_controller.completedMateri} dari ${_controller.totalMateri} Selesai',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._controller.materiList.map(
          (materi) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MateriCard(
              materi: materi,
              onTap: () {
                if (materi.isLocked) return;
                _controller.continueLearning(materi.id);
                _bukaIsiMateri(materi.id);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionB() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'B. Ujian Akhir Bab 1',
          AppColors.textMuted,
          trailing: Text(
            'Siap Dimulai',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        QuizCard(
          onStartQuiz: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizPage()),
            );
          },
        ),
      ],
    );
  }
}