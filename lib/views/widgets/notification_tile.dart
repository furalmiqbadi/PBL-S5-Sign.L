import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'time_labels.dart';
import 'user_avatar.dart';

/// Kartu satu notifikasi.
///
/// Notifikasi belum dibaca ditampilkan dengan latar pink lembut, sedangkan
/// yang sudah dibaca berlatar putih.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  Color get _categoryColor {
    switch (notification.category) {
      case NotificationCategory.komunitas:
        return AppColors.primary;
      case NotificationCategory.belajar:
        return AppColors.tertiary;
      case NotificationCategory.pencapaian:
        return AppColors.secondary;
    }
  }

  IconData get _categoryIcon {
    switch (notification.category) {
      case NotificationCategory.komunitas:
        return Icons.groups_rounded;
      case NotificationCategory.belajar:
        return Icons.local_fire_department_rounded;
      case NotificationCategory.pencapaian:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.pinkSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeading(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _buildCategoryTag()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notificationTime(notification.time),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.title,
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                  ),
                  if (notification.hasAction) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onAction,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              notification.actionLabel!,
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
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (notification.avatarUrl != null &&
        notification.avatarUrl!.isNotEmpty) {
      return UserAvatar(
        imageUrl: notification.avatarUrl,
        name: notification.title,
        size: 44,
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _categoryColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(_categoryIcon, color: _categoryColor, size: 22),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _categoryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        notification.category.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: _categoryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
