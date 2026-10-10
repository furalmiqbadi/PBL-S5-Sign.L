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
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Consumer<ChatController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                const Divider(height: 1),
                Expanded(child: _buildMessages(controller)),
                _buildInputBar(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      title: Row(
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
                      : (widget.room.isOnline ? 'Aktif sekarang' : 'Terakhir dilihat baru-baru ini'),
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
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  Widget _buildMessages(ChatController controller) {
    if (controller.isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final messages = controller.activeMessages;
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Mulai percakapan dengan sapaan hangat 👋',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: items,
    );
  }

  Widget _buildInputBar(ChatController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
              onTap: controller.isSending
                  ? null
                  : () => _handleSend(controller),
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
