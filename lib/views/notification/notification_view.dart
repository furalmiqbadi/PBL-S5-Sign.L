import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../common/pushed_page.dart';
import '../home/detail_materi_page.dart';
import '../komunitas/komunitas_page.dart';
import '../profile/profile_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        context.read<NotificationController>().search('');
      }
    });
  }

  void _openNotification(
    BuildContext context,
    NotificationController controller,
    AppNotification notification,
  ) {
    controller.markAsRead(notification.id);

    final route = switch (notification.target) {
      NotificationTarget.community => MaterialPageRoute<void>(
          builder: (_) => const PushedPage(
            title: 'Komunitas',
            child: KomunitasPage(),
          ),
        ),
      NotificationTarget.learning => MaterialPageRoute<void>(
          builder: (_) => const DetailMateriPage(),
        ),
      NotificationTarget.achievement => MaterialPageRoute<void>(
          builder: (_) => const PushedPage(
            title: 'Profil',
            child: ProfileScreen(),
          ),
        ),
    };

    Navigator.of(context).push(route);
  }

  static final OutlineInputBorder _softFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  );

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
                  icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                  semanticLabel:
                      _searching ? 'Tutup pencarian' : 'Cari notifikasi',
                  onTap: _toggleSearch,
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
                    if (_searching)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: controller.search,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Cari notifikasi...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textMuted,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: _softFieldBorder,
                            enabledBorder: _softFieldBorder,
                            focusedBorder: _softFieldBorder,
                            suffixIcon: controller.query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      controller.search('');
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                          ),
                        ),
                      ),
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
                    Expanded(child: _buildList(context, controller)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SignlNavBar(selectedIndex: -1),
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
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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

  Widget _buildList(BuildContext context, NotificationController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => controller.load(force: true),
              child: const Text('Coba lagi'),
            ),
          ],
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
              controller.query.isEmpty
                  ? 'Belum ada notifikasi di kategori ini.'
                  : 'Notifikasi tidak ditemukan.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (today.isNotEmpty) ...[
          _buildSectionLabel('Hari ini'),
          ...today.map((item) => _buildTile(context, controller, item)),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionLabel('Kemarin'),
          ...yesterday.map((item) => _buildTile(context, controller, item)),
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
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Text(label, style: AppTextStyles.titleMedium),
    );
  }

  Widget _buildTile(
    BuildContext context,
    NotificationController controller,
    AppNotification notification,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NotificationTile(
        notification: notification,
        onTap: () => _openNotification(context, controller, notification),
        onAction: () => _openNotification(context, controller, notification),
      ),
    );
  }
}
