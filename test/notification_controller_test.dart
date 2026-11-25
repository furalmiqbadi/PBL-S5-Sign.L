import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/controllers/notification_controller.dart';
import 'package:sign_l/models/notification_model.dart';
import 'package:sign_l/services/notification_service.dart';

/// Data uji pengganti tabel `notifications` (tanpa jaringan).
List<AppNotification> _seed() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      category: NotificationCategory.komunitas,
      title: 'Rian membalas pertanyaanmu',
      body: 'Coba perhatikan gambar, arahkan tangan dari dagu ke depan, ya.',
      time: now,
    ),
    AppNotification(
      id: 'n2',
      category: NotificationCategory.belajar,
      title: 'Jaga streak 7 harimu!',
      body: 'Luangkan 10 menit untuk melanjutkan Bab 1: Alfabet Isyarat.',
      time: now,
    ),
    AppNotification(
      id: 'n3',
      category: NotificationCategory.komunitas,
      title: 'Seisi Klub BISINDO Jakarta',
      body: 'Latihan kata sehari-hari di Tebo Eco Park.',
      time: now.subtract(const Duration(hours: 2)),
    ),
  ];
}

NotificationController _controller() => NotificationController(
      service: NotificationService(seed: _seed()),
    );

void main() {
  group('NotificationController', () {
    test('memuat, memfilter, dan mencari notifikasi', () async {
      final controller = _controller();
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
      final controller = _controller();
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
