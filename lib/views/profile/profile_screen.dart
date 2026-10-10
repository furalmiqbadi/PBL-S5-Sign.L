import 'package:flutter/material.dart';
import '../edit/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildSectionTitle(
            icon: Icons.military_tech_rounded,
            title: 'Pencapaian Unggulan',
            iconColor: const Color(0xFFC40083),
            trailing: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0ECF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Color(0xFF826D80)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementsRow(),
          const SizedBox(height: 32),
          _buildSectionTitle(
            icon: Icons.school_rounded,
            title: 'Modul & Progres Isyarat',
            iconColor: const Color(0xFFC40083),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '4 Modul',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF826D80),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildModuleCard(
            iconWidget: const Stack(
              alignment: Alignment.bottomRight,
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 2.0, right: 2.0),
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC40083),
                    ),
                  ),
                ),
                Icon(Icons.check, size: 12, color: Color(0xFFC40083)),
              ],
            ),
            title: 'Alfabet (A - Z)',
            subtitle: '26 Huruf Dasar • Selesai',
            percentText: '100%',
            progressValue: 1.0,
            progressColor: const Color(0xFFC40083),
            iconBgColor: const Color(0xFFF9E6F2),
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '123',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7E57C2),
                ),
              ),
            ),
            title: 'Angka & Bilangan',
            subtitle: '0 - 100 & Satuan • 15/20 Pelajaran',
            percentText: '75%',
            progressValue: 0.75,
            progressColor: const Color(0xFF7E57C2),
            iconBgColor: const Color(0xFFF2E6F9),
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: const Icon(
              Icons.back_hand_rounded,
              color: Color(0xFFCA7629),
              size: 20,
            ),
            title: 'Sapaan & Percakapan Dasar',
            subtitle: 'Halo, Terima Kasih, Maaf • 8/20 Pelajaran',
            percentText: '40%',
            progressValue: 0.40,
            progressColor: const Color(0xFFCA7629),
            iconBgColor: const Color(0xFFF9EFE6),
          ),
          const SizedBox(height: 12),
          _buildModuleCard(
            iconWidget: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: Color(0xFF64B5F6),
              size: 22,
            ),
            title: 'Ekspresi Wajah & Emosi',
            subtitle: 'Gramatika Visual Non-Manual • 3/20 Pelajaran',
            percentText: '15%',
            progressValue: 0.15,
            progressColor: const Color(0xFF64B5F6),
            iconBgColor: const Color(0xFFE6F2F9),
          ),
          const SizedBox(height: 24), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=47'),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Sarah Chen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF302036),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '@sarah.creates',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF826D80),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF302036),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAchievementsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAchievementCard(
          icon: Icons.stars_rounded,
          iconBg: const Color(0xFF201625),
          iconColor: Colors.white,
          title: 'Perfect 100',
          subtitle: '100% Akurasi',
          subtitleColor: const Color(0xFFC40083),
        ),
        _buildAchievementCard(
          icon: Icons.local_fire_department_rounded,
          iconBg: const Color(0xFF201625),
          iconColor: const Color(0xFFFF9800),
          title: '7-Day Streak',
          subtitle: '7 Hari Beruntun',
          subtitleColor: const Color(0xFFCA7629),
        ),
        _buildAchievementCard(
          icon: Icons.bolt_rounded,
          iconBg: const Color(0xFF201625),
          iconColor: const Color(0xFFCE93D8),
          title: 'Fast Signer',
          subtitle: '<1.2s Respons',
          subtitleColor: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0ECF4), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF302036),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required String percentText,
    required double progressValue,
    required Color progressColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECF4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: iconWidget,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF302036),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF826D80),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0ECF4),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
