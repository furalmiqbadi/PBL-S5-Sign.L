import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/friend_controller.dart';
import '../../models/chat_model.dart';
import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/user_list_tile.dart';

/// Bottom sheet untuk memilih lawan bicara atau menemukan orang baru.
///
/// Mengembalikan [ChatContact] yang dipilih melalui `Navigator.pop`.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();

  Timer? _debounce;
  String _query = '';
  bool _mencari = false;
  List<Teman> _hasilCari = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatController>().loadContacts();
      context.read<FriendController>().load();
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
        _mencari = false;
      });
      return;
    }

    setState(() => _mencari = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _cari(q));
  }

  Future<void> _cari(String q) async {
    try {
      final hasil = await _friendService.cariPengguna(q);
      if (!mounted) return;
      setState(() => _hasilCari = hasil);
      await context
          .read<FriendController>()
          .muatStatus(hasil.map((e) => e.id).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasilCari = const []);
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  void _buatRuang(ChatContact contact) => Navigator.pop(context, contact);

  Future<void> _aksiTeman(Future<bool> Function() jalan) async {
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

  List<ChatContact> _saringKontak(List<ChatContact> contacts) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.username.toLowerCase().contains(q))
        .toList();
  }

  List<Teman> _orangLain(List<ChatContact> contacts) {
    if (_hasilCari.isEmpty) return const [];
    final idKontak = contacts.map((c) => c.id).toSet();
    return _hasilCari.where((t) => !idKontak.contains(t.id)).toList();
  }

  static final OutlineInputBorder _softFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final teman = context.watch<FriendController>();
    final contacts = _saringKontak(chat.contacts);
    final orangLain = _orangLain(chat.contacts);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text('Pesan baru', style: AppTextStyles.titleLarge),
                    ),
                    AppIconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.close_rounded,
                      tooltip: 'Tutup',
                      backgroundColor: AppColors.surfaceMuted,
                      borderColor: Colors.transparent,
                      size: 40,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _ubahQuery,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau @username...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: _softFieldBorder,
                    enabledBorder: _softFieldBorder,
                    focusedBorder: _softFieldBorder,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _ubahQuery('');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildIsi(
                  chat: chat,
                  teman: teman,
                  contacts: contacts,
                  orangLain: orangLain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIsi({
    required ChatController chat,
    required FriendController teman,
    required List<ChatContact> contacts,
    required List<Teman> orangLain,
  }) {
    final sedangMemuat = chat.isLoadingContacts || teman.isLoading;
    if (sedangMemuat && contacts.isEmpty && _hasilCari.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final kosong = contacts.isEmpty && orangLain.isEmpty;
    if (kosong) {
      if (_mencari) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _query.trim().length < 2
                ? 'Belum ada kontak. Ketik minimal 2 huruf untuk\nmencari pengguna lain.'
                : 'Tidak ada pengguna yang cocok.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        if (contacts.isNotEmpty) ...[
          BagianLabel(label: _query.trim().isEmpty ? 'Kontak' : 'Kontak cocok'),
          for (final contact in contacts)
            UserListTile(
              nama: contact.name,
              username: contact.username,
              peran: contact.peran,
              avatarUrl: contact.avatarUrl,
              isOnline: contact.isOnline,
              trailing: TemanStatusAksi(
                status: teman.statusUntuk(contact.id),
                sibuk: teman.sedangMemproses(contact.id),
                onTambah: () => _aksiTeman(() => teman.tambahTeman(contact.id)),
                onBatalkan: () => _aksiTeman(() => teman.batalkan(contact.id)),
                onIkutiBalik: () =>
                    _aksiTeman(() => teman.ikutiBalik(contact.id)),
                onBuka: () => _buatRuang(contact),
              ),
              onTap: teman.statusUntuk(contact.id) == StatusTeman.berteman
                  ? () => _buatRuang(contact)
                  : null,
            ),
        ],
        if (orangLain.isNotEmpty) ...[
          if (contacts.isNotEmpty) const SizedBox(height: 8),
          const BagianLabel(label: 'Orang lain'),
          for (final orang in orangLain)
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
                onTambah: () => _aksiTeman(() => teman.tambahTeman(orang.id)),
                onBatalkan: () => _aksiTeman(() => teman.batalkan(orang.id)),
                onIkutiBalik: () =>
                    _aksiTeman(() => teman.ikutiBalik(orang.id)),
                onBuka: () => Navigator.pop(
                  context,
                  ChatContact(
                    id: orang.id,
                    name: orang.nama,
                    username: orang.username,
                    avatarUrl: orang.avatarUrl,
                    role: orang.role,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
