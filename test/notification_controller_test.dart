import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/controllers/notification_controller.dart';
import 'package:sign_l/models/notification_model.dart';

void main() {
  group('NotificationController', () {
    test('memuat, memfilter, dan mencari notifikasi', () async {
      final controller = NotificationController();
      await controller.load();

      expect(controller.unreadCount, 3);

      controller.setFilter(NotificationFilter.belajar);
      expect(controller.notifications.length, 1);

      controller.setFilter(NotificationFilter.semua);
      controller.search('streak');
      expect(controller.notifications.length, 1);
      expect(controller.notifications.first.title, contains('streak'));
    });

    test('status dibaca bertahan saat data dimuat ulang', () async {
      final controller = NotificationController();
      await controller.load();

      controller.markAsRead('n1');
      expect(controller.unreadCount, 2);

      await controller.load(force: true);
      expect(controller.unreadCount, 2);

      controller.markAllAsRead();
      expect(controller.unreadCount, 0);

      await controller.load(force: true);
      expect(controller.unreadCount, 0);
    });

    test('target navigasi mengikuti kategori', () {
      final notification = AppNotification(
        id: 'x',
        category: NotificationCategory.pencapaian,
        title: 'Lencana',
        body: 'Hebat',
        time: DateTime.now(),
      );

      expect(notification.target, NotificationTarget.achievement);
    });
  });
}
