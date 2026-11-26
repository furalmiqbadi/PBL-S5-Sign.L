import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../home/isi_materi_page.dart';

/// Detail satu materi: menampilkan daftar bab (tabel `bab_materi`),
/// misalnya "Pengenalan Abjad BISINDO A-E", "F-J", dst.
///
/// [materi] adalah satu baris dari tabel `materi`. Kalau null, halaman ini
/// memuat materi pertama yang sudah diterbitkan.
class DetailMateriPage extends StatefulWidget {
  const DetailMateriPage({super.key, this.materi});

  final Map<String, dynamic>? materi;

  @override
  State<DetailMateriPage> createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _materi;
  List<Map<String, dynamic>> _bab = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _materi = widget.materi;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_materi == null) {
        final first = await _db
            .from('materi')
            .select()
            .eq('is_published', true)
            .order('urutan', ascending: true)
            .limit(1)
            .maybeSingle();
        _materi = first;
      }
      if (_materi == null) {
        if (!mounted) return;
        setState(() {
          _bab = [];
          _loading = false;
        });
        return;
      }
      final data = await _db
          .from('bab_materi')
          .select('*, isi_materi(count)')
          .eq('materi_id', _materi!['id'])
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
        _error = 'Gagal memuat bab. Periksa koneksi internetmu.';
        _loading = false;
      });
    }
  }

  int _jumlahIsi(Map<String, dynamic> b) {
    final v = b['isi_materi'];
    if (v is List && v.isNotEmpty && v.first is Map) {
      return ((v.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get _totalHuruf => _bab.fold(0, (sum, b) => sum + _jumlahIsi(b));

  void _bukaIsi(Map<String, dynamic> bab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsiMateriPage(
          babId: bab['id'].toString(),
          judulBab: bab['judul']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              ..._buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          tooltip: 'Kembali',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.fieldFill,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            (_materi?['judul'] ?? 'Materi').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headlineSmall,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBody() {
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
        Center(child: TextButton(onPressed: _load, child: const Text('Coba lagi'))),
      ];
    }
    if (_materi == null) {
      return const [
        SizedBox(height: 120),
        Center(child: Text('Belum ada materi yang tersedia.')),
      ];
    }
    return [
      _buildModuleInfo(),
      const SizedBox(height: 24),
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('Daftar Bab', style: AppTextStyles.titleLarge),
        ],
      ),
      const SizedBox(height: 12),
      if (_bab.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('Belum ada bab di materi ini.')),
        )
      else
        ...List.generate(_bab.length, (i) {
          final b = _bab[i];
          final jumlah = _jumlahIsi(b);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BabCard(
              nomor: i + 1,
              judul: (b['judul'] ?? '').toString(),
              deskripsi: (b['deskripsi'] ?? '').toString(),
              jumlahHuruf: jumlah,
              onTap: jumlah == 0 ? null : () => _bukaIsi(b),
            ),
          );
        }),
    ];
  }

  Widget _buildModuleInfo() {
    final deskripsi = (_materi?['deskripsi'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              'MODUL',
              style: AppTextStyles.labelXSmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (deskripsi.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              deskripsi,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.63,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoColumn('Total Bab', '${_bab.length} Bab', AppColors.textPrimary),
              _infoColumn('Total Isi', '$_totalHuruf Gestur', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, Color valueColor) {
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
        Text(value, style: AppTextStyles.titleSmall.copyWith(color: valueColor)),
      ],
    );
  }
}

class _BabCard extends StatelessWidget {
  final int nomor;
  final String judul;
  final String deskripsi;
  final int jumlahHuruf;
  final VoidCallback? onTap;

  const _BabCard({
    required this.nomor,
    required this.judul,
    required this.deskripsi,
    required this.jumlahHuruf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kosong = onTap == null;
    return Container(
      decoration: BoxDecoration(
        color: kosong ? AppColors.fieldFill : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kosong
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kosong ? AppColors.border : AppColors.pinkSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$nomor',
                    style: AppTextStyles.labelMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: kosong ? AppColors.textSecondary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kosong
                            ? 'Belum ada isi'
                            : (deskripsi.isEmpty
                                ? '$jumlahHuruf gestur'
                                : '$jumlahHuruf gestur • $deskripsi'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelXSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  kosong ? Icons.lock_outline : Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}