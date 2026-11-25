import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
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
    showAppSnackBar(context, message);
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
                if (widget.room.isReadOnly) _buildReadOnlyBanner(),
                Expanded(child: _buildMessages(controller)),
                if (widget.room.isReadOnly)
                  _buildReadOnlyFooter()
                else
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
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      toolbarHeight: 72,
      leadingWidth: 72,
      leading: Center(
        child: _buildSoftIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          iconSize: 20,
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                    widget.room.isReadOnly
                        ? 'Balasan resmi admin'
                        : widget.room.isGroup
                            ? '${widget.room.memberCount ?? 0} anggota'
                            : (widget.room.isOnline
                                ? 'Aktif sekarang'
                                : 'Terakhir dilihat baru-baru ini'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: widget.room.isReadOnly
                          ? AppColors.info
                          : widget.room.isOnline
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
        _buildSoftIconButton(
          icon: Icons.more_vert_rounded,
          tooltip: 'Opsi percakapan',
          onPressed: () => _showRoomMenu(controller),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSoftIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    double iconSize = 24,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  void _showRoomMenu(ChatController controller) {
    final room = widget.room;
    final muted = controller.isMuted(room.id);

    showAppBottomSheet<void>(
      context,
      title: room.name,
      subtitle: 'Opsi percakapan',
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetOptionTile(
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              iconBackground: AppColors.pinkSoft,
              title: 'Lihat profil',
              onTap: () {
                Navigator.pop(sheetContext);
                _showRoomInfo(controller);
              },
            ),
            if (!room.isReadOnly) ...[
              AppSheetOptionTile(
                icon: muted
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                iconColor: AppColors.secondary,
                iconBackground: AppColors.purpleSoft,
                title: muted ? 'Bunyikan notifikasi' : 'Bisukan notifikasi',
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
              AppSheetOptionTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.textSecondary,
                iconBackground: AppColors.surfaceMuted,
                title: 'Bersihkan riwayat',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmClearHistory(controller);
                },
              ),
              AppSheetOptionTile(
                icon: Icons.block_rounded,
                iconColor: AppColors.danger,
                iconBackground: AppColors.dangerSoft,
                title: 'Blokir & laporkan',
                titleColor: AppColors.danger,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  void _showRoomInfo(ChatController controller) {
    final room = widget.room;
    showAppBottomSheet<void>(
      context,
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      builder: (sheetContext) {
        return Column(
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
              room.isReadOnly
                  ? 'Ruang laporan • hanya-baca'
                  : room.isGroup
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                ),
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
        );
      },
    );
  }

  Future<void> _confirmClearHistory(ChatController controller) async {
    final confirmed = await showAppDialog(
      context,
      icon: Icons.delete_sweep_rounded,
      title: 'Bersihkan riwayat?',
      message: 'Semua pesan pada percakapan ini akan dihapus dari perangkat.',
      cancelLabel: 'Batal',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    await controller.clearActiveMessages();
    _showSnack('Riwayat percakapan dibersihkan.');
  }

  Future<void> _confirmBlock() async {
    final confirmed = await showAppDialog(
      context,
      icon: Icons.block_rounded,
      title: 'Blokir ${widget.room.name}?',
      message:
          'Kamu tidak akan menerima pesan dari kontak ini lagi. Laporan juga akan dikirim ke moderator.',
      cancelLabel: 'Batal',
      confirmLabel: 'Blokir',
      isDestructive: true,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.waving_hand_rounded,
              size: 40,
              color: AppColors.tertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai percakapan dengan sapaan hangat',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
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

  static final OutlineInputBorder _pillBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: BorderSide.none,
  );

  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ruang laporan hanya-baca. Balasan admin tercatat di sini, '
              'tapi kamu tidak bisa mengirim pesan.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Balasan resmi dari admin akan muncul di sini.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: _pillBorder,
                  enabledBorder: _pillBorder,
                  focusedBorder: _pillBorder,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: InkWell(
                    onTap: controller.isSending
                        ? null
                        : () => _handleSend(controller),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Center(
                      child: controller.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
