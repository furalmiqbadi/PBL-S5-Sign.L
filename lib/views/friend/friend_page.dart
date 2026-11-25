import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/friend_controller.dart';
import '../../models/chat_model.dart';
import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../chat/chat_room_view.dart';
import '../common/pushed_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/user_list_tile.dart';

/// Halaman Teman: daftar teman, permintaan masuk/keluar, dan saran teman.
class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  int _index = 0;

  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  Timer? _debounce;
  String _query = '';
  bool _mencari = false;
  String? _errorCari;
  List<Teman> _hasilCari = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final teman = context.read<FriendController>();
      teman.load(force: true);
      teman.loadSaran();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _ubahQuery(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _hasilCari = const [];
        _errorCari = null;
        _mencari = false;
      });
      return;
    }
    setState(() {
      _mencari = true;
      _errorCari = null;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () => _cari(q));
  }

  Future<void> _cari(String q) async {
    try {
      final hasil = await _friendService.cariPengguna(q);
      if (!mounted) return;
      setState(() {
        _hasilCari = hasil;
        _errorCari = null;
      });
      await context.read<FriendController>().muatStatus(
            hasil.map((e) => e.id).toList(),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasilCari = const [];
        _errorCari = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Pencarian gagal. Coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  Future<void> _segarkan() async {
    final teman = context.read<FriendController>();
    await Future.wait([
      teman.load(force: true),
      teman.loadSaran(),
    ]);
  }

  Future<void> _bukaChat(Teman orang) async {
    final chat = context.read<ChatController>();

    try {
      final room = await chat.startChat(
        ChatContact(
          id: orang.id,
          name: orang.nama,
          username: orang.username,
          avatarUrl: orang.avatarUrl,
          role: orang.role,
        ),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Percakapan gagal dibuka. Coba lagi.',
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _aksi(Future<bool> Function() jalan) async {
    final teman = context.read<FriendController>();
    final berhasil = await jalan();
    if (!mounted) return;
    if (!berhasil) {
      showAppSnackBar(
        context,
        teman.errorMessage ?? 'Aksi gagal. Coba lagi.',
        type: AppSnackType.error,
      );
    }
  }

  Future<void> _hapusTeman(Teman orang) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
        ),
        title: const Text('Hapus teman?'),
        content: Text('${orang.nama} akan dihapus dari daftar temanmu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    await _aksi(() => context.read<FriendController>().hapusTeman(orang.id));
  }

  void _menuTeman(Teman orang, String aksi) {
    if (aksi == 'pesan') {
      _bukaChat(orang);
    } else if (aksi == 'hapus') {
      _hapusTeman(orang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teman = context.watch<FriendController>();
    final label = [
      'Teman',
      teman.jumlahPermintaan > 0
          ? 'Permintaan · ${teman.jumlahPermintaan}'
          : 'Permintaan',
      'Saran',
    ];

    return PushedPage(
      title: 'Teman',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _ubahQuery,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari nama atau @username...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Bersihkan',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _ubahQuery('');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: AppColors.fieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: _softFieldBorder,
                enabledBorder: _softFieldBorder,
                focusedBorder: _softFieldBorder,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: FilterChipRow(
              labels: label,
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _segarkan,
              child: _isi(teman),
            ),
          ),
        ],
      ),
    );
  }

  static final OutlineInputBorder _softFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide.none,
  );

  Widget _isi(FriendController teman) {
    if (_query.trim().length >= 2) return _daftarHasilCari(teman);

    if (teman.isLoading &&
        teman.teman.isEmpty &&
        teman.permintaanMasuk.isEmpty &&
        teman.saran.isEmpty) {
      return const _PusatPesan(
        icon: Icons.people_alt_outlined,
        message: 'Memuat data teman...',
        loading: true,
      );
    }

    if (teman.errorMessage != null && teman.teman.isEmpty) {
      return _PusatPesan(
        icon: Icons.wifi_off_rounded,
        message: teman.errorMessage!,
        actionLabel: 'Coba lagi',
        onAction: _segarkan,
      );
    }

    return switch (_index) {
      1 => _daftarPermintaan(teman),
      2 => _daftarSaran(teman),
      _ => _daftarTeman(teman),
    };
  }

  Widget _daftarHasilCari(FriendController teman) {
    if (_mencari) {
      return const _PusatPesan(
        icon: Icons.search_rounded,
        message: 'Mencari pengguna...',
        loading: true,
      );
    }

    if (_errorCari != null) {
      return _PusatPesan(
        icon: Icons.wifi_off_rounded,
        message: _errorCari!,
        actionLabel: 'Coba lagi',
        onAction: () => _cari(_query.trim()),
      );
    }

    if (_hasilCari.isEmpty) {
      return const _PusatPesan(
        icon: Icons.person_search_outlined,
        message: 'Tidak ada pengguna yang cocok.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const BagianLabel(label: 'Hasil pencarian'),
        for (final orang in _hasilCari)
          UserListTile(
            nama: orang.nama,
            username: orang.username,
            peran: orang.peran,
            avatarUrl: orang.avatarUrl,
            trailing: TemanStatusAksi(
              status: teman.statusUntuk(orang.id) == StatusTeman.tidakAda
                  ? orang.status
                  : teman.statusUntuk(orang.id),
              sibuk: teman.sedangMemproses(orang.id),
              onTambah: () => _aksi(() => teman.tambahTeman(orang.id)),
              onBatalkan: () => _aksi(() => teman.batalkan(orang.id)),
              onIkutiBalik: () => _aksi(() => teman.ikutiBalik(orang.id)),
              onBuka: () => _bukaChat(orang),
            ),
          ),
      ],
    );
  }

  Widget _daftarTeman(FriendController teman) {
    if (teman.teman.isEmpty) {
      return const _PusatPesan(
        icon: Icons.group_add_outlined,
        message:
            'Belum ada teman.\nCari orang di tab Saran atau lewat pencarian.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: teman.teman.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final orang = teman.teman[i];
        return UserListTile(
          nama: orang.nama,
          username: orang.username,
          peran: orang.peran,
          avatarUrl: orang.avatarUrl,
          onTap: () => _bukaChat(orang),
          trailing: PopupMenuButton<String>(
            tooltip: 'Aksi teman',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSecondary,
            ),
            onSelected: (aksi) => _menuTeman(orang, aksi),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pesan',
                child: Text('Kirim pesan'),
              ),
              PopupMenuItem(
                value: 'hapus',
                child: Text('Hapus teman'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _daftarPermintaan(FriendController teman) {
    final masuk = teman.permintaanMasuk;
    final keluar = teman.permintaanKeluar;

    if (masuk.isEmpty && keluar.isEmpty) {
      return const _PusatPesan(
        icon: Icons.mark_email_unread_outlined,
        message: 'Tidak ada permintaan teman.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (masuk.isNotEmpty) const BagianLabel(label: 'Permintaan masuk'),
        for (final p in masuk)
          UserListTile(
            nama: p.pengguna.nama,
            username: p.pengguna.username,
            peran: p.pengguna.peran,
            avatarUrl: p.pengguna.avatarUrl,
            subtitle: 'Ingin berteman denganmu',
            trailing: _AksiPermintaanMasuk(
              sibuk: teman.sedangMemproses(p.pengguna.id),
              onTerima: () => _aksi(() => teman.terimaPermintaan(p.pengguna)),
              onTolak: () => _aksi(() => teman.tolakPermintaan(p.pengguna)),
            ),
          ),
        if (keluar.isNotEmpty) const BagianLabel(label: 'Permintaan terkirim'),
        for (final p in keluar)
          UserListTile(
            nama: p.pengguna.nama,
            username: p.pengguna.username,
            peran: p.pengguna.peran,
            avatarUrl: p.pengguna.avatarUrl,
            subtitle: 'Menunggu jawaban',
            trailing: teman.sedangMemproses(p.pengguna.id)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : TemanPillButton(
                    label: 'Batalkan',
                    minWidth: 76,
                    onPressed: () => _aksi(() => teman.batalkan(p.pengguna.id)),
                  ),
          ),
      ],
    );
  }

  Widget _daftarSaran(FriendController teman) {
    if (teman.saran.isEmpty) {
      return const _PusatPesan(
        icon: Icons.person_search_outlined,
        message: 'Belum ada saran teman.\nCoba lagi nanti.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const BagianLabel(label: 'Mungkin kamu kenal'),
        for (final orang in teman.saran)
          UserListTile(
            nama: orang.nama,
            username: orang.username,
            peran: orang.peran,
            avatarUrl: orang.avatarUrl,
            trailing: TemanStatusAksi(
              status: teman.statusUntuk(orang.id) == StatusTeman.tidakAda
                  ? orang.status
                  : teman.statusUntuk(orang.id),
              sibuk: teman.sedangMemproses(orang.id),
              onTambah: () => _aksi(() => teman.tambahTeman(orang.id)),
              onBatalkan: () => _aksi(() => teman.batalkan(orang.id)),
              onIkutiBalik: () => _aksi(() => teman.ikutiBalik(orang.id)),
              onBuka: () => _bukaChat(orang),
            ),
          ),
      ],
    );
  }
}

/// Tombol Terima/Tolak untuk satu permintaan masuk.
class _AksiPermintaanMasuk extends StatelessWidget {
  const _AksiPermintaanMasuk({
    required this.sibuk,
    required this.onTerima,
    required this.onTolak,
  });

  final bool sibuk;
  final VoidCallback onTerima;
  final VoidCallback onTolak;

  @override
  Widget build(BuildContext context) {
    if (sibuk) {
      return const SizedBox(
        width: 96,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onTolak,
          style: TextButton.styleFrom(
            minimumSize: const Size(56, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: AppColors.textSecondary,
            textStyle: AppTextStyles.labelMedium,
          ),
          child: const Text('Tolak'),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: onTerima,
          style: FilledButton.styleFrom(
            minimumSize: const Size(66, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            textStyle: AppTextStyles.labelMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          child: const Text('Terima'),
        ),
      ],
    );
  }
}

/// Pesan status di tengah area daftar (memuat, kosong, atau galat).
class _PusatPesan extends StatelessWidget {
  const _PusatPesan({
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      children: [
        Icon(icon, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (loading) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TemanPillButton(
              label: actionLabel!,
              onPressed: onAction,
              terisi: true,
            ),
          ),
        ],
      ],
    );
  }
}
