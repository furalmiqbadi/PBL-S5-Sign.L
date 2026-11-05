import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ============================================================
// Helper kecil
// ============================================================

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

Widget adminPage({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: const BackButton(color: AppColors.textPrimary),
      title: Text(title, style: AppTextStyles.headlineSmall),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(child: child),
      ],
    ),
  );
}

Widget itemCard({
  required Widget child,
  EdgeInsets margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
}) {
  return Container(
    margin: margin,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: child,
  );
}

Widget actionBtn(String label, Color color, VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: Size.zero,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label),
  );
}

// ============================================================
// 1. LAPORAN PENGGUNA
// ============================================================

class LaporanPenggunaPage extends StatelessWidget {
  const LaporanPenggunaPage({super.key});

  static final List<Map<String, String>> reports = [
    {
      'reporter': 'Rina Wulandari',
      'reported': 'Agus Prasetyo',
      'reason': 'Konten tidak pantas',
      'detail': 'Komentar mengandung kata kasar di diskusi huruf "R".',
      'time': '10 menit lalu',
    },
    {
      'reporter': 'Dina Safitri',
      'reported': 'UnknownUser99',
      'reason': 'Spam / promosi',
      'detail': 'Postingan yang sama diulang 5x di kategori Tanya Isyarat.',
      'time': '1 jam lalu',
    },
    {
      'reporter': 'Budi Santoso',
      'reported': 'Faiz Hidayat',
      'reason': 'Ujaran kebencian',
      'detail': 'Menghina komunitas Tuli di kolom komentar.',
      'time': '3 jam lalu',
    },
    {
      'reporter': 'Siti Rahma',
      'reported': 'Ayu Lestari',
      'reason': 'Informasi palsu',
      'detail': 'Membagikan jadwal event belajar palsu.',
      'time': 'Kemarin',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Laporan Pengguna',
      subtitle: '${reports.length} laporan menunggu ditinjau',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: reports.length,
        itemBuilder: (context, i) {
          final r = reports[i];
          return itemCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.pinkSoft,
                      child: Icon(Icons.person, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['reported']} dilaporkan oleh ${r['reporter']}',
                              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text(r['time']!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r['reason']!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(r['detail']!, style: AppTextStyles.bodySmall),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    actionBtn('Hapus Konten', AppColors.danger, () => toast(context, 'Konten dihapus')),
                    const SizedBox(width: 8),
                    actionBtn('Banned 7 Hari', AppColors.tertiary, () => toast(context, 'Pengguna dibanned 7 hari')),
                    const SizedBox(width: 8),
                    actionBtn('Abaikan', AppColors.textSecondary, () => toast(context, 'Laporan diabaikan')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 2. MODERASI CHAT
// ============================================================

class ModerasiChatPage extends StatelessWidget {
  const ModerasiChatPage({super.key});

  static final List<Map<String, String>> chats = [
    {
      'sender': 'Rizky Firmansyah',
      'receiver': 'Dewi Anggraini',
      'message': 'Kamu tuh gak pantes ada di komunitas ini, dasar ...',
      'time': '5 menit lalu',
      'flag': 'Ujaran kasar',
    },
    {
      'sender': 'SpamBot_22',
      'receiver': '12 pengguna',
      'message': 'JOIN GRUP WA DAPAT CUAN 500K/HARI!!! KLIK LINK...',
      'time': '45 menit lalu',
      'flag': 'Spam massal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Moderasi Chat',
      subtitle: '${chats.length} pesan dilaporkan pengguna',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: chats.length,
        itemBuilder: (context, i) {
          final c = chats[i];
          return itemCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${c['sender']} → ${c['receiver']}',
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Text(c['time']!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('"${c['message']}"', style: AppTextStyles.bodySmall),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag, size: 12, color: AppColors.danger),
                    const SizedBox(width: 4),
                    Text(c['flag']!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    actionBtn('Hapus Pesan', AppColors.danger, () => toast(context, 'Pesan dihapus')),
                    const SizedBox(width: 8),
                    actionBtn('Banned Permanen', AppColors.tertiary, () => toast(context, 'Pengguna dibanned permanen')),
                    const SizedBox(width: 8),
                    actionBtn('Abaikan', AppColors.textSecondary, () => toast(context, 'Laporan diabaikan')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 3. REVIEW VIDEO AI
// ============================================================

class ReviewVideoAIPage extends StatelessWidget {
  const ReviewVideoAIPage({super.key});

  static final List<Map<String, dynamic>> videos = [
    {'user': 'Dina Safitri', 'title': 'Deteksi Huruf D', 'score': 82.0, 'time': 'Hari ini'},
    {'user': 'Bagas Nugroho', 'title': 'Deteksi Huruf R', 'score': 67.0, 'time': 'Hari ini'},
    {'user': 'Laras Putri', 'title': 'Deteksi Kata "Terima Kasih"', 'score': 91.0, 'time': 'Kemarin'},
    {'user': 'Faiz Hidayat', 'title': 'Deteksi Angka 7', 'score': 74.0, 'time': 'Kemarin'},
    {'user': 'Yoga Saputra', 'title': 'Deteksi Huruf S', 'score': 58.0, 'time': '2 hari lalu'},
    {'user': 'Nadia Kirana', 'title': 'Deteksi Kata "Halo"', 'score': 88.0, 'time': '2 hari lalu'},
  ];

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Review Video AI',
      subtitle: '${videos.length} video menunggu persetujuan',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: videos.length,
        itemBuilder: (context, i) {
          final v = videos[i];
          final score = v['score'] as double;
          final scoreColor = score >= 80 ? AppColors.success : (score >= 70 ? AppColors.tertiary : AppColors.danger);
          return itemCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['title'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${v['user']} • ${v['time']}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('Akurasi AI: ${score.toStringAsFixed(0)}%',
                              style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => toast(context, 'Video disetujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Setujui', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    actionBtn('Tolak', AppColors.danger, () => toast(context, 'Video ditolak')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 4. MANAJEMEN PENGGUNA
// ============================================================

class ManajemenPenggunaPage extends StatefulWidget {
  const ManajemenPenggunaPage({super.key});

  @override
  State<ManajemenPenggunaPage> createState() => _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState extends State<ManajemenPenggunaPage> {
  static final List<Map<String, dynamic>> users = [
    {'name': 'Dina Safitri', 'role': 'Pembelajar', 'streak': 12, 'status': 'Aktif'},
    {'name': 'Budi Santoso', 'role': 'Pembelajar', 'streak': 30, 'status': 'Aktif'},
    {'name': 'Siti Rahma', 'role': 'Mentor Tuli', 'streak': 0, 'status': 'Aktif'},
    {'name': 'Agus Prasetyo', 'role': 'Pembelajar', 'streak': 3, 'status': 'Aktif'},
    {'name': 'SpamBot_22', 'role': 'Pembelajar', 'streak': 0, 'status': 'Dibanned'},
  ];

  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) => u['name'].toString().toLowerCase().contains(query.toLowerCase())).toList();
    return adminPage(
      context: context,
      title: 'Manajemen Pengguna',
      subtitle: '${users.length} pengguna terdaftar',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama pengguna...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final u = filtered[i];
                final banned = u['status'] == 'Dibanned';
                return itemCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: banned ? AppColors.surfaceMuted : AppColors.purpleSoft,
                        child: Text(u['name'][0],
                            style: TextStyle(
                                color: banned ? AppColors.textMuted : AppColors.secondary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '${u['role']} • Streak ${u['streak']} hari • ${u['status']}',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: banned ? AppColors.danger : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (!banned)
                        actionBtn('Banned', AppColors.danger, () => toast(context, '${u['name']} dibanned'))
                      else
                        actionBtn('Buka Banned', AppColors.success, () => toast(context, 'Banned dibuka')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. LEADERBOARD & POIN
// ============================================================

class LeaderboardPoinPage extends StatelessWidget {
  const LeaderboardPoinPage({super.key});

  static final List<Map<String, dynamic>> ranks = [
    {'rank': 1, 'name': 'Budi Santoso', 'points': 2450, 'suspicious': false},
    {'rank': 2, 'name': 'Dina Safitri', 'points': 2180, 'suspicious': false},
    {'rank': 3, 'name': 'Faiz Hidayat', 'points': 2105, 'suspicious': true},
    {'rank': 4, 'name': 'Laras Putri', 'points': 1890, 'suspicious': false},
    {'rank': 5, 'name': 'Yoga Saputra', 'points': 1740, 'suspicious': false},
  ];

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Leaderboard & Poin',
      subtitle: 'Kunci peringkat setiap Minggu 23:59 WIB',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: ranks.length,
        itemBuilder: (context, i) {
          final r = ranks[i];
          final medal = r['rank'] == 1
              ? Colors.amber
              : (r['rank'] == 2 ? Colors.grey : (r['rank'] == 3 ? Colors.brown : AppColors.surfaceMuted));
          return itemCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: medal,
                  child: Text('${r['rank']}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: r['rank'] <= 3 ? Colors.white : AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text('${r['points']} poin',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (r['suspicious'])
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Curiga curang',
                        style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                actionBtn('Reset Poin', AppColors.tertiary, () => toast(context, 'Poin ${r['name']} direset')),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 6. MANAGEMENT MATERI
// ============================================================

class ManagementMateriPage extends StatelessWidget {
  const ManagementMateriPage({super.key});

  static final List<Map<String, dynamic>> materi = [
    {'title': 'Alfabet & Angka', 'level': 'Bab 1 • Pemula', 'progress': 100},
    {'title': 'Kata Sehari-hari', 'level': 'Bab 2 • Pemula', 'progress': 100},
    {'title': 'Percakapan Dasar', 'level': 'Bab 3 • Menengah', 'progress': 80},
    {'title': 'Isyarat Keluarga', 'level': 'Bab 4 • Menengah', 'progress': 60},
    {'title': 'Ekspresi & Emosi', 'level': 'Bab 5 • Lanjutan', 'progress': 40},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Management Materi', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => toast(context, 'Form tambah materi (sambung backend)'),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Materi', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: materi.length,
        itemBuilder: (context, i) {
          final m = materi[i];
          return itemCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.pinkSoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.menu_book, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text(m['level'], style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    actionBtn('Edit', AppColors.primary, () => toast(context, 'Edit "${m['title']}"')),
                    const SizedBox(width: 6),
                    actionBtn('Hapus', AppColors.danger, () => toast(context, '"${m['title']}" dihapus')),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: m['progress'] / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 7. MANAGEMENT KUIS
// ============================================================

class ManagementKuisPage extends StatelessWidget {
  const ManagementKuisPage({super.key});

  static final List<Map<String, dynamic>> kuis = [
    {'title': 'Kuis Alfabet A-M', 'questions': 13, 'avg': 87.0},
    {'title': 'Kuis Alfabet N-Z', 'questions': 13, 'avg': 82.0},
    {'title': 'Kuis Angka 1-50', 'questions': 20, 'avg': 91.0},
    {'title': 'Kuis Kata Sehari-hari', 'questions': 15, 'avg': 74.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Management Kuis', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => toast(context, 'Form tambah kuis (sambung backend)'),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Kuis', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: kuis.length,
        itemBuilder: (context, i) {
          final k = kuis[i];
          return itemCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.purpleSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.assignment, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k['title'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text('${k['questions']} soal • Rata-rata skor ${k['avg'].toStringAsFixed(0)}%',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                actionBtn('Edit', AppColors.primary, () => toast(context, 'Edit "${k['title']}"')),
                const SizedBox(width: 6),
                actionBtn('Hapus', AppColors.danger, () => toast(context, '"${k['title']}" dihapus')),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 8. BROADCAST NOTIFIKASI
// ============================================================

class BroadcastNotifikasiPage extends StatefulWidget {
  const BroadcastNotifikasiPage({super.key});

  @override
  State<BroadcastNotifikasiPage> createState() => _BroadcastNotifikasiPageState();
}

class _BroadcastNotifikasiPageState extends State<BroadcastNotifikasiPage> {
  final title = TextEditingController();
  final body = TextEditingController();
  String target = 'Semua Pengguna';

  @override
  void dispose() { title.dispose(); body.dispose(); super.dispose(); }

  InputDecoration deco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Broadcast Notifikasi',
      subtitle: 'Pengumuman akan dikirim ke notifikasi aplikasi pengguna',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Target Penerima', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: target,
            decoration: deco(''),
            items: ['Semua Pengguna', 'Hanya Pembelajar', 'Hanya Mentor Tuli']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => target = v!),
          ),
          const SizedBox(height: 16),
          TextField(controller: title, decoration: deco('Judul pengumuman, cth. Maintenance Minggu Ini')),
          const SizedBox(height: 12),
          TextField(controller: body, maxLines: 5, decoration: deco('Isi pengumuman...')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
                  toast(context, 'Judul dan isi pengumuman wajib diisi');
                  return;
                }
                toast(context, 'Pengumuman terkirim ke $target (mock)');
              },
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Kirim Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 9. BANNER & PROMO
// ============================================================

class BannerPromoPage extends StatefulWidget {
  const BannerPromoPage({super.key});

  @override
  State<BannerPromoPage> createState() => _BannerPromoPageState();
}

class _BannerPromoPageState extends State<BannerPromoPage> {
  static final List<Map<String, dynamic>> banners = [
    {'title': 'Ragu dengan bentuk isyaratmu?', 'active': true},
    {'title': 'Event Temu Belajar Tebet Eco Park', 'active': true},
    {'title': 'Upgrade ke Sign.L Premium', 'active': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Banner & Promo', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => toast(context, 'Form tambah banner (sambung backend)'),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Banner', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: banners.length,
        itemBuilder: (context, i) {
          final b = banners[i];
          return itemCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.pinkSoft, AppColors.purpleSoft]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['title'], style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                      Text(b['active'] ? 'Aktif ditampilkan' : 'Nonaktif',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: b['active'] ? AppColors.success : AppColors.textMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: b['active'],
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => b['active'] = v),
                ),
                actionBtn('Hapus', AppColors.danger, () => toast(context, 'Banner dihapus')),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 10. LOG AKTIVITAS ADMIN
// ============================================================

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key});

  static final List<Map<String, String>> logs = [
    {'admin': 'Admin Utama', 'action': 'Menghapus 1 komentar dari Agus Prasetyo', 'time': 'Hari ini 14:20'},
    {'admin': 'Admin Utama', 'action': 'Menyetujui video AI milik Laras Putri', 'time': 'Hari ini 11:05'},
    {'admin': 'Moderator 2', 'action': 'Membanned SpamBot_22 permanen', 'time': 'Kemarin 20:44'},
    {'admin': 'Moderator 2', 'action': 'Mengirim broadcast "Event Tebet Eco Park"', 'time': 'Kemarin 09:12'},
    {'admin': 'Admin Utama', 'action': 'Mengedit materi "Percakapan Dasar"', 'time': '2 hari lalu'},
  ];

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Log Aktivitas Admin',
      subtitle: '${logs.length} aksi terakhir',
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: logs.length,
        itemBuilder: (context, i) {
          final l = logs[i];
          return itemCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l['admin']} — ${l['action']}', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 2),
                      Text(l['time']!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}