import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_model.dart';
import '../notification/notification_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/chat_list_tile.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/section_header.dart';
import '../widgets/signl_nav_bar.dart';
import 'chat_room_view.dart';

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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppScreenHeader(
              title: 'Chat',
              actions: [
                HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  semanticLabel: 'Notifikasi',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                HeaderIconButton(
                  icon: Icons.edit_square,
                  semanticLabel: 'Tulis pesan baru',
                  filled: false,
                  onTap: () {},
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
                      child: _buildSearchField(controller),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FilterChipRow(
                        labels: const ['Semua', 'Belum dibaca', 'Grup'],
                        selectedIndex: controller.filter.index,
                        onSelected: (index) =>
                            controller.setFilter(ChatFilter.values[index]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSectionHeader(controller),
                    ),
                    const SizedBox(height: 4),
                    Expanded(child: _buildList(context, controller)),
                    _buildCommunityBanner(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SignlNavBar(selectedIndex: 3),
    );
  }

  Widget _buildSearchField(ChatController controller) {
    return TextField(
      onChanged: controller.search,
      style: AppTextStyles.bodyMedium,
      decoration: const InputDecoration(
        hintText: 'Cari teman atau grup belajar...',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
        isDense: true,
      ),
    );
  }

  Widget _buildSectionHeader(ChatController controller) {
    return Row(
      children: [
        Text('Percakapan terbaru', style: AppTextStyles.titleMedium),
        const Spacer(),
        if (controller.unreadRoomsCount > 0)
          Text(
            '${controller.unreadRoomsCount} chat belum dibaca',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildList(BuildContext context, ChatController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return _buildMessageState(
        icon: Icons.wifi_off_rounded,
        message: controller.errorMessage!,
      );
    }

    final rooms = controller.rooms;
    if (rooms.isEmpty) {
      return _buildMessageState(
        icon: Icons.forum_outlined,
        message: 'Belum ada percakapan di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ChatListTile(
          room: room,
          onTap: () => _openRoom(context, room),
        );
      },
    );
  }

  void _openRoom(BuildContext context, ChatRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String message,
  }) {
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
        ],
      ),
    );
  }

  Widget _buildCommunityBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
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
                const SizedBox(height: 2),
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
    );
  }
}
