import 'package:flutter/material.dart';
import '../../controllers/detail_materi_controller.dart';
import '../widgets/detail_header.dart';
import '../widgets/materi_card.dart';
import '../widgets/final_exam_card.dart';
import '../home/isi_materi_page.dart';

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
          backgroundColor: const Color(0xFFFCF9F8),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),
                _buildModuleInfo(),
                const SizedBox(height: 24),
                _buildSectionA(),
                const SizedBox(height: 20),
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
      // start: panah sejajar dengan baris "Detail Materi", bukan di tengah
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1C1B1B),
          ),
          tooltip: 'Kembali',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
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
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1C1B1B),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFFFFD9E2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Text(
              'MODUL DASAR',
              style: TextStyle(
                color: Color(0xFF3E001D),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kuasai 26 gestur ejaan jari alfabet bahasa isyarat & verifikasi langsung kelenturan lekuk jarimu via panduan kamera AI real-time.',
            style: TextStyle(
              color: Color(0xFF594047),
              fontSize: 14,
              height: 1.63,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn(
                  'Total Materi', '5 Sesi', const Color(0xFF1C1B1B)),
              _buildInfoColumn('Latihan AI', 'Aktif', const Color(0xFFB5005F)),
              _buildInfoColumn(
                  'Kelulusan', 'Tes Refleks', const Color(0xFF964900)),
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
          style: const TextStyle(
            color: Color(0xFF594047),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
          const Color(0xFFB5005F),
          trailing: Text(
            '${_controller.completedMateri} dari ${_controller.totalMateri} Selesai',
            style: const TextStyle(
              color: Color(0xFF594047),
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
                if (materi.isLocked) return; // materi terkunci tidak bisa dibuka
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
        _sectionTitle('B. Ujian Akhir Bab 1', const Color(0xFF8D6F77)),
        const SizedBox(height: 12),
        const FinalExamCard(),
      ],
    );
  }
}