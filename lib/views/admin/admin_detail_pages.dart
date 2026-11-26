import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
// 3. MANAJEMEN PENGGUNA
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
// 4. LEADERBOARD & POIN
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
// 5. MANAGEMENT MATERI (TERSAMBUNG KE SUPABASE)
//    Tingkat 1: Materi (cth. Abjad BISINDO A-Z)
//    Tombol "Isi" -> BabMateriPage
// ============================================================

class ManagementMateriPage extends StatefulWidget {
  const ManagementMateriPage({super.key});

  @override
  State<ManagementMateriPage> createState() => _ManagementMateriPageState();
}

class _ManagementMateriPageState extends State<ManagementMateriPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _materi = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db.from('materi').select().order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _materi = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat materi.';
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final judul = TextEditingController(text: existing?['judul'] ?? '');
    final deskripsi = TextEditingController(text: existing?['deskripsi'] ?? '');
    final urutan = TextEditingController(
      text: '${existing?['urutan'] ?? _materi.length + 1}',
    );
    bool terbit = existing?['is_published'] ?? true;
    String? err;
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Tambah Materi' : 'Edit Materi',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: judul,
                      decoration: const InputDecoration(labelText: 'Judul materi'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deskripsi,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urutan,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Urutan'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tampilkan ke pengguna'),
                      value: terbit,
                      onChanged: (v) => setModal(() => terbit = v),
                    ),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(err!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                final j = judul.text.trim();
                                final u = int.tryParse(urutan.text.trim());
                                if (j.isEmpty) {
                                  setModal(() => err = 'Judul wajib diisi');
                                  return;
                                }
                                if (u == null) {
                                  setModal(() => err = 'Urutan harus berupa angka');
                                  return;
                                }
                                setModal(() {
                                  saving = true;
                                  err = null;
                                });
                                final d = deskripsi.text.trim();
                                final payload = {
                                  'judul': j,
                                  'deskripsi': d.isEmpty ? null : d,
                                  'urutan': u,
                                  'is_published': terbit,
                                };
                                try {
                                  if (existing == null) {
                                    await _db.from('materi').insert(payload);
                                  } else {
                                    final res = await _db
                                        .from('materi')
                                        .update(payload)
                                        .eq('id', existing['id'])
                                        .select();
                                    if (res.isEmpty) throw Exception('ditolak');
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  setModal(() {
                                    saving = false;
                                    err = 'Gagal menyimpan. Cek izin admin (RLS) di Supabase.';
                                  });
                                }
                              },
                        child: Text(
                          saving ? 'Menyimpan...' : 'Simpan',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      if (!mounted) return;
      toast(context, existing == null ? 'Materi ditambahkan' : 'Materi diperbarui');
      _load();
    }
  }

  Future<void> _hapus(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus materi?'),
        content: Text('"${m['judul']}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await _db.from('materi').delete().eq('id', m['id']).select();
      if (res.isEmpty) throw Exception('ditolak');
      if (!mounted) return;
      toast(context, '"${m['judul']}" dihapus');
      _load();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      toast(
        context,
        e.code == '23503'
            ? 'Tidak bisa dihapus: masih ada kuis atau isi materi yang terkait.'
            : 'Gagal menghapus: ${e.message}',
      );
    } catch (_) {
      if (!mounted) return;
      toast(context, 'Gagal menghapus. Cek izin admin di Supabase.');
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_materi.isEmpty) {
      return const Center(child: Text('Belum ada materi. Tekan "Tambah Materi".'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _materi.length,
        itemBuilder: (context, i) {
          final m = _materi[i];
          final terbit = m['is_published'] == true;
          return itemCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['judul'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Urutan ${m['urutan']} • ${terbit ? 'Terbit' : 'Draft'}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: terbit ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                actionBtn('Isi', AppColors.secondary, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BabMateriPage(materi: m)),
                  );
                }),
                const SizedBox(width: 6),
                actionBtn('Edit', AppColors.primary, () => _showForm(existing: m)),
                const SizedBox(width: 6),
                actionBtn('Hapus', AppColors.danger, () => _hapus(m)),
              ],
            ),
          );
        },
      ),
    );
  }

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
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Materi', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// BAB MATERI (tabel bab_materi)
//    Tingkat 2: Bab di dalam materi (cth. A-E, F-J, K-O ...)
//    Tombol "Isi" -> IsiMateriPage
// ============================================================

class BabMateriPage extends StatefulWidget {
  const BabMateriPage({super.key, required this.materi});

  final Map<String, dynamic> materi;

  @override
  State<BabMateriPage> createState() => _BabMateriPageState();
}

class _BabMateriPageState extends State<BabMateriPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _bab = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db
          .from('bab_materi')
          .select()
          .eq('materi_id', widget.materi['id'])
          .order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _bab = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat bab: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat bab. Pastikan tabel bab_materi sudah dibuat.';
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final judul = TextEditingController(text: existing?['judul'] ?? '');
    final deskripsi = TextEditingController(text: existing?['deskripsi'] ?? '');
    final berikutnya = _bab.isEmpty ? 1 : ((_bab.last['urutan'] as num).toInt() + 1);
    final urutan = TextEditingController(text: '${existing?['urutan'] ?? berikutnya}');
    String? err;
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> simpan() async {
              final j = judul.text.trim();
              final u = int.tryParse(urutan.text.trim());
              if (j.isEmpty) {
                setModal(() => err = 'Nama bab wajib diisi');
                return;
              }
              if (u == null) {
                setModal(() => err = 'Urutan harus berupa angka');
                return;
              }
              setModal(() {
                saving = true;
                err = null;
              });
              final d = deskripsi.text.trim();
              final payload = {
                'materi_id': widget.materi['id'],
                'judul': j,
                'deskripsi': d.isEmpty ? null : d,
                'urutan': u,
              };
              try {
                if (existing == null) {
                  await _db.from('bab_materi').insert(payload);
                } else {
                  final res = await _db
                      .from('bab_materi')
                      .update(payload)
                      .eq('id', existing['id'])
                      .select();
                  if (res.isEmpty) throw Exception('ditolak');
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                debugPrint('Gagal menyimpan bab: $e');
                if (!ctx.mounted) return;
                setModal(() {
                  saving = false;
                  err = 'Gagal menyimpan. Cek tabel dan izin admin (RLS) di Supabase.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Tambah Bab' : 'Edit Bab',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: judul,
                      decoration: const InputDecoration(labelText: 'Nama bab, cth. A-E'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deskripsi,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urutan,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Urutan'),
                    ),
                    const SizedBox(height: 12),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(err!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: saving ? null : simpan,
                        child: Text(
                          saving ? 'Menyimpan...' : 'Simpan',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      toast(context, existing == null ? 'Bab ditambahkan' : 'Bab diperbarui');
      _load();
    }
  }

  Future<void> _hapus(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bab?'),
        content: Text(
            'Bab "${b['judul']}" beserta SEMUA isinya (huruf, gambar, penjelasan) akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await _db.from('bab_materi').delete().eq('id', b['id']).select();
      if (res.isEmpty) throw Exception('ditolak');
      if (!mounted) return;
      toast(context, 'Bab "${b['judul']}" dihapus');
      _load();
    } catch (e) {
      debugPrint('Gagal menghapus bab: $e');
      if (!mounted) return;
      toast(context, 'Gagal menghapus. Cek izin admin di Supabase.');
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (_bab.isEmpty) {
      return const Center(child: Text('Belum ada bab. Tekan "Tambah Bab".'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _bab.length,
        itemBuilder: (context, i) {
          final b = _bab[i];
          final desk = (b['deskripsi'] ?? '').toString();
          return itemCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_outlined, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b['judul'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        desk.isEmpty ? 'Urutan ${b['urutan']}' : 'Urutan ${b['urutan']} • $desk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                actionBtn('Isi', AppColors.secondary, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IsiMateriPage(materi: widget.materi, bab: b),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                actionBtn('Edit', AppColors.primary, () => _showForm(existing: b)),
                const SizedBox(width: 6),
                actionBtn('Hapus', AppColors.danger, () => _hapus(b)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(widget.materi['judul'] ?? 'Bab Materi',
            style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _loading ? null : () => _showForm(),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Bab', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// ISI MATERI (tabel isi_materi)
//    Tingkat 3: Huruf/gerakan di dalam sebuah bab
//    (judul, gambar, penjelasan)
// ============================================================

class IsiMateriPage extends StatefulWidget {
  const IsiMateriPage({super.key, required this.materi, required this.bab});

  final Map<String, dynamic> materi;
  final Map<String, dynamic> bab;

  @override
  State<IsiMateriPage> createState() => _IsiMateriPageState();
}

class _IsiMateriPageState extends State<IsiMateriPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _isi = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db
          .from('isi_materi')
          .select()
          .eq('bab_id', widget.bab['id'])
          .order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _isi = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat isi materi: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat isi materi. Pastikan kolom bab_id sudah ditambahkan.';
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    // Urutan baru = urutan terbesar di bab ini + 1
    final berikutnya =
        _isi.isEmpty ? 1 : ((_isi.last['urutan'] as num).toInt() + 1);
    final judul = TextEditingController(text: existing?['judul'] ?? '');
    final deskripsi = TextEditingController(text: existing?['deskripsi'] ?? '');
    final gambar = TextEditingController(text: existing?['gambar_url'] ?? '');
    final urutan = TextEditingController(text: '${existing?['urutan'] ?? berikutnya}');
    String? err;
    bool saving = false;
    bool uploading = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            // Pilih file, upload ke Storage, lalu isi link otomatis
            Future<void> pilihGambar() async {
              setModal(() {
                uploading = true;
                err = null;
              });
              try {
                final file = await ImagePicker()
                    .pickImage(source: ImageSource.gallery);
                if (file == null) {
                  if (ctx.mounted) setModal(() => uploading = false);
                  return;
                }
                const tipe = {
                  'jpg': 'image/jpeg',
                  'jpeg': 'image/jpeg',
                  'png': 'image/png',
                  'gif': 'image/gif',
                  'webp': 'image/webp',
                };
                final ext = file.name.split('.').last.toLowerCase();
                final bytes = await file.readAsBytes();
                String? pesan;
                if (!tipe.containsKey(ext)) {
                  pesan = 'Format harus JPG, PNG, GIF, atau WEBP';
                } else if (bytes.length > 5 * 1024 * 1024) {
                  pesan = 'Ukuran gambar maksimal 5 MB';
                }
                if (pesan != null) {
                  if (ctx.mounted) {
                    setModal(() {
                      uploading = false;
                      err = pesan;
                    });
                  }
                  return;
                }
                final path = 'isi/${DateTime.now().microsecondsSinceEpoch}.$ext';
                final bucket = _db.storage.from('materi');
                await bucket.uploadBinary(
                  path,
                  bytes,
                  fileOptions: FileOptions(contentType: tipe[ext]),
                );
                if (!ctx.mounted) return;
                setModal(() {
                  gambar.text = bucket.getPublicUrl(path);
                  uploading = false;
                });
              } catch (e) {
                debugPrint('Gagal upload gambar: $e');
                if (!ctx.mounted) return;
                setModal(() {
                  uploading = false;
                  err = 'Gagal upload. Cek bucket dan izin Storage di Supabase.';
                });
              }
            }

            Future<void> simpan() async {
              final j = judul.text.trim();
              final u = int.tryParse(urutan.text.trim());
              if (j.isEmpty) {
                setModal(() => err = 'Judul wajib diisi');
                return;
              }
              if (u == null) {
                setModal(() => err = 'Urutan harus berupa angka');
                return;
              }
              setModal(() {
                saving = true;
                err = null;
              });
              final d = deskripsi.text.trim();
              final g = gambar.text.trim();
              final payload = {
                'materi_id': widget.materi['id'],
                'bab_id': widget.bab['id'],
                'judul': j,
                'deskripsi': d.isEmpty ? null : d,
                'gambar_url': g.isEmpty ? null : g,
                'urutan': u,
              };
              try {
                if (existing == null) {
                  await _db.from('isi_materi').insert(payload);
                } else {
                  final res = await _db
                      .from('isi_materi')
                      .update(payload)
                      .eq('id', existing['id'])
                      .select();
                  if (res.isEmpty) throw Exception('ditolak');
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                debugPrint('Gagal menyimpan isi materi: $e');
                if (!ctx.mounted) return;
                setModal(() {
                  saving = false;
                  err = 'Gagal menyimpan. Cek izin admin (RLS) di Supabase.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Tambah Isi' : 'Edit Isi',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: judul,
                      decoration: const InputDecoration(labelText: 'Judul, cth. Huruf A'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deskripsi,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Penjelasan gerakan (opsional)'),
                    ),
                    const SizedBox(height: 12),
                    if (gambar.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(
                          gambar.text,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('Gambar tidak bisa ditampilkan'),
                        ),
                      ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: uploading || saving ? null : pilihGambar,
                          icon: const Icon(Icons.upload),
                          label: Text(uploading ? 'Mengupload...' : 'Pilih Gambar'),
                        ),
                        if (gambar.text.isNotEmpty)
                          TextButton(
                            onPressed: uploading || saving
                                ? null
                                : () => setModal(() => gambar.clear()),
                            child: const Text('Hapus gambar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urutan,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Urutan'),
                    ),
                    const SizedBox(height: 12),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(err!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: saving || uploading ? null : simpan,
                        child: Text(
                          saving ? 'Menyimpan...' : 'Simpan',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      toast(context, existing == null ? 'Isi ditambahkan' : 'Isi diperbarui');
      _load();
    }
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus isi materi?'),
        content: Text('"${item['judul'] ?? ''}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await _db.from('isi_materi').delete().eq('id', item['id']).select();
      if (res.isEmpty) throw Exception('ditolak');
      if (!mounted) return;
      toast(context, 'Isi dihapus');
      _load();
    } catch (e) {
      debugPrint('Gagal menghapus isi materi: $e');
      if (!mounted) return;
      toast(context, 'Gagal menghapus. Cek izin admin di Supabase.');
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (_isi.isEmpty) {
      return const Center(child: Text('Belum ada isi. Tekan "Tambah Isi".'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _isi.length,
      itemBuilder: (context, i) {
        final item = _isi[i];
        final url = (item['gambar_url'] ?? '').toString();
        return itemCard(
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: url.isEmpty
                    ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['judul'] ?? '(tanpa judul)',
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Urutan ${item['urutan']} • ${item['deskripsi'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              actionBtn('Edit', AppColors.primary, () => _showForm(existing: item)),
              const SizedBox(width: 6),
              actionBtn('Hapus', AppColors.danger, () => _hapus(item)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('${widget.bab['judul'] ?? ''}',
            style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _loading || _error != null ? null : () => _showForm(),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Isi', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// 6. MANAGEMENT KUIS
// ============================================================

class ManagementKuisPage extends StatefulWidget {
  const ManagementKuisPage({super.key});

  @override
  State<ManagementKuisPage> createState() => _ManagementKuisPageState();
}

class _ManagementKuisPageState extends State<ManagementKuisPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _kuis = [];
  List<Map<String, dynamic>> _materi = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db
          .from('kuis')
          .select('*, soal(count)')
          .order('created_at', ascending: true);
      final materi = await _db
          .from('materi')
          .select('id, judul')
          .order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _kuis = List<Map<String, dynamic>>.from(data);
        _materi = List<Map<String, dynamic>>.from(materi);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat kuis: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat kuis.';
        _loading = false;
      });
    }
  }

  int _jumlahSoal(Map<String, dynamic> k) {
    final s = k['soal'];
    if (s is List && s.isNotEmpty && s.first is Map) {
      return ((s.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  String? _judulMateri(dynamic id) {
    if (id == null) return null;
    for (final m in _materi) {
      if (m['id'] == id) return m['judul']?.toString();
    }
    return null;
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final judul = TextEditingController(text: existing?['judul'] ?? '');
    final xp = TextEditingController(text: '${existing?['xp_reward'] ?? 10}');
    String tipe = (existing?['tipe'] ?? 'kuis').toString();
    String? materiId = existing?['materi_id']?.toString();
    String? err;
    bool saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> simpan() async {
              final j = judul.text.trim();
              final x = int.tryParse(xp.text.trim());
              if (j.isEmpty) {
                setModal(() => err = 'Judul wajib diisi');
                return;
              }
              if (x == null || x < 0) {
                setModal(() => err = 'XP harus berupa angka');
                return;
              }
              setModal(() {
                saving = true;
                err = null;
              });
              final payload = {
                'judul': j,
                'tipe': tipe,
                'xp_reward': x,
                'materi_id': materiId,
              };
              try {
                if (existing == null) {
                  await _db.from('kuis').insert(payload);
                } else {
                  final res = await _db
                      .from('kuis')
                      .update(payload)
                      .eq('id', existing['id'])
                      .select();
                  if (res.isEmpty) throw Exception('ditolak');
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                debugPrint('Gagal menyimpan kuis: $e');
                if (!ctx.mounted) return;
                setModal(() {
                  saving = false;
                  err = 'Gagal menyimpan. Cek izin admin (RLS) di Supabase.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Tambah Kuis' : 'Edit Kuis',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: judul,
                      decoration: const InputDecoration(labelText: 'Judul kuis'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tipe,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                      items: const [
                        DropdownMenuItem(value: 'kuis', child: Text('Kuis')),
                        DropdownMenuItem(value: 'latihan', child: Text('Latihan')),
                      ],
                      onChanged: (v) => setModal(() => tipe = v ?? 'kuis'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: materiId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Materi terkait (opsional)'),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('Tanpa materi')),
                        ..._materi.map((m) => DropdownMenuItem<String?>(
                              value: m['id'].toString(),
                              child: Text(m['judul']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setModal(() => materiId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: xp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'XP hadiah'),
                    ),
                    const SizedBox(height: 12),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(err!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: saving ? null : simpan,
                        child: Text(
                          saving ? 'Menyimpan...' : 'Simpan',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      toast(context, existing == null ? 'Kuis ditambahkan' : 'Kuis diperbarui');
      _load();
    }
  }

  Future<void> _hapus(Map<String, dynamic> k) async {
    final n = _jumlahSoal(k);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kuis?'),
        content: Text(n > 0
            ? '"${k['judul']}" beserta $n soal di dalamnya akan dihapus permanen.'
            : '"${k['judul']}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // soal tidak ikut terhapus otomatis, jadi hapus dulu
      await _db.from('soal').delete().eq('kuis_id', k['id']);
      final res = await _db.from('kuis').delete().eq('id', k['id']).select();
      if (res.isEmpty) throw Exception('ditolak');
      if (!mounted) return;
      toast(context, '"${k['judul']}" dihapus');
      _load();
    } on PostgrestException catch (e) {
      debugPrint('Gagal menghapus kuis: $e');
      if (!mounted) return;
      toast(
        context,
        e.code == '23503'
            ? 'Tidak bisa dihapus: sudah ada hasil kuis pengguna.'
            : 'Gagal menghapus: ${e.message}',
      );
      _load();
    } catch (e) {
      debugPrint('Gagal menghapus kuis: $e');
      if (!mounted) return;
      toast(context, 'Gagal menghapus. Cek izin admin di Supabase.');
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_kuis.isEmpty) {
      return const Center(child: Text('Belum ada kuis. Tekan "Tambah Kuis".'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _kuis.length,
        itemBuilder: (context, i) {
          final k = _kuis[i];
          final materi = _judulMateri(k['materi_id']);
          final jenis = (k['tipe'] ?? 'kuis').toString() == 'latihan' ? 'Latihan' : 'Kuis';
          return itemCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.purpleSoft,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.assignment, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k['judul'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '$jenis • ${_jumlahSoal(k)} soal • ${k['xp_reward']} XP'
                        '${materi == null ? '' : ' • $materi'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                actionBtn('Soal', AppColors.secondary, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SoalKuisPage(kuis: k)),
                  );
                  _load(); // jumlah soal bisa berubah
                }),
                const SizedBox(width: 6),
                actionBtn('Edit', AppColors.primary, () => _showForm(existing: k)),
                const SizedBox(width: 6),
                actionBtn('Hapus', AppColors.danger, () => _hapus(k)),
              ],
            ),
          );
        },
      ),
    );
  }

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
        onPressed: _loading ? null : () => _showForm(),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Kuis', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// SOAL KUIS (tabel soal)
//    Soal di dalam sebuah kuis: pertanyaan, pilihan, jawaban benar
// ============================================================

class SoalKuisPage extends StatefulWidget {
  const SoalKuisPage({super.key, required this.kuis});

  final Map<String, dynamic> kuis;

  @override
  State<SoalKuisPage> createState() => _SoalKuisPageState();
}

class _SoalKuisPageState extends State<SoalKuisPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _soal = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // opsi di database bertipe jsonb: bisa list, bisa map
  List<String> _opsiList(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is Map) return raw.values.map((e) => e.toString()).toList();
    return <String>[];
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db
          .from('soal')
          .select()
          .eq('kuis_id', widget.kuis['id'])
          .order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _soal = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat soal: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat soal.';
        _loading = false;
      });
    }
  }

  Future<void> _showForm({Map<String, dynamic>? existing}) async {
    final tipeAwal = (existing?['tipe'] ?? 'teks').toString();
    final awalGambar = existing != null && tipeAwal != 'teks';

    final pertanyaan = TextEditingController(text: existing?['pertanyaan'] ?? '');
    final penjelasan = TextEditingController(text: existing?['penjelasan'] ?? '');
    final gambar = TextEditingController(text: existing?['gambar_pertanyaan'] ?? '');

    final opsiAwal = existing == null ? <String>[] : _opsiList(existing['opsi']);
    final gambarAwal = existing == null ? <String>[] : _opsiList(existing['opsi_gambar']);
    final teksAwal = awalGambar ? <String>[] : opsiAwal;
    final urlAwal = !awalGambar ? <String>[] : (gambarAwal.isNotEmpty ? gambarAwal : opsiAwal);

    bool modeGambar = awalGambar;
    final opsiCtrl = List.generate(
      teksAwal.length < 4 ? 4 : teksAwal.length,
      (i) => TextEditingController(text: i < teksAwal.length ? teksAwal[i] : ''),
    );
    final gambarCtrl = List.generate(
      urlAwal.length < 4 ? 4 : urlAwal.length,
      (i) => TextEditingController(text: i < urlAwal.length ? urlAwal[i] : ''),
    );

    int? benarTeks;
    int? benarGambar;
    if (existing != null) {
      final jb = (existing['jawaban_benar'] ?? '').toString();
      if (awalGambar) {
        var idx = opsiAwal.indexOf(jb);
        if (idx < 0) idx = gambarAwal.indexOf(jb);
        if (idx >= 0 && idx < urlAwal.length) benarGambar = idx;
      } else {
        final idx = teksAwal.indexOf(jb);
        if (idx >= 0) benarTeks = idx;
      }
    }

    final berikutnya = _soal.isEmpty ? 1 : ((_soal.last['urutan'] as num).toInt() + 1);
    final urutan = TextEditingController(text: '${existing?['urutan'] ?? berikutnya}');
    String? err;
    bool saving = false;
    int? uploadingIdx; // -1 = gambar pertanyaan, 0.. = gambar pilihan

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            // Pilih gambar dari galeri, upload ke Storage, kembalikan link publik
            Future<String?> unggah(int slot) async {
              setModal(() {
                uploadingIdx = slot;
                err = null;
              });
              try {
                final file =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (file == null) {
                  if (ctx.mounted) setModal(() => uploadingIdx = null);
                  return null;
                }
                const mimeTipe = {
                  'jpg': 'image/jpeg',
                  'jpeg': 'image/jpeg',
                  'png': 'image/png',
                  'gif': 'image/gif',
                  'webp': 'image/webp',
                };
                final ext = file.name.split('.').last.toLowerCase();
                final bytes = await file.readAsBytes();
                String? pesan;
                if (!mimeTipe.containsKey(ext)) {
                  pesan = 'Format harus JPG, PNG, GIF, atau WEBP';
                } else if (bytes.length > 5 * 1024 * 1024) {
                  pesan = 'Ukuran gambar maksimal 5 MB';
                }
                if (pesan != null) {
                  if (ctx.mounted) {
                    setModal(() {
                      uploadingIdx = null;
                      err = pesan;
                    });
                  }
                  return null;
                }
                final path = 'soal/${DateTime.now().microsecondsSinceEpoch}.$ext';
                final bucket = _db.storage.from('materi');
                await bucket.uploadBinary(
                  path,
                  bytes,
                  fileOptions: FileOptions(contentType: mimeTipe[ext]),
                );
                if (!ctx.mounted) return null;
                setModal(() => uploadingIdx = null);
                return bucket.getPublicUrl(path);
              } catch (e) {
                debugPrint('Gagal upload gambar soal: $e');
                if (!ctx.mounted) return null;
                setModal(() {
                  uploadingIdx = null;
                  err = 'Gagal upload. Cek bucket dan izin Storage di Supabase.';
                });
                return null;
              }
            }

            Future<void> simpan() async {
              final p = pertanyaan.text.trim();
              final g = gambar.text.trim();
              final u = int.tryParse(urutan.text.trim());
              if (p.isEmpty && g.isEmpty) {
                setModal(() => err = 'Pertanyaan atau gambar pertanyaan wajib diisi');
                return;
              }
              if (u == null) {
                setModal(() => err = 'Urutan harus berupa angka');
                return;
              }

              final sumber = modeGambar ? gambarCtrl : opsiCtrl;
              final terpilih = modeGambar ? benarGambar : benarTeks;
              final opsi = <String>[];
              int? benarBaru;
              for (var i = 0; i < sumber.length; i++) {
                final t = sumber[i].text.trim();
                if (t.isEmpty) continue;
                if (terpilih == i) benarBaru = opsi.length;
                opsi.add(t);
              }
              if (opsi.length < 2) {
                setModal(() => err = modeGambar
                    ? 'Isi minimal 2 pilihan gambar'
                    : 'Isi minimal 2 pilihan jawaban');
                return;
              }
              if (benarBaru == null) {
                setModal(() => err =
                    'Pilih jawaban yang benar (tap bulatan di samping pilihan)');
                return;
              }

              setModal(() {
                saving = true;
                err = null;
              });
              final payload = <String, dynamic>{
                'kuis_id': widget.kuis['id'],
                'pertanyaan': p,
                'gambar_pertanyaan': g.isEmpty ? null : g,
                'penjelasan': penjelasan.text.trim(),
                'urutan': u,
                'opsi': opsi,
                'jawaban_benar': opsi[benarBaru],
                'tipe': modeGambar ? (awalGambar ? tipeAwal : 'gambar') : 'teks',
                'opsi_gambar': modeGambar ? opsi : <String>[],
              };
              try {
                if (existing == null) {
                  await _db.from('soal').insert(payload);
                } else {
                  final res = await _db
                      .from('soal')
                      .update(payload)
                      .eq('id', existing['id'])
                      .select();
                  if (res.isEmpty) throw Exception('ditolak');
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                debugPrint('Gagal menyimpan soal: $e');
                if (!ctx.mounted) return;
                setModal(() {
                  saving = false;
                  err = 'Gagal menyimpan. Cek izin admin (RLS) di Supabase.';
                });
              }
            }

            final sibuk = saving || uploadingIdx != null;

            // Satu baris pilihan bergambar
            Widget barisGambar(int i) {
              final url = gambarCtrl[i].text.trim();
              Widget preview;
              if (url.isEmpty) {
                preview = const Icon(Icons.image_outlined, color: AppColors.textMuted);
              } else if (url.startsWith('http')) {
                preview = Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: AppColors.textMuted),
                );
              } else {
                preview = Center(
                  child: Text(url,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setModal(() => benarGambar = i),
                      icon: Icon(
                        benarGambar == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: benarGambar == i ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: preview,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pilihan ${String.fromCharCode(65 + i)}',
                              style: AppTextStyles.labelMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 4,
                            children: [
                              OutlinedButton(
                                onPressed: sibuk
                                    ? null
                                    : () async {
                                        final hasil = await unggah(i);
                                        if (hasil != null && ctx.mounted) {
                                          setModal(() => gambarCtrl[i].text = hasil);
                                        }
                                      },
                                child: Text(uploadingIdx == i
                                    ? 'Mengupload...'
                                    : (url.isEmpty ? 'Pilih Gambar' : 'Ganti')),
                              ),
                              if (url.isNotEmpty)
                                TextButton(
                                  onPressed: sibuk
                                      ? null
                                      : () => setModal(() => gambarCtrl[i].clear()),
                                  child: const Text('Hapus'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existing == null ? 'Tambah Soal' : 'Edit Soal',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pertanyaan,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Pertanyaan'),
                    ),
                    const SizedBox(height: 12),
                    if (gambar.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(
                          gambar.text,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('Gambar tidak bisa ditampilkan'),
                        ),
                      ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: sibuk
                              ? null
                              : () async {
                                  final hasil = await unggah(-1);
                                  if (hasil != null && ctx.mounted) {
                                    setModal(() => gambar.text = hasil);
                                  }
                                },
                          icon: const Icon(Icons.upload),
                          label: Text(uploadingIdx == -1
                              ? 'Mengupload...'
                              : 'Gambar Pertanyaan'),
                        ),
                        if (gambar.text.isNotEmpty)
                          TextButton(
                            onPressed: sibuk ? null : () => setModal(() => gambar.clear()),
                            child: const Text('Hapus gambar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Pilihan jawaban berupa:',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Teks')),
                        ButtonSegment(value: true, label: Text('Gambar')),
                      ],
                      selected: {modeGambar},
                      onSelectionChanged: (s) => setModal(() => modeGambar = s.first),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap bulatan untuk menandai jawaban yang benar',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    if (modeGambar)
                      ...List.generate(gambarCtrl.length, barisGambar)
                    else
                      ...List.generate(
                        opsiCtrl.length,
                        (i) => Row(
                          children: [
                            IconButton(
                              onPressed: () => setModal(() => benarTeks = i),
                              icon: Icon(
                                benarTeks == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: benarTeks == i
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: opsiCtrl[i],
                                decoration: InputDecoration(
                                  labelText: 'Pilihan ${String.fromCharCode(65 + i)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: penjelasan,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Penjelasan jawaban (opsional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urutan,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Urutan'),
                    ),
                    const SizedBox(height: 12),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(err!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: sibuk ? null : simpan,
                        child: Text(
                          saving ? 'Menyimpan...' : 'Simpan',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      toast(context, existing == null ? 'Soal ditambahkan' : 'Soal diperbarui');
      _load();
    }
  }

  Future<void> _hapus(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus soal?'),
        content: const Text('Soal ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await _db.from('soal').delete().eq('id', s['id']).select();
      if (res.isEmpty) throw Exception('ditolak');
      if (!mounted) return;
      toast(context, 'Soal dihapus');
      _load();
    } catch (e) {
      debugPrint('Gagal menghapus soal: $e');
      if (!mounted) return;
      toast(context, 'Gagal menghapus. Cek izin admin di Supabase.');
    }
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_soal.isEmpty) {
      return const Center(child: Text('Belum ada soal. Tekan "Tambah Soal".'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _soal.length,
      itemBuilder: (context, i) {
        final s = _soal[i];
        final url = (s['gambar_pertanyaan'] ?? '').toString();
        final pertanyaan = (s['pertanyaan'] ?? '').toString();
        return itemCard(
          child: Row(
            children: [
              if (url.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pertanyaan.isEmpty ? '(pertanyaan bergambar)' : pertanyaan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      (s['tipe'] ?? 'teks').toString() == 'teks'
                          ? 'Urutan ${s['urutan']} • Jawaban: ${s['jawaban_benar'] ?? '-'}'
                          : 'Urutan ${s['urutan']} • Pilihan berupa gambar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              actionBtn('Edit', AppColors.primary, () => _showForm(existing: s)),
              const SizedBox(width: 6),
              actionBtn('Hapus', AppColors.danger, () => _hapus(s)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(widget.kuis['judul'] ?? 'Soal Kuis',
            style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _loading || _error != null ? null : () => _showForm(),
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Tambah Soal', style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// 7. BROADCAST NOTIFIKASI
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
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

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
// 8. BANNER & PROMO
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
// 9. LOG AKTIVITAS ADMIN
// ============================================================

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key});

  static final List<Map<String, String>> logs = [
    {'admin': 'Admin Utama', 'action': 'Menghapus 1 komentar dari Agus Prasetyo', 'time': 'Hari ini 14:20'},
    {'admin': 'Admin Utama', 'action': 'Menyetujui kiriman milik Laras Putri', 'time': 'Hari ini 11:05'},
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