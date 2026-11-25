import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../common/pushed_page.dart';
import '../komunitas/komunitas_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_ui.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/section_header.dart';
import 'chat_room_view.dart';
import 'new_chat_sheet.dart';

/// Layar daftar percakapan (Chat).
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: AppScreenHeader(
                title: 'Chat',
                actions: [
                  HeaderIconButton(
                    icon: Icons.edit_square,
                    semanticLabel: 'Tulis pesan baru',
                    onTap: _openNewChat,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ChatController>(
                builder: (context, controller, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: _ChatSearchField(onChanged: controller.search),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FilterChipRow(
                          labels: const ['Semua', 'Belum dibaca'],
                          selectedIndex: controller.filter.index,
                          onSelected: (index) =>
                              controller.setFilter(ChatFilter.values[index]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _UnreadSummary(
                          count: controller.unreadRoomsCount,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _RoomList(
                          controller: controller,
                          onOpen: (room) => _openRoom(context, room),
                        ),
                      ),
                      _CommunityBanner(
                        onTap: () => _openCommunity(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoom(BuildContext context, ChatRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
    );
  }

  Future<void> _openNewChat() async {
    final contact = await showModalBottomSheet<ChatContact>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.dialog),
        ),
      ),
      builder: (_) => const NewChatSheet(),
    );
    if (contact == null || !mounted) return;

    final room = await context.read<ChatController>().startChat(contact);
    if (!mounted) return;
    _openRoom(context, room);
  }

  void _openCommunity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PushedPage(
          title: 'Komunitas',
          child: KomunitasPage(),
        ),
      ),
    );
  }
}

/// Kolom pencarian nama teman atau grup.
class _ChatSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _ChatSearchField({required this.onChanged});

  static final OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Cari teman atau grup belajar...',
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textMuted),
        isDense: true,
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
    );
  }
}

/// Judul bagian "Percakapan terbaru" beserta jumlah chat belum dibaca.
class _UnreadSummary extends StatelessWidget {
  final int count;

  const _UnreadSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Percakapan terbaru', style: AppTextStyles.titleMedium),
        const Spacer(),
        if (count > 0)
          Text(
            '$count chat belum dibaca',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Daftar ruang percakapan dengan state memuat, galat, dan kosong.
class _RoomList extends StatelessWidget {
  final ChatController controller;
  final ValueChanged<ChatRoom> onOpen;

  const _RoomList({required this.controller, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return _MessageState(
        icon: Icons.wifi_off_rounded,
        message: controller.errorMessage!,
        onRetry: controller.loadRooms,
      );
    }

    final rooms = controller.rooms;
    if (rooms.isEmpty) {
      return const _MessageState(
        icon: Icons.forum_outlined,
        message: 'Belum ada percakapan di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ChatListTile(room: room, onTap: () => onOpen(room));
      },
    );
  }
}

/// Tampilan pusat untuk kondisi kosong atau galat.
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu ajakan menjelajahi komunitas di bawah daftar chat.
class _CommunityBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CommunityBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Belajar lebih seru bersama!',
                      style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan teman latihan di komunitas.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Jelajahi komunitas',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
