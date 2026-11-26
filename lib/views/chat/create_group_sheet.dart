import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/user_avatar.dart';

/// Data yang dikembalikan [CreateGroupSheet] saat pengguna menekan "Buat grup".
typedef NewGroupDraft = ({String name, List<ChatContact> members});

/// Bottom sheet untuk membuat grup chat: isi nama grup lalu pilih anggota.
class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  String _query = '';

  static final OutlineInputBorder _softFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadContacts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  List<ChatContact> _selectedContacts(List<ChatContact> contacts) {
    return contacts
        .where((contact) => _selectedIds.contains(contact.id))
        .toList();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedIds.isNotEmpty;

  void _toggle(String contactId) {
    setState(() {
      if (!_selectedIds.remove(contactId)) {
        _selectedIds.add(contactId);
      }
    });
  }

  void _submit() {
    final controller = context.read<ChatController>();
    final draft = (
      name: _nameController.text.trim(),
      members: _selectedContacts(controller.contacts),
    );
    Navigator.pop(context, draft);
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
          height: MediaQuery.sizeOf(context).height * 0.85,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Grup baru', style: AppTextStyles.titleLarge),
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
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Nama grup',
                    prefixIcon: const Icon(
                      Icons.groups_rounded,
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
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari anggota...',
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
                    : controller.contactsErrorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.contactsErrorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.loadContacts,
                                  child: const Text('Coba lagi'),
                                ),
                              ],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                itemCount: contacts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  final selected =
                                      _selectedIds.contains(contact.id);
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    onTap: () => _toggle(contact.id),
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
                                          : 'Tersedia di kontak',
                                      style: AppTextStyles.labelSmall,
                                    ),
                                    trailing: Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  );
                                },
                              ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canCreate ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Buat grup'
                          : 'Buat grup (${_selectedIds.length} anggota)',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
