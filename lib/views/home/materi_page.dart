import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'detail_materi_page.dart';

/// Konten tab Materi: daftar materi (tabel `materi`) yang sudah diterbitkan admin.
///
/// Widget ini hanya berisi konten (tanpa AppBar maupun bottom navigation)
/// karena header dan navbar disediakan oleh `MainShell`.
class MateriPage extends StatefulWidget {
  const MateriPage({super.key});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _db
          .from('materi')
          .select('*, bab_materi(count)')
          .eq('is_published', true)
          .order('urutan', ascending: true);
      if (!mounted) return;
      setState(() {
        _materi = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat materi: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat materi. Periksa koneksi internetmu.';
        _loading = false;
      });
    }
  }

  int _jumlahBab(Map<String, dynamic> m) {
    final v = m['bab_materi'];
    if (v is List && v.isNotEmpty && v.first is Map) {
      return ((v.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  void _buka(Map<String, dynamic> m) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailMateriPage(materi: m)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: _buildChildren(),
      ),
    );
  }

  List<Widget> _buildChildren() {
    if (_loading) {
      return const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (_error != null) {
      return [
        const SizedBox(height: 120),
        Center(child: Text(_error!, textAlign: TextAlign.center)),
        Center(
          child: TextButton(onPressed: _load, child: const Text('Coba lagi')),
        ),
      ];
    }
    if (_materi.isEmpty) {
      return const [
        SizedBox(height: 120),
        Center(child: Text('Belum ada materi yang tersedia.')),
      ];
    }
    return [
      _SummaryCard(jumlah: _materi.length),
      const SizedBox(height: 24),
      Text('Pilih Materi', style: AppTextStyles.titleLarge),
      const SizedBox(height: 12),
      ...List.generate(_materi.length, (i) {
        final m = _materi[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MateriCard(
            nomor: i + 1,
            judul: (m['judul'] ?? '').toString(),
            deskripsi: (m['deskripsi'] ?? '').toString(),
            jumlahBab: _jumlahBab(m),
            onTap: () => _buka(m),
          ),
        );
      }),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  final int jumlah;
  const _SummaryCard({required this.jumlah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERI BELAJAR',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Belajar Bahasa Isyarat',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$jumlah materi siap dipelajari.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MateriCard extends StatelessWidget {
  final int nomor;
  final String judul;
  final String deskripsi;
  final int jumlahBab;
  final VoidCallback onTap;

  const _MateriCard({
    required this.nomor,
    required this.judul,
    required this.deskripsi,
    required this.jumlahBab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.pinkSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$nomor',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materi $nomor',
                            style: AppTextStyles.labelXSmall.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                if (deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    deskripsi,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.33),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$jumlahBab Bab',
                      style: AppTextStyles.labelXSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}