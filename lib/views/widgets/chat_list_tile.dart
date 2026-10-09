import 'package:flutter/material.dart';

import '../../models/chat_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'time_labels.dart';
import 'user_avatar.dart';

/// Satu baris percakapan pada layar daftar Chat.
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.room,
    this.onTap,
  });

  final ChatRoom room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.hasUnread;

    final preview = StringBuffer();
    if (room.lastSenderName != null && room.lastSenderName!.isNotEmpty) {
      preview.write('${room.lastSenderName}: ');
    }
    preview.write(room.lastMessage);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              imageUrl: room.avatarUrl,
              name: room.name,
              isGroup: room.isGroup,
              showOnlineBadge: room.isOnline,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      if (room.isGroup && room.memberCount != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${room.memberCount} anggota',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chatListTime(room.lastMessageTime),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: hasUnread ? AppColors.primary : AppColors.textMuted,
                    fontWeight:
                        hasUnread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${room.unreadCount}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
