import 'package:flutter/material.dart';
import '../../controllers/materi_controller.dart';
import '../../models/bab_model.dart';
import '../widgets/filter_chips.dart';       
import '../widgets/current_progress_card.dart'; 
import '../widgets/bab_card.dart';            
import '../widgets/target_card.dart';   
import 'detail_materi_page.dart';      

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
        return Scaffold(
          backgroundColor: const Color(0xFFFCF9F8),
          appBar: _buildAppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
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
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFCF9F8),
      elevation: 0,
      title: const Text(
        'Materi',
        style: TextStyle(
          color: Color(0xFF1C1B1B),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        _buildStatChip('🔥', '7', const Color(0xFFEA580C)),
        const SizedBox(width: 8),
        _buildStatChip('❤️', '5', const Color(0xFFE11D48)),
        const SizedBox(width: 8),
        _buildStatChip('💎', '420', const Color(0xFF8639B4)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatChip(String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F8),
        border: Border(top: BorderSide(color: Color(0xFFE0BEC6), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home_outlined), onPressed: () {}),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, color: Color(0xFFB5005F)),
              Text('Materi', style: TextStyle(color: Color(0xFFB5005F), fontSize: 10)),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDD2A7B).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          IconButton(icon: const Icon(Icons.people_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
    );
  }
}