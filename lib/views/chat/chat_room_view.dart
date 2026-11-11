import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/user_avatar.dart';

/// Layar detail percakapan dengan satu ruang chat.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.room});

  final ChatRoom room;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ChatController>();
      controller.openRoom(widget.room).then((_) {
        if (mounted) _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend(ChatController controller) async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await controller.sendMessage(text);
    if (!mounted) return;

    if (controller.roomErrorMessage != null) {
      _showSnack(controller.roomErrorMessage!);
      return;
    }
    _scrollToBottom();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(controller),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(child: _buildMessages(controller)),
                _buildInputBar(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ChatController controller) {
    final muted = controller.isMuted(widget.room.id);

    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showRoomInfo(controller),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: widget.room.avatarUrl,
              name: widget.room.name,
              isGroup: widget.room.isGroup,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    widget.room.isGroup
                        ? '${widget.room.memberCount ?? 0} anggota'
                        : (widget.room.isOnline
                            ? 'Aktif sekarang'
                            : 'Terakhir dilihat baru-baru ini'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: widget.room.isOnline
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (muted)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        IconButton(
          tooltip: 'Opsi percakapan',
          onPressed: () => _showRoomMenu(controller),
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  void _showRoomMenu(ChatController controller) {
    final room = widget.room;
    final muted = controller.isMuted(room.id);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Lihat profil'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomInfo(controller);
                },
              ),
              ListTile(
                leading: Icon(
                  muted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                ),
                title: Text(
                  muted ? 'Bunyikan notifikasi' : 'Bisukan notifikasi',
                ),
                onTap: () {
                  controller.toggleMute(room.id);
                  Navigator.pop(sheetContext);
                  _showSnack(
                    muted
                        ? 'Notifikasi percakapan dibunyikan.'
                        : 'Notifikasi percakapan dibisukan.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Bersihkan riwayat'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmClearHistory(controller);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.block_rounded,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Blokir & laporkan',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRoomInfo(ChatController controller) {
    final room = widget.room;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(
                  imageUrl: room.avatarUrl,
                  name: room.name,
                  isGroup: room.isGroup,
                  size: 76,
                ),
                const SizedBox(height: 12),
                Text(room.name, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(
                  room.isGroup
                      ? '${room.memberCount ?? 0} anggota grup'
                      : (room.isOnline
                          ? 'Aktif sekarang'
                          : 'Terakhir dilihat baru-baru ini'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (room.isGroup && room.lastSenderName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pesan terakhir dari ${room.lastSenderName}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      controller.toggleMute(room.id);
                      _showSnack(
                        controller.isMuted(room.id)
                            ? 'Notifikasi percakapan dibisukan.'
                            : 'Notifikasi percakapan dibunyikan.',
                      );
                    },
                    icon: Icon(
                      controller.isMuted(room.id)
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_active_outlined,
                    ),
                    label: Text(
                      controller.isMuted(room.id)
                          ? 'Bunyikan notifikasi'
                          : 'Bisukan notifikasi',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearHistory(ChatController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bersihkan riwayat?'),
        content: const Text(
          'Semua pesan pada percakapan ini akan dihapus dari perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await controller.clearActiveMessages();
    _showSnack('Riwayat percakapan dibersihkan.');
  }

  Future<void> _confirmBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Blokir ${widget.room.name}?'),
        content: const Text(
          'Kamu tidak akan menerima pesan dari kontak ini lagi. '
          'Laporan juga akan dikirim ke moderator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Blokir',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _showSnack('${widget.room.name} diblokir dan laporan dikirim.');
    Navigator.of(context).maybePop();
  }

  Widget _buildMessages(ChatController controller) {
    if (controller.isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final messages = controller.activeMessages;
    if (messages.isEmpty) {
      if (controller.roomErrorMessage != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                controller.roomErrorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => controller.openRoom(widget.room),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Text(
          'Mulai percakapan dengan sapaan hangat 👋',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final items = <Widget>[const ChatDayDivider(label: 'Hari ini')];
    var newDividerInserted = false;
    for (final message in messages) {
      if (message.isNew && !newDividerInserted) {
        items.add(const ChatNewMessageDivider());
        newDividerInserted = true;
      }
      items.add(ChatBubble(message: message));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: items,
    );
  }

  Widget _buildInputBar(ChatController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(controller),
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap:
                  controller.isSending ? null : () => _handleSend(controller),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: controller.isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
