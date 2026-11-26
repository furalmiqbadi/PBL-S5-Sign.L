import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Isi satu bab: gestur/huruf satu per satu (tabel `isi_materi`),
/// lengkap dengan gambar dan penjelasan cara membentuknya.
class IsiMateriPage extends StatefulWidget {
  /// `id` dari tabel `bab_materi`.
  final String babId;

  /// Judul bab, untuk header (opsional).
  final String? judulBab;

  /// Gestur ke berapa yang ditampilkan pertama kali (mulai dari 0).
  final int startIndex;

  const IsiMateriPage({
    super.key,
    required this.babId,
    this.judulBab,
    this.startIndex = 0,
  });

  @override
  State<IsiMateriPage> createState() => _IsiMateriPageState();
}

class _IsiMateriPageState extends State<IsiMateriPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _isi = [];
  int _index = 0;
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
          .eq('bab_id', widget.babId)
          .order('urutan', ascending: true);
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data);
      setState(() {
        _isi = list;
        _index = list.isEmpty ? 0 : widget.startIndex.clamp(0, list.length - 1);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat isi materi: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat isi materi. Periksa koneksi internetmu.';
        _loading = false;
      });
    }
  }

  bool get _isFirst => _index <= 0;
  bool get _isLast => _index >= _isi.length - 1;

  void _sebelumnya() {
    if (_isFirst) return;
    setState(() => _index--);
  }

  void _berikutnya() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  void _kamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur kamera AI segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            if (!_loading && _error == null && _isi.isNotEmpty) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
      child: Row(
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.judulBab ?? 'Isi Materi',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge,
            ),
          ),
          if (_isi.isNotEmpty)
            Text(
              '${_index + 1} / ${_isi.length}',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_isi.isEmpty) {
      return const Center(child: Text('Belum ada isi di bab ini.'));
    }

    final item = _isi[_index];
    final judul = (item['judul'] ?? '').toString();
    final deskripsi = (item['deskripsi'] ?? '').toString();
    final url = (item['gambar_url'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Gambar gestur
        Container(
          height: 280,
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
          clipBehavior: Clip.antiAlias,
          child: url.isEmpty
              ? const Center(
                  child: Icon(Icons.pan_tool_alt_outlined,
                      size: 64, color: AppColors.textMuted),
                )
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 64, color: AppColors.textMuted),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        // Judul + penjelasan
        Container(
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
              Text(judul.isEmpty ? '(tanpa judul)' : judul,
                  style: AppTextStyles.titleLarge),
              if (deskripsi.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  deskripsi,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Progres di dalam bab
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: (_index + 1) / _isi.length,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isFirst ? null : _sebelumnya,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _kamera,
            tooltip: 'Latihan kamera',
            icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.pinkSoft,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _berikutnya,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLast ? 'Selesai' : 'Berikutnya',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Icon(_isLast ? Icons.check : Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}