import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../services/share_service.dart';
import '../main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Menampilkan pilihan berbagi: kirim lewat pesan atau buat postingan
/// di komunitas.
Future<void> showShareSheet(
  BuildContext context, {
  required String text,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ShareSheet(text: text),
  );
}

class _ShareSheet extends StatefulWidget {
  final String text;

  const _ShareSheet({required this.text});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _choosingContact = false;

  void _shareToCommunity() {
    ShareService.queueCommunityPost(widget.text);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 3)),
      (_) => false,
    );
  }

  Future<void> _openContactPicker() async {
    await context.read<ChatController>().loadContacts();
    if (!mounted) return;
    setState(() => _choosingContact = true);
  }

  Future<void> _sendToContact(ChatController controller, String name) async {
    final contact = controller.contacts.firstWhere((c) => c.name == name);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    await controller.startChat(contact);
    await controller.sendMessage(widget.text);
    messenger.showSnackBar(
      SnackBar(content: Text('Terkirim ke ${contact.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: _choosingContact ? _buildContactList() : _buildOptions(),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Bagikan ke', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.purpleSoft,
            child: Icon(Icons.groups_rounded, color: AppColors.secondary),
          ),
          title: const Text('Komunitas',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Jadikan postingan baru di Komunitas'),
          onTap: _shareToCommunity,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.pinkSoft,
            child: Icon(Icons.chat_rounded, color: AppColors.primary),
          ),
          title: const Text('Pesan',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Kirim ke teman lewat chat'),
          onTap: _openContactPicker,
        ),
      ],
    );
  }

  Widget _buildContactList() {
    final controller = context.watch<ChatController>();
    return SizedBox(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _choosingContact = false),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text('Kirim ke', style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: controller.isLoadingContacts
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: controller.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = controller.contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.pinkSoft,
                          backgroundImage: contact.avatarUrl != null
                              ? NetworkImage(contact.avatarUrl!)
                              : null,
                          child: contact.avatarUrl == null
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        title: Text(contact.name),
                        onTap: () => _sendToContact(controller, contact.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
