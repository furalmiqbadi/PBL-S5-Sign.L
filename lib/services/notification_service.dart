import '../models/notification_model.dart';

/// Service Layer untuk fitur Notifikasi.
///
/// Mengembalikan data dummy; implementasi dapat diganti dengan Cloud
/// Firestore tanpa mengubah Controller maupun View.
class NotificationService {
  /// Mengambil seluruh notifikasi pengguna (terbaru lebih dahulu).
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    DateTime yesterdayAt(int hour, int minute) =>
        DateTime(yesterday.year, yesterday.month, yesterday.day, hour, minute);

    return [
      AppNotification(
        id: 'n1',
        category: NotificationCategory.komunitas,
        title: 'Rian membalas pertanyaanmu',
        body: 'Coba perhatikan gambar, arahkan tangan dari dagu ke depan, ya.',
        actionLabel: 'Lihat diskusi',
        time: now.subtract(const Duration(minutes: 10)),
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
      ),
      AppNotification(
        id: 'n2',
        category: NotificationCategory.belajar,
        title: 'Jaga streak 7 harimu!',
        body: 'Luangkan 10 menit untuk melanjutkan Bab 1: Alfabet Isyarat.',
        actionLabel: 'Lanjutkan belajar',
        time: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n3',
        category: NotificationCategory.komunitas,
        title: 'Seisi Klub BISINDO Jakarta',
        body: 'Latihan kata sehari-hari di Tebo Eco Park, Minggu pukul 09.00 WIB.',
        actionLabel: 'Lihat sesi',
        time: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n4',
        category: NotificationCategory.pencapaian,
        title: 'Lencana Konsisten 7 Hari terbuka!',
        body: 'Hebat, Sarah! Kamu belajar selama 7 hari berturut-turut. +50 XP',
        actionLabel: 'Lihat pencapaian',
        time: yesterdayAt(19, 30),
        isRead: true,
      ),
      AppNotification(
        id: 'n5',
        category: NotificationCategory.komunitas,
        title: 'Budi menyukai video latihanmu',
        body: 'Gerakan huruf D-mu makin baik. Terus berlatih bersama komunitas!',
        time: yesterdayAt(19, 45),
        isRead: true,
      ),
    ];
  }
}
