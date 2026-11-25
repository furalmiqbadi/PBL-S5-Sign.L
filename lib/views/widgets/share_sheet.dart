import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../services/share_service.dart';
import '../main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_ui.dart';
import 'user_avatar.dart';

/// Menampilkan pilihan berbagi: kirim lewat pesan atau buat postingan
/// di komunitas.
Future<void> showShareSheet(
  BuildContext context, {
  required String text,
  String? mediaUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ShareSheet(text: text, mediaUrl: mediaUrl),
  );
}

class _ShareSheet extends StatefulWidget {
  final String text;
  final String? mediaUrl;

  const _ShareSheet({required this.text, this.mediaUrl});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _choosingContact = false;

  void _shareToCommunity() {
    ShareService.queueCommunityPost(widget.text, mediaUrl: widget.mediaUrl);
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
    final rootContext = context;
    Navigator.pop(context);
    await controller.startChat(contact);
    await controller.sendMessage(widget.text);
    if (!rootContext.mounted) return;
    showAppSnackBar(
      rootContext,
      'Terkirim ke ${contact.name}',
      type: AppSnackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
        const SizedBox(height: 10),
        AppSheetOptionTile(
          icon: Icons.groups_rounded,
          iconColor: AppColors.secondary,
          iconBackground: AppColors.purpleSoft,
          title: 'Komunitas',
          subtitle: 'Jadikan postingan baru di Komunitas',
          onTap: _shareToCommunity,
        ),
        AppSheetOptionTile(
          icon: Icons.chat_rounded,
          iconColor: AppColors.primary,
          iconBackground: AppColors.pinkSoft,
          title: 'Pesan',
          subtitle: 'Kirim ke teman lewat chat',
          onTap: _openContactPicker,
        ),
      ],
    );
  }

  Widget _buildContactList() {
    final controller = context.watch<ChatController>();
    return SizedBox(
      height: 340,
      child: Column(
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
          const SizedBox(height: 8),
          Row(
            children: [
              AppIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Kembali',
                onPressed: () => setState(() => _choosingContact = false),
              ),
              const SizedBox(width: 6),
              Text('Kirim ke', style: AppTextStyles.titleLarge),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: controller.isLoadingContacts
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: controller.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = controller.contacts[index];
                      return ListTile(
                        leading: UserAvatar(
                          imageUrl: contact.avatarUrl,
                          name: contact.name,
                          size: 40,
                        ),
                        title:
                            Text(contact.name, style: AppTextStyles.titleSmall),
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
