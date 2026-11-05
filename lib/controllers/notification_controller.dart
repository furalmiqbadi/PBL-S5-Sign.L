import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Filter kategori pada layar Notifikasi.
enum NotificationFilter { semua, komunitas, belajar, pencapaian }

/// Thin Controller untuk fitur Notifikasi.
///
/// Mengelola state daftar notifikasi dan mendelegasikan pengambilan data ke
/// [NotificationService].
class NotificationController extends ChangeNotifier {
  NotificationController({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;

  bool isLoading = false;
  String? errorMessage;
  List<AppNotification> _notifications = [];
  NotificationFilter filter = NotificationFilter.semua;

  /// Notifikasi setelah difilter berdasarkan kategori.
  List<AppNotification> get notifications {
    switch (filter) {
      case NotificationFilter.semua:
        return _notifications;
      case NotificationFilter.komunitas:
        return _byCategory(NotificationCategory.komunitas);
      case NotificationFilter.belajar:
        return _byCategory(NotificationCategory.belajar);
      case NotificationFilter.pencapaian:
        return _byCategory(NotificationCategory.pencapaian);
    }
  }

  /// Notifikasi yang dibuat pada hari ini.
  List<AppNotification> get today => notifications
      .where((item) => _isSameDay(item.time, DateTime.now()))
      .toList();

  /// Notifikasi yang dibuat kemarin.
  List<AppNotification> get yesterday => notifications
      .where(
        (item) => _isSameDay(
          item.time,
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      )
      .toList();

  int get unreadCount =>
      _notifications.where((item) => !item.isRead).length;

  bool get hasAnyNotification => notifications.isNotEmpty;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      errorMessage = 'Gagal memuat notifikasi. Silakan coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(NotificationFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  /// Menandai satu notifikasi telah dibaca.
  void markAsRead(String id) {
    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    notifyListeners();
  }

  /// Menandai seluruh notifikasi telah dibaca.
  void markAllAsRead() {
    if (unreadCount == 0) return;
    _notifications =
        _notifications.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  List<AppNotification> _byCategory(NotificationCategory category) =>
      _notifications.where((item) => item.category == category).toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
