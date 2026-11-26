import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/modern_theme.dart';

class HomeModernPreview extends StatelessWidget {
  const HomeModernPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ModernTheme.light,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Halo,", style: TextStyle(color: ModernTheme.textGray, fontSize: 16)),
                        Text(
                          "Alex Morgan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: ModernTheme.softShadow,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: ModernTheme.textDark),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                
                // Card Utama (Dropbox style in image)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: ModernTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text("🔥 5 Day Streak", style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Progress Belajar",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Dasar Abjad A-Z",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      const Text("65% Selesai", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text(
                  "Materi Selanjutnya",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ModernTheme.textDark),
                ),
                const SizedBox(height: 16),
                
                // Grid Materi Preview
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMaterialCard("Huruf Isyarat", Icons.front_hand_outlined, "8 Materi", context),
                    _buildMaterialCard("Angka 1-10", Icons.numbers_rounded, "5 Materi", context),
                    _buildMaterialCard("Kata Dasar", Icons.text_fields_rounded, "12 Materi", context),
                    _buildMaterialCard("Kalimat Umum", Icons.forum_outlined, "10 Materi", context),
                  ],
                ),
                const SizedBox(height: 100), // Bottom nav space
              ],
            ),
          ),
        ),
        // Floating Bottom Nav Preview
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: ModernTheme.textDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ModernTheme.softShadow,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.home_filled, color: Colors.white),
              Icon(Icons.book_outlined, color: Colors.white54),
              Icon(Icons.camera_alt_outlined, color: Colors.white54),
              Icon(Icons.person_outline, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(String title, IconData icon, String subtitle, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ModernTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.secondaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ModernTheme.primaryBlue, size: 24),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: ModernTheme.textGray, fontSize: 12)),
        ],
      ),
    );
  }
}
