import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/notification_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/signl_nav_bar.dart';

/// Layar Notifikasi.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
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
              title: 'Notifikasi',
              actions: [
                HeaderIconButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Cari notifikasi',
                  filled: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<NotificationController>(
              builder: (context, controller, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                      child: _buildSummaryRow(controller),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FilterChipRow(
                        labels: const [
                          'Semua',
                          'Komunitas',
                          'Belajar',
                          'Pencapaian',
                        ],
                        selectedIndex: controller.filter.index,
                        onSelected: (index) => controller
                            .setFilter(NotificationFilter.values[index]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildList(controller)),
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

  Widget _buildSummaryRow(NotificationController controller) {
    final unread = controller.unreadCount;
    return Row(
      children: [
        Expanded(
          child: Text(
            unread > 0
                ? '$unread notifikasi belum dibaca'
                : 'Semua notifikasi sudah dibaca',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (unread > 0)
          TextButton(
            onPressed: controller.markAllAsRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Tandai semua dibaca',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildList(NotificationController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Text(
          controller.errorMessage!,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final today = controller.today;
    final yesterday = controller.yesterday;

    if (today.isEmpty && yesterday.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada notifikasi di kategori ini.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionLabel('Hari ini'),
          ...today.map((item) => _buildTile(controller, item)),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionLabel('Kemarin'),
          ...yesterday.map((item) => _buildTile(controller, item)),
        ],
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Kamu sudah melihat semua aktivitas terbaru.',
            style: AppTextStyles.labelSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(label, style: AppTextStyles.titleMedium),
    );
  }

  Widget _buildTile(
    NotificationController controller,
    AppNotification notification,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NotificationTile(
        notification: notification,
        onTap: () => controller.markAsRead(notification.id),
        onAction: () => controller.markAsRead(notification.id),
      ),
    );
  }
}
