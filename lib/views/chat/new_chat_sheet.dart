import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/user_avatar.dart';

/// Bottom sheet untuk memilih kontak saat menulis pesan baru.
///
/// Mengembalikan [ChatContact] yang dipilih melalui `Navigator.pop`.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatContact> get _filteredContacts {
    final contacts = context.watch<ChatController>().contacts;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts
        .where((contact) => contact.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final contacts = _filteredContacts;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text('Pesan baru', style: AppTextStyles.titleLarge),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari kontak...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: controller.isLoadingContacts
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : contacts.isEmpty
                        ? Center(
                            child: Text(
                              'Kontak tidak ditemukan.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: contacts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: UserAvatar(
                                  imageUrl: contact.avatarUrl,
                                  name: contact.name,
                                  showOnlineBadge: contact.isOnline,
                                  size: 46,
                                ),
                                title: Text(
                                  contact.name,
                                  style: AppTextStyles.titleSmall,
                                ),
                                subtitle: Text(
                                  contact.isOnline
                                      ? 'Aktif sekarang'
                                      : 'Tersedia di komunitas',
                                  style: AppTextStyles.labelSmall,
                                ),
                                onTap: () => Navigator.pop(context, contact),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
