import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/modern_theme.dart';

class MateriModernPreview extends StatelessWidget {
  const MateriModernPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ModernTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Icon(Icons.arrow_back_ios_new, color: ModernTheme.textDark, size: 20),
          title: Text(
            "Pilih Materi",
            style: GoogleFonts.plusJakartaSans(
              color: ModernTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: ModernTheme.secondaryBlue,
                radius: 18,
                child: const Icon(Icons.search, color: ModernTheme.primaryBlue, size: 20),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryChip("Semua", true),
                  _buildCategoryChip("Dasar", false),
                  _buildCategoryChip("Kalimat", false),
                  _buildCategoryChip("Kuis", false),
                ],
              ),
              const SizedBox(height: 32),
              
              // List Materi
              _buildMateriItem(
                "Abjad Isyarat A-Z",
                "24 dari 26 huruf dikuasai",
                Icons.sort_by_alpha_rounded,
                0.92,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildMateriItem(
                "Angka 1-20",
                "5 dari 20 materi",
                Icons.numbers_rounded,
                0.25,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildMateriItem(
                "Perkenalan Diri",
                "Belum dimulai",
                Icons.person_search_rounded,
                0.0,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              _buildMateriItem(
                "Ekspresi Wajah",
                "Belum dimulai",
                Icons.face_retouching_natural_rounded,
                0.0,
                Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? ModernTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [] : ModernTheme.softShadow,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : ModernTheme.textGray,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMateriItem(String title, String sub, IconData icon, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ModernTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(color: ModernTheme.textGray, fontSize: 13),
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: ModernTheme.textGray, size: 16),
        ],
      ),
    );
  }
}
