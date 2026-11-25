import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_ui.dart';
import 'wizard_kuis_page.dart';
import 'wizard_materi_page.dart';

// ============================================================
// Helper bersama
// ============================================================

void toast(BuildContext context, String msg,
    {AppSnackType type = AppSnackType.info}) {
  showAppSnackBar(context, msg, type: type);
}

Widget adminPage({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget child,
  List<Widget> actions = const [],
  bool embedded = false,
}) {
  final isi = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      const Divider(height: 1, color: AppColors.border),
      Expanded(child: child),
    ],
  );
  if (embedded) return isi;
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const BackButton(color: AppColors.textPrimary),
      title: Text(title, style: AppTextStyles.headlineSmall),
      actions: actions,
    ),
    body: isi,
  );
}

Widget itemCard({
  required Widget child,
  EdgeInsets margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
}) {
  return AppCard(
    margin: margin,
    padding: const EdgeInsets.all(14),
    borderRadius: AppRadii.md,
    child: child,
  );
}

Widget actionBtn(String label, Color color, VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: const Size(0, 44),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
    child: Text(label),
  );
}

/// Pembungkus state loading / error / tabel belum siap / kosong / data siap.
Widget adminAsync<T>({
  required bool loading,
  required String? error,
  required bool tabelSiap,
  required List<T> data,
  required VoidCallback onRetry,
  required Widget Function(List<T> data) builder,
  String emptyTitle = 'Belum ada data',
  String emptyMessage = 'Belum ada data untuk ditampilkan saat ini.',
}) {
  if (loading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (error != null) {
    return _PesanState(
      icon: Icons.cloud_off_rounded,
      title: 'Gagal memuat data',
      message: error,
      actionLabel: 'Muat ulang',
      onAction: onRetry,
    );
  }
  if (!tabelSiap) {
    return const _PesanState(
      icon: Icons.storage_rounded,
      title: 'Tabel belum tersedia',
      message:
          'Jalankan file supabase/patch_signl_backend.sql di SQL Editor Supabase '
          'agar modul ini bisa dipakai.',
    );
  }
  if (data.isEmpty) {
    return _PesanState(
      icon: Icons.inbox_rounded,
      title: emptyTitle,
      message: emptyMessage,
      actionLabel: 'Muat ulang',
      onAction: onRetry,
    );
  }
  return builder(data);
}

class _PesanState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PesanState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTonal,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 26),
              ),
              const SizedBox(height: 14),
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(height: 1.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 1. LAPORAN PENGGUNA
// ============================================================

class LaporanPenggunaPage extends StatefulWidget {
  /// `true` bila ditampilkan di dalam tab shell admin (tanpa Scaffold/AppBar).
  final bool embedded;

  const LaporanPenggunaPage({super.key, this.embedded = false});

  @override
  State<LaporanPenggunaPage> createState() => _LaporanPenggunaPageState();
}

class _LaporanPenggunaPageState extends State<LaporanPenggunaPage> {
  final AdminService _service = AdminService();

  AdminList<LaporanItem> _list = AdminList.kosongBelumSiap.cast();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchLaporan();
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aksi(LaporanItem laporan, String status, String log) async {
    final label = switch (status) {
      'dihapus' => 'Hapus konten laporan ini?',
      'dibanned' => 'Blokir pengguna yang dilaporkan?',
      _ => 'Abaikan laporan ini?',
    };
    final ok = await showAppDialog(
      context,
      title: label,
      message: '"${laporan.alasan}" — ${laporan.terlapor}',
      icon: Icons.flag_rounded,
      iconColor:
          status == 'diabaikan' ? AppColors.textSecondary : AppColors.danger,
      confirmLabel: 'Lanjutkan',
      isDestructive: status != 'diabaikan',
    );
    if (ok != true) return;
    try {
      await _service.ubahStatusLaporan(laporan.id, status);
      await _service.catatLog(log);
      if (!mounted) return;
      toast(context, 'Laporan diperbarui.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _balas(LaporanItem laporan, String template) async {
    final input =
        await _dialogBalasTemplate(context, laporan, template: template);
    if (input == null || !mounted) return;
    try {
      await _service.balasLaporan(
        laporan: laporan,
        template: input.$1,
        alasan: input.$2,
      );
      if (!mounted) return;
      toast(context, 'Balasan terkirim ke chat pelapor.',
          type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Laporan Pengguna',
      subtitle: '${_list.data.length} laporan terdaftar',
      embedded: widget.embedded,
      child: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<LaporanItem>(
          loading: _loading,
          error: _error,
          tabelSiap: _list.tabelTersedia || _loading,
          data: _list.data,
          onRetry: _muat,
          emptyTitle: 'Belum ada laporan',
          emptyMessage: 'Tidak ada laporan pengguna yang masuk.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final l = data[i];
              final selesai = l.status != 'baru';
              return itemCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.pinkSoft,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l.terlapor} dilaporkan oleh ${l.pelapor}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                l.waktu,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: selesai ? l.status : l.alasan,
                          color: selesai
                              ? AppColors.textSecondary
                              : AppColors.danger,
                          backgroundColor: selesai
                              ? AppColors.surfaceMuted
                              : AppColors.dangerSoft,
                        ),
                      ],
                    ),
                    if (l.detail.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(l.detail, style: AppTextStyles.bodySmall),
                      ),
                    ],
                    if (!selesai) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          actionBtn(
                            'Hapus Konten',
                            AppColors.danger,
                            () => _aksi(l, 'dihapus',
                                'Menghapus konten laporan milik ${l.terlapor}'),
                          ),
                          actionBtn(
                            'Banned 7 Hari',
                            AppColors.tertiary,
                            () => _aksi(l, 'dibanned',
                                'Memblokir ${l.terlapor} selama 7 hari'),
                          ),
                          actionBtn(
                            'Abaikan',
                            AppColors.textSecondary,
                            () => _aksi(l, 'diabaikan',
                                'Mengabaikan laporan ${l.terlapor}'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (l.sudahDibalas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          'Sudah dibalas: ${l.balasan}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    if (!l.sudahDibalas)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          actionBtn(
                            'Balas: Dieksekusi',
                            AppColors.success,
                            () => _balas(l, 'dieksekusi'),
                          ),
                          actionBtn(
                            'Balas: Ditolak',
                            AppColors.danger,
                            () => _balas(l, 'ditolak'),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _pesan(Object e) =>
    e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';

/// Dialog balasan template untuk pelapor.
///
/// Mengembalikan `(template, alasan)` atau null bila dibatalkan.
Future<(String, String)?> _dialogBalasTemplate(
  BuildContext context,
  LaporanItem laporan, {
  required String template,
}) async {
  final alasan = TextEditingController();
  final hasil = await showAppDialog(
    context,
    title: template == 'ditolak'
        ? 'Tolak Laporan & Balas'
        : 'Konfirmasi Eksekusi & Balas',
    message: 'Balasan masuk ke chat pelapor "${laporan.pelapor}" sebagai '
        'ruang hanya-baca.',
    icon: template == 'ditolak'
        ? Icons.report_gmailerrorred_rounded
        : Icons.verified_rounded,
    iconColor: template == 'ditolak' ? AppColors.danger : AppColors.success,
    confirmLabel: 'Kirim Balasan',
    isDestructive: template == 'ditolak',
    content: _field(
      alasan,
      template == 'ditolak' ? 'Alasan penolakan' : 'Catatan admin (opsional)',
      maxLines: 3,
    ),
  );
  final teks = alasan.text.trim();
  alasan.dispose();
  if (hasil != true) return null;
  if (template == 'ditolak' && teks.isEmpty) return null;
  return (template, teks);
}

extension _CastAdminList on AdminList<Never> {
  AdminList<T> cast<T>() =>
      AdminList<T>(const [], tabelTersedia: tabelTersedia);
}

// ============================================================
// 2. MODERASI CHAT
// ============================================================

class ModerasiChatPage extends StatefulWidget {
  /// `true` bila ditampilkan di dalam tab shell admin (tanpa Scaffold/AppBar).
  final bool embedded;

  const ModerasiChatPage({super.key, this.embedded = false});

  @override
  State<ModerasiChatPage> createState() => _ModerasiChatPageState();
}

class _ModerasiChatPageState extends State<ModerasiChatPage> {
  final AdminService _service = AdminService();

  AdminList<LaporanItem> _list = AdminList.kosongBelumSiap.cast();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchLaporan(tipe: 'chat');
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aksi(LaporanItem laporan, String status, String log) async {
    final ok = await showAppDialog(
      context,
      title: switch (status) {
        'dihapus' => 'Hapus pesan ini?',
        'dibanned' => 'Blokir pengguna ini permanen?',
        _ => 'Abaikan laporan ini?',
      },
      message: '"${laporan.pesan}"',
      icon: Icons.forum_rounded,
      iconColor:
          status == 'diabaikan' ? AppColors.textSecondary : AppColors.danger,
      confirmLabel: 'Lanjutkan',
      isDestructive: status != 'diabaikan',
    );
    if (ok != true) return;
    try {
      await _service.ubahStatusLaporan(laporan.id, status);
      await _service.catatLog(log);
      if (!mounted) return;
      toast(context, 'Laporan chat diperbarui.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _balas(LaporanItem laporan, String template) async {
    final input =
        await _dialogBalasTemplate(context, laporan, template: template);
    if (input == null || !mounted) return;
    try {
      await _service.balasLaporan(
        laporan: laporan,
        template: input.$1,
        alasan: input.$2,
      );
      if (!mounted) return;
      toast(context, 'Balasan terkirim ke chat pelapor.',
          type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Moderasi Chat',
      subtitle: '${_list.data.length} pesan dilaporkan pengguna',
      embedded: widget.embedded,
      child: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<LaporanItem>(
          loading: _loading,
          error: _error,
          tabelSiap: _list.tabelTersedia || _loading,
          data: _list.data,
          onRetry: _muat,
          emptyTitle: 'Tidak ada chat dilaporkan',
          emptyMessage: 'Belum ada pesan chat yang dilaporkan pengguna.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final l = data[i];
              final selesai = l.status != 'baru';
              return itemCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l.pelapor} → ${l.terlapor}',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          l.waktu,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        l.pesan.isEmpty ? l.detail : '"${l.pesan}"',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.flag_rounded,
                            size: 14, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Text(
                          l.alasan,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (selesai)
                          AppStatusBadge(
                            label: l.status,
                            color: AppColors.textSecondary,
                            backgroundColor: AppColors.surfaceMuted,
                          ),
                      ],
                    ),
                    if (!selesai) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          actionBtn(
                            'Hapus Pesan',
                            AppColors.danger,
                            () => _aksi(l, 'dihapus',
                                'Menghapus pesan chat dari ${l.terlapor}'),
                          ),
                          actionBtn(
                            'Banned Permanen',
                            AppColors.tertiary,
                            () => _aksi(l, 'dibanned',
                                'Memblokir permanen ${l.terlapor}'),
                          ),
                          actionBtn(
                            'Abaikan',
                            AppColors.textSecondary,
                            () => _aksi(l, 'diabaikan',
                                'Mengabaikan laporan chat ${l.terlapor}'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (l.sudahDibalas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          'Sudah dibalas: ${l.balasan}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    if (!l.sudahDibalas)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          actionBtn(
                            'Balas: Dieksekusi',
                            AppColors.success,
                            () => _balas(l, 'dieksekusi'),
                          ),
                          actionBtn(
                            'Balas: Ditolak',
                            AppColors.danger,
                            () => _balas(l, 'ditolak'),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. REVIEW VIDEO & FOTO
// ============================================================

class ReviewVideoAIPage extends StatefulWidget {
  const ReviewVideoAIPage({super.key});

  @override
  State<ReviewVideoAIPage> createState() => _ReviewVideoAIPageState();
}

class _ReviewVideoAIPageState extends State<ReviewVideoAIPage> {
  final AdminService _service = AdminService();

  AdminList<MediaItem> _list = AdminList.kosongBelumSiap.cast();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchMedia();
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubahStatus(MediaItem item, String status) async {
    try {
      await _service.ubahStatusMedia(item.id, status);
      await _service.catatLog(
        '${status == 'disetujui' ? 'Menyetujui' : 'Menolak'} kiriman ${item.namaUser}',
      );
      if (!mounted) return;
      toast(
        context,
        status == 'disetujui' ? 'Kiriman disetujui.' : 'Kiriman ditolak.',
        type:
            status == 'disetujui' ? AppSnackType.success : AppSnackType.warning,
      );
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Review Video & Foto',
      subtitle: '${_list.data.length} kiriman terdaftar',
      child: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<MediaItem>(
          loading: _loading,
          error: _error,
          tabelSiap: _list.tabelTersedia || _loading,
          data: _list.data,
          onRetry: _muat,
          emptyTitle: 'Belum ada kiriman',
          emptyMessage: 'Tidak ada video atau foto yang menunggu tinjauan.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final m = data[i];
              final menunggu = m.status == 'menunggu';
              return itemCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              m.isVideo
                                  ? Icons.videocam_rounded
                                  : Icons.image_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: m.isVideo
                                    ? AppColors.secondary
                                    : AppColors.primary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(AppRadii.sm),
                                ),
                              ),
                              child: Text(
                                m.isVideo ? 'VIDEO' : 'FOTO',
                                style: AppTextStyles.labelXSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.deskripsi.isEmpty
                                ? 'Kiriman pengguna'
                                : m.deskripsi,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${m.namaUser} • ${m.waktu}',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          AppStatusBadge(
                            label: m.status,
                            color: menunggu
                                ? AppColors.tertiary
                                : (m.status == 'disetujui'
                                    ? AppColors.success
                                    : AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    if (menunggu) ...[
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          actionBtn('Setujui', AppColors.success,
                              () => _ubahStatus(m, 'disetujui')),
                          const SizedBox(height: 6),
                          actionBtn('Tolak', AppColors.danger,
                              () => _ubahStatus(m, 'ditolak')),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
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
  final AdminService _service = AdminService();

  List<PenggunaItem> _pengguna = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchPengguna();
      if (!mounted) return;
      setState(() => _pengguna = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setBanned(PenggunaItem user) async {
    final ok = await showAppDialog(
      context,
      title: user.banned ? 'Buka blokir pengguna?' : 'Blokir pengguna ini?',
      message:
          '${user.nama} akan ${user.banned ? 'kembali bisa' : 'tidak bisa'} '
          'mengakses aplikasi.',
      icon: Icons.block_rounded,
      confirmLabel: user.banned ? 'Buka blokir' : 'Blokir',
      isDestructive: !user.banned,
    );
    if (ok != true) return;
    try {
      await _service.setBanned(user.id, !user.banned);
      await _service.catatLog(
        '${user.banned ? 'Membuka blokir' : 'Memblokir'} ${user.nama}',
      );
      if (!mounted) return;
      toast(
        context,
        user.banned ? 'Blokir dibuka.' : 'Pengguna diblokir.',
        type: AppSnackType.success,
      );
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _pengguna.where((u) {
      final q = _query.toLowerCase();
      return u.nama.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q);
    }).toList();

    return adminPage(
      context: context,
      title: 'Manajemen Pengguna',
      subtitle: '${_pengguna.length} pengguna terdaftar',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama atau username...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muat,
              child: adminAsync<PenggunaItem>(
                loading: _loading,
                error: _error,
                tabelSiap: true,
                data: filtered,
                onRetry: _muat,
                emptyTitle: 'Pengguna tidak ditemukan',
                emptyMessage: 'Tidak ada pengguna yang cocok dengan pencarian.',
                builder: (data) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final u = data[i];
                    return itemCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: u.banned
                                ? AppColors.surfaceMuted
                                : AppColors.purpleSoft,
                            child: Text(
                              u.nama.isEmpty ? '?' : u.nama[0].toUpperCase(),
                              style: TextStyle(
                                color: u.banned
                                    ? AppColors.textMuted
                                    : AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.nama,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${u.roleLabel} • Streak ${u.streak} hari'
                                  '${u.banned ? ' • Diblokir' : ''}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: u.banned
                                        ? AppColors.danger
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          actionBtn(
                            u.banned ? 'Buka Banned' : 'Banned',
                            u.banned ? AppColors.success : AppColors.danger,
                            () => _setBanned(u),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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

class LeaderboardPoinPage extends StatefulWidget {
  const LeaderboardPoinPage({super.key});

  @override
  State<LeaderboardPoinPage> createState() => _LeaderboardPoinPageState();
}

class _LeaderboardPoinPageState extends State<LeaderboardPoinPage> {
  final AdminService _service = AdminService();

  List<PenggunaItem> _pengguna = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchPengguna();
      if (!mounted) return;
      setState(() {
        _pengguna = data.toList()..sort((a, b) => b.points.compareTo(a.points));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset(PenggunaItem user) async {
    final ok = await showAppDialog(
      context,
      title: 'Reset poin pengguna?',
      message: 'Poin dan XP ${user.nama} akan dikembalikan ke 0.',
      icon: Icons.restart_alt_rounded,
      confirmLabel: 'Reset',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.resetPoin(user.id);
      await _service.catatLog('Mereset poin ${user.nama}');
      if (!mounted) return;
      toast(context, 'Poin direset.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Leaderboard & Poin',
      subtitle: 'Peringkat berdasarkan poin terbanyak',
      child: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<PenggunaItem>(
          loading: _loading,
          error: _error,
          tabelSiap: true,
          data: _pengguna,
          onRetry: _muat,
          emptyTitle: 'Belum ada peringkat',
          emptyMessage: 'Belum ada pengguna dengan poin.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final u = data[i];
              final rank = i + 1;
              final medal = rank == 1
                  ? Colors.amber
                  : (rank == 2
                      ? Colors.grey
                      : (rank == 3 ? Colors.brown : AppColors.surfaceMuted));
              return itemCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: medal,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.nama,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${u.points} poin • ${u.xp} XP',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    actionBtn(
                        'Reset Poin', AppColors.tertiary, () => _reset(u)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 6. MANAGEMENT MATERI
// ============================================================

class ManagementMateriPage extends StatefulWidget {
  /// `true` bila ditampilkan di dalam tab shell admin (tanpa AppBar).
  final bool embedded;

  const ManagementMateriPage({super.key, this.embedded = false});

  @override
  State<ManagementMateriPage> createState() => _ManagementMateriPageState();
}

class _ManagementMateriPageState extends State<ManagementMateriPage> {
  final AdminService _service = AdminService();

  List<MateriAdminItem> _materi = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchMateriAdmin();
      if (!mounted) return;
      setState(() => _materi = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bukaWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WizardMateriPage(urutanAwal: _materi.length + 1),
      ),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  void _bukaEdit(MateriAdminItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditMateriAdminPage(materi: item)),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  Future<void> _hapus(MateriAdminItem item) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus materi?',
      message: '"${item.judul}" beserta kuis terkait akan dihapus.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusMateri(item.id);
      await _service.catatLog('Menghapus materi "${item.judul}"');
      if (!mounted) return;
      toast(context, 'Materi dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fab = AppFab(
      label: 'Materi',
      onPressed: _bukaWizard,
    );
    final isi = RefreshIndicator(
      onRefresh: _muat,
      child: adminAsync<MateriAdminItem>(
        loading: _loading,
        error: _error,
        tabelSiap: true,
        data: _materi,
        onRetry: _muat,
        emptyTitle: 'Belum ada materi',
        emptyMessage: 'Tambahkan materi pertama lewat tombol di bawah.',
        builder: (data) => ListView.builder(
          padding: EdgeInsets.only(
            bottom: widget.embedded
                ? AppBottomNavBar.reservedSpace(context) + 16
                : 100,
            top: 4,
          ),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final m = data[i];
            return itemCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.pinkSoft,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m.urutan}. ${m.judul}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${m.jumlahKuis} kuis • '
                          '${m.published ? 'Terbit' : 'Draf'}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                        if (m.adaGambar || m.adaVideo || m.adaKamera)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (m.adaGambar)
                                  const AppStatusBadge(
                                    label: 'Foto',
                                    color: AppColors.secondary,
                                    backgroundColor: AppColors.purpleSoft,
                                  ),
                                if (m.adaVideo)
                                  const AppStatusBadge(
                                    label: 'Video',
                                    color: AppColors.info,
                                    backgroundColor: AppColors.infoSoft,
                                  ),
                                if (m.adaKamera)
                                  AppStatusBadge(
                                    label: 'Kamera ${m.kameraHuruf}',
                                    color: AppColors.tertiary,
                                    backgroundColor: AppColors.orangeSoft,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  actionBtn(
                    'Edit',
                    AppColors.primary,
                    () => _bukaEdit(m),
                  ),
                  const SizedBox(width: 6),
                  actionBtn('Hapus', AppColors.danger, () => _hapus(m)),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (widget.embedded) {
      // Shell admin memakai `extendBody` dan halaman ini tidak punya
      // `bottomNavigationBar` sendiri, jadi FAB perlu digeser manual agar
      // melayang sedikit di atas navbar.
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: AppBottomNavBar.barTopOffset(context) + 28,
          ),
          child: fab,
        ),
        body: isi,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Management Materi', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: fab,
      body: isi,
    );
  }
}

// ============================================================
// 7. MANAGEMENT KUIS
// ============================================================

class ManagementKuisPage extends StatefulWidget {
  /// `true` bila ditampilkan di dalam tab shell admin (tanpa AppBar).
  final bool embedded;

  const ManagementKuisPage({super.key, this.embedded = false});

  @override
  State<ManagementKuisPage> createState() => _ManagementKuisPageState();
}

class _ManagementKuisPageState extends State<ManagementKuisPage> {
  final AdminService _service = AdminService();

  List<KuisAdminItem> _kuis = const [];
  List<KuisAdminItem> _latihan = const [];
  List<MateriAdminItem> _materi = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final kuis = await _service.fetchKuisAdmin();
      final latihan = await _service.fetchLatihanAdmin();
      final materi = await _service.fetchMateriAdmin();
      if (!mounted) return;
      setState(() {
        _kuis = kuis.where((k) => !k.isLatihan).toList();
        _latihan = latihan;
        _materi = materi;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bukaSoal(KuisAdminItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SoalKuisAdminPage(kuis: item)),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  void _bukaEditKuis(KuisAdminItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditKuisAdminPage(kuis: item)),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  Future<void> _formLatihan(KuisAdminItem? existing) async {
    final judul = TextEditingController(text: existing?.judul ?? '');
    final xp = TextEditingController(text: '${existing?.xpReward ?? 10}');
    final simpan = await showAppDialog(
      context,
      title: existing == null ? 'Tambah Latihan Soal' : 'Edit Latihan Soal',
      message: 'Latihan soal mandiri tidak terikat satu materi.',
      icon: Icons.quiz_rounded,
      confirmLabel: 'Simpan',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(judul, 'Judul latihan'),
          const SizedBox(height: 10),
          _field(xp, 'XP reward', keyboard: TextInputType.number),
        ],
      ),
    );
    final judulTeks = judul.text.trim();
    final xpAngka = int.tryParse(xp.text.trim()) ?? (existing?.xpReward ?? 10);
    judul.dispose();
    xp.dispose();

    if (simpan != true) return;
    if (judulTeks.isEmpty) {
      if (!mounted) return;
      toast(context, 'Judul latihan wajib diisi.', type: AppSnackType.warning);
      return;
    }
    try {
      await _service.simpanLatihan(
        id: existing?.id,
        judul: judulTeks,
        xpReward: xpAngka,
      );
      await _service.catatLog(
        '${existing == null ? 'Menambah' : 'Mengedit'} latihan soal '
        '"$judulTeks"',
      );
      if (!mounted) return;
      toast(
        context,
        existing == null ? 'Latihan ditambahkan.' : 'Latihan diperbarui.',
        type: AppSnackType.success,
      );
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  void _bukaWizard() {
    if (_materi.isEmpty) {
      toast(context, 'Tambahkan materi terlebih dahulu.',
          type: AppSnackType.warning);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WizardKuisPage(materi: _materi)),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  Future<void> _hapus(KuisAdminItem item) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus kuis?',
      message: '"${item.judul}" beserta soal terkait akan dihapus.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusKuis(item.id);
      await _service.catatLog('Menghapus kuis "${item.judul}"');
      if (!mounted) return;
      toast(context, 'Kuis dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Widget _kartuKuis(KuisAdminItem k) {
    final materiJudul = k.isLatihan
        ? 'Latihan soal mandiri'
        : (_materi
                .where((m) => m.id == k.materiId)
                .map((m) => m.judul)
                .firstOrNull ??
            'Tanpa materi');
    return itemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  k.isLatihan ? Icons.quiz_rounded : Icons.assignment_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$materiJudul • ${k.jumlahSoal}/$maksSoalPerKuis soal • '
                      '+${k.xpReward} XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              actionBtn(
                'Soal (${k.jumlahSoal})',
                AppColors.secondary,
                () => _bukaSoal(k),
              ),
              actionBtn(
                'Edit',
                AppColors.primary,
                () => k.isLatihan ? _formLatihan(k) : _bukaEditKuis(k),
              ),
              actionBtn('Hapus', AppColors.danger, () => _hapus(k)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fab = AppFab(
      label: 'Kuis',
      onPressed: _bukaWizard,
    );
    final isi = RefreshIndicator(
      onRefresh: _muat,
      child: adminAsync<KuisAdminItem>(
        loading: _loading,
        error: _error,
        tabelSiap: true,
        data: [..._kuis, ..._latihan],
        onRetry: _muat,
        emptyTitle: 'Belum ada kuis',
        emptyMessage: 'Tambahkan kuis pertama lewat tombol di bawah.',
        builder: (_) => ListView(
          padding: EdgeInsets.only(
            bottom: widget.embedded
                ? AppBottomNavBar.reservedSpace(context) + 16
                : 100,
            top: 4,
          ),
          children: [
            _judulSeksi(
              'Kuis Materi',
              '${_kuis.length} kuis, maksimal $maksSoalPerKuis soal',
            ),
            if (_kuis.isEmpty)
              _seksiKosong('Belum ada kuis materi.')
            else
              ..._kuis.map(_kartuKuis),
            const SizedBox(height: 20),
            _judulSeksi(
              'Latihan Soal Mandiri',
              '${_latihan.length} latihan, tidak terikat materi',
              trailing: actionBtn(
                'Tambah Latihan',
                AppColors.secondary,
                () => _formLatihan(null),
              ),
            ),
            if (_latihan.isEmpty)
              _seksiKosong('Belum ada latihan soal mandiri.')
            else
              ..._latihan.map(_kartuKuis),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: AppBottomNavBar.barTopOffset(context) + 28,
          ),
          child: fab,
        ),
        body: isi,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Management Kuis', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: fab,
      body: isi,
    );
  }

  Widget _judulSeksi(String judul, String subtitle, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: AppTextStyles.titleMedium),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _seksiKosong(String pesan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        pesan,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

// ============================================================
// 7b. KELOLA SOAL KUIS
// ============================================================

/// Kelola soal satu kuis/latihan: teks atau bergambar, maksimal 20 soal.
class SoalKuisAdminPage extends StatefulWidget {
  final KuisAdminItem kuis;

  const SoalKuisAdminPage({super.key, required this.kuis});

  @override
  State<SoalKuisAdminPage> createState() => _SoalKuisAdminPageState();
}

class _SoalKuisAdminPageState extends State<SoalKuisAdminPage> {
  final AdminService _service = AdminService();

  List<SoalAdminItem> _soal = const [];
  bool _loading = true;
  String? _error;

  bool get _penuh => _soal.length >= maksSoalPerKuis;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchSoalAdmin(widget.kuis.id);
      if (!mounted) return;
      setState(() => _soal = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _form(SoalAdminItem? existing) {
    if (existing == null && _penuh) {
      toast(
        context,
        'Batas $maksSoalPerKuis soal sudah tercapai. Hapus soal lain dulu.',
        type: AppSnackType.warning,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSoalKuisPage(
          kuisId: widget.kuis.id,
          judulKuis: widget.kuis.judul,
          nomorAwal: _soal.length + 1,
          soal: existing,
        ),
      ),
    ).then((_) {
      if (mounted) _muat();
    });
  }

  Future<void> _hapus(SoalAdminItem item) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus soal ini?',
      message: 'Soal akan hilang dari kuis "${widget.kuis.judul}".',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusSoal(item.id);
      await _service.catatLog('Menghapus soal "${widget.kuis.judul}"');
      if (!mounted) return;
      toast(context, 'Soal dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Widget _gambar(String url, {double height = 120}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          alignment: Alignment.center,
          color: AppColors.surfaceMuted,
          child: const Icon(Icons.broken_image_rounded,
              color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _kartuSoal(SoalAdminItem s, int index) {
    return itemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Soal ${index + 1}',
                style: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (s.adaGambar)
                const AppStatusBadge(
                  label: 'Bergambar',
                  color: AppColors.secondary,
                  backgroundColor: AppColors.purpleSoft,
                ),
              const Spacer(),
              actionBtn('Edit', AppColors.primary, () => _form(s)),
              const SizedBox(width: 6),
              actionBtn('Hapus', AppColors.danger, () => _hapus(s)),
            ],
          ),
          const SizedBox(height: 8),
          if (s.pertanyaan.isNotEmpty)
            Text(s.pertanyaan,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          if (s.gambarPertanyaan != null) ...[
            const SizedBox(height: 8),
            _gambar(s.gambarPertanyaan!),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < s.opsi.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    String.fromCharCode(65 + i) == s.jawabanBenar
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: String.fromCharCode(65 + i) == s.jawabanBenar
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${String.fromCharCode(65 + i)}. ${s.opsi[i]}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (i < s.opsiGambar.length &&
                            s.opsiGambar[i].trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _gambar(s.opsiGambar[i], height: 70),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (s.penjelasan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text('Penjelasan: ${s.penjelasan}',
                  style: AppTextStyles.bodySmall),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Soal Kuis', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: AppFab(
        label: _penuh ? 'Batas $maksSoalPerKuis soal' : 'Soal',
        icon: _penuh ? Icons.block_rounded : Icons.add_rounded,
        muted: _penuh,
        onPressed: () => _form(null),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.kuis.judul, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${_soal.length} dari $maksSoalPerKuis soal • '
                  '+${widget.kuis.xpReward} XP',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muat,
              child: adminAsync<SoalAdminItem>(
                loading: _loading,
                error: _error,
                tabelSiap: true,
                data: _soal,
                onRetry: _muat,
                emptyTitle: 'Belum ada soal',
                emptyMessage: 'Tambahkan soal pertama lewat tombol di bawah. '
                    'Soal bisa berupa teks, gambar, atau keduanya.',
                builder: (data) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100, top: 4),
                  itemCount: data.length,
                  itemBuilder: (context, i) => _kartuSoal(data[i], i),
                ),
              ),
            ),
          ),
        ],
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
  State<BroadcastNotifikasiPage> createState() =>
      _BroadcastNotifikasiPageState();
}

class _BroadcastNotifikasiPageState extends State<BroadcastNotifikasiPage> {
  final AdminService _service = AdminService();
  final TextEditingController _judul = TextEditingController();
  final TextEditingController _isi = TextEditingController();
  String _target = 'Semua Pengguna';
  bool _mengirim = false;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final judul = _judul.text.trim();
    final isi = _isi.text.trim();
    if (judul.isEmpty || isi.isEmpty) {
      toast(context, 'Judul dan isi pengumuman wajib diisi.',
          type: AppSnackType.warning);
      return;
    }
    final ok = await showAppDialog(
      context,
      title: 'Kirim pengumuman?',
      message: 'Pesan akan dikirim ke $_target.',
      icon: Icons.campaign_rounded,
      confirmLabel: 'Kirim',
    );
    if (ok != true) return;

    setState(() => _mengirim = true);
    try {
      final jumlah = await _service.kirimBroadcast(
          judul: judul, isi: isi, target: _target);
      if (!mounted) return;
      _judul.clear();
      _isi.clear();
      toast(context, 'Pengumuman terkirim ke $jumlah pengguna.',
          type: AppSnackType.success);
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Broadcast Notifikasi',
      subtitle: 'Pengumuman akan masuk ke notifikasi aplikasi pengguna',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Target Penerima',
              style: AppTextStyles.labelMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _target,
            isExpanded: true,
            decoration: _fieldDeco('Target'),
            items: const [
              'Semua Pengguna',
              'Hanya Pembelajar',
              'Hanya Mentor Tuli',
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _target = v ?? _target),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _judul,
            decoration: _fieldDeco('Judul pengumuman'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _isi,
            maxLines: 5,
            decoration: _fieldDeco('Isi pengumuman...'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _mengirim ? null : _kirim,
              icon: _mengirim
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(_mengirim ? 'Mengirim...' : 'Kirim Sekarang'),
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
  final AdminService _service = AdminService();

  AdminList<BannerItem> _list = AdminList.kosongBelumSiap.cast();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchBanner();
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tambah() async {
    final judul = TextEditingController();
    final simpan = await showAppDialog(
      context,
      title: 'Tambah Banner',
      icon: Icons.campaign_rounded,
      confirmLabel: 'Simpan',
      content: _field(judul, 'Judul banner promo'),
    );
    final teks = judul.text.trim();
    judul.dispose();
    if (simpan != true) return;
    if (teks.isEmpty) {
      if (!mounted) return;
      toast(context, 'Judul banner wajib diisi.', type: AppSnackType.warning);
      return;
    }
    try {
      await _service.simpanBanner(teks);
      await _service.catatLog('Menambah banner "$teks"');
      if (!mounted) return;
      toast(context, 'Banner ditambahkan.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _toggle(BannerItem item, bool aktif) async {
    try {
      await _service.setBannerAktif(item.id, aktif);
      await _service.catatLog(
        '${aktif ? 'Mengaktifkan' : 'Menonaktifkan'} banner "${item.judul}"',
      );
      if (!mounted) return;
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  Future<void> _hapus(BannerItem item) async {
    final ok = await showAppDialog(
      context,
      title: 'Hapus banner?',
      message: '"${item.judul}" akan dihapus permanen.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (ok != true) return;
    try {
      await _service.hapusBanner(item.id);
      await _service.catatLog('Menghapus banner "${item.judul}"');
      if (!mounted) return;
      toast(context, 'Banner dihapus.', type: AppSnackType.success);
      _muat();
    } catch (e) {
      if (!mounted) return;
      toast(context, _pesan(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Banner & Promo', style: AppTextStyles.headlineSmall),
      ),
      floatingActionButton: AppFab(
        label: 'Banner',
        onPressed: _tambah,
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<BannerItem>(
          loading: _loading,
          error: _error,
          tabelSiap: _list.tabelTersedia || _loading,
          data: _list.data,
          onRetry: _muat,
          emptyTitle: 'Belum ada banner',
          emptyMessage: 'Tambahkan banner promo pertama lewat tombol di bawah.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 4),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final b = data[i];
              return itemCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.pinkSoft, AppColors.purpleSoft],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            b.aktif ? 'Aktif ditampilkan' : 'Nonaktif',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: b.aktif
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: b.aktif,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => _toggle(b, v),
                    ),
                    actionBtn('Hapus', AppColors.danger, () => _hapus(b)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 10. LOG AKTIVITAS ADMIN
// ============================================================

class LogAktivitasPage extends StatefulWidget {
  const LogAktivitasPage({super.key});

  @override
  State<LogAktivitasPage> createState() => _LogAktivitasPageState();
}

class _LogAktivitasPageState extends State<LogAktivitasPage> {
  final AdminService _service = AdminService();

  AdminList<LogItem> _list = AdminList.kosongBelumSiap.cast();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchLog();
      if (!mounted) return;
      setState(() => _list = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _pesan(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminPage(
      context: context,
      title: 'Log Aktivitas Admin',
      subtitle: '${_list.data.length} aksi terakhir',
      child: RefreshIndicator(
        onRefresh: _muat,
        child: adminAsync<LogItem>(
          loading: _loading,
          error: _error,
          tabelSiap: _list.tabelTersedia || _loading,
          data: _list.data,
          onRetry: _muat,
          emptyTitle: 'Belum ada log',
          emptyMessage: 'Belum ada aktivitas admin yang tercatat.',
          builder: (data) => ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final l = data[i];
              return itemCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.adminNama} — ${l.aksi}',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.waktu,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Field helper
// ============================================================

InputDecoration _fieldDeco(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide.none,
      ),
    );

Widget _field(
  TextEditingController controller,
  String hint, {
  int maxLines = 1,
  TextInputType? keyboard,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboard,
    decoration: _fieldDeco(hint),
  );
}
