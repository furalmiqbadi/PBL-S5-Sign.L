import 'package:flutter/material.dart';

import '../../services/leaderboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Membuka papan peringkat (layar penuh).
Future<void> openLeaderboard(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
  );
}

/// Nama lama, dipertahankan supaya home_page.dart dan komunitas_header.dart
/// tidak perlu diubah. Isinya sekarang membuka layar penuh.
Future<void> showLeaderboardSheet(BuildContext context) =>
    openLeaderboard(context);

enum _Period { week, month, all }

const Map<_Period, String> _periodLabels = {
  _Period.week: 'Pekan Ini',
  _Period.month: 'Bulan Ini',
  _Period.all: 'Sepanjang Waktu',
};

class _Entry {
  final String name;
  final Map<_Period, int> xp;
  final bool isMe;

  const _Entry(this.name, this.xp, {this.isMe = false});
}

/// Data dummy. Ganti dengan data backend nanti.
const List<_Entry> _entries = [
  _Entry('Budi Santoso',
      {_Period.week: 1420, _Period.month: 4820, _Period.all: 17250}),
  _Entry('Dina S.',
      {_Period.week: 1280, _Period.month: 4510, _Period.all: 18400}),
  _Entry('Sarah Chen',
      {_Period.week: 1150, _Period.month: 4120, _Period.all: 12800}),
  _Entry('Kamu',
      {_Period.week: 980, _Period.month: 3650, _Period.all: 9800},
      isMe: true),
  _Entry('Ahmad Fauzi',
      {_Period.week: 870, _Period.month: 3380, _Period.all: 11900}),
  _Entry('Larasati',
      {_Period.week: 760, _Period.month: 2960, _Period.all: 14100}),
  _Entry('Rian Pratama',
      {_Period.week: 690, _Period.month: 2540, _Period.all: 8700}),
  _Entry('Maya Putri',
      {_Period.week: 540, _Period.month: 2210, _Period.all: 6900}),
  _Entry('Tania Octavia',
      {_Period.week: 430, _Period.month: 1750, _Period.all: 4100}),
  _Entry('Hendra Wijaya',
      {_Period.week: 360, _Period.month: 1420, _Period.all: 5200}),
];

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _service = LeaderboardService();
  _Period _period = _Period.week;
  List<_Entry> _currentEntries = _entries;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final users = await _service.getLeaderboard(limit: 20);
      if (mounted && users.isNotEmpty) {
        setState(() {
          _currentEntries = users.map((u) {
            final xp = u.xp > 0 ? u.xp : (u.points > 0 ? u.points : 50);
            return _Entry(
              u.name,
              {
                _Period.week: xp,
                _Period.month: xp * 3,
                _Period.all: xp * 10,
              },
              isMe: u.isMe,
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  List<_Entry> get _sorted {
    final list = [..._currentEntries];
    list.sort((a, b) => (b.xp[_period] ?? 0).compareTo(a.xp[_period] ?? 0));
    return list;
  }

  int _xpOf(_Entry e) => e.xp[_period] ?? 0;

  /// 1280 -> "1.280"
  String _formatXp(int xp) {
    final s = xp.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Papan Peringkat',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          _buildPeriodChips(),
          const SizedBox(height: 28),
          _buildPodium(top3),
          const SizedBox(height: 28),
          _buildRankCard(rest),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Peringkat diperbarui setiap hari pada pukul 00.00.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FILTER PERIODE ----------------

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _Period.values.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  _periodLabels[p]!,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- PODIUM TOP 3 ----------------

  Widget _buildPodium(List<_Entry> top3) {
    if (top3.length < 3) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _podiumItem(top3[1], 2)),
          const SizedBox(width: 8),
          Expanded(child: _podiumItem(top3[0], 1)),
          const SizedBox(width: 8),
          Expanded(child: _podiumItem(top3[2], 3)),
        ],
      ),
    );
  }

  Widget _podiumItem(_Entry e, int rank) {
    final first = rank == 1;
    final blockHeight = first ? 130.0 : (rank == 2 ? 98.0 : 82.0);
    final radius = first ? 36.0 : 30.0;
    final ringColor = first ? AppColors.tertiary : AppColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: e.isMe ? AppColors.primary : AppColors.purpleSoft,
            child: Icon(
              Icons.person,
              size: radius * 0.85,
              color: e.isMe ? AppColors.textOnPrimary : AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          e.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 16, color: AppColors.secondary),
            Flexible(
              child: Text(
                '${_formatXp(_xpOf(e))} XP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: blockHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: first
                ? LinearGradient(
                    colors: [AppColors.tertiary, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [AppColors.pinkSoft, AppColors.purpleSoft],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: first ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- DAFTAR PERINGKAT 4 DST --------------

  Widget _buildRankCard(List<_Entry> rest) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            for (int i = 0; i < rest.length; i++) ...[
              _buildRow(rest[i], i + 4),
              if (i < rest.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 60,
                  endIndent: 16,
                  color: AppColors.border,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_Entry e, int rank) {
    final me = e.isMe;
    return Container(
      color: me ? AppColors.pinkSoft.withValues(alpha: 0.3) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: me ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: me ? AppColors.primary : AppColors.purpleSoft,
            child: Icon(
              Icons.person,
              size: 20,
              color: me ? AppColors.textOnPrimary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: me ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (me) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Kamu',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.bolt,
            size: 16,
            color: me ? AppColors.primary : AppColors.secondary,
          ),
          Text(
            '${_formatXp(_xpOf(e))} XP',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: me ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}