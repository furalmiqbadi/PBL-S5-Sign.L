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
  String query = '';
  bool _hasLoaded = false;

  /// Notifikasi setelah difilter berdasarkan kategori dan kata kunci.
  List<AppNotification> get notifications {
    final Iterable<AppNotification> base;
    switch (filter) {
      case NotificationFilter.semua:
        base = _notifications;
        break;
      case NotificationFilter.komunitas:
        base = _byCategory(NotificationCategory.komunitas);
        break;
      case NotificationFilter.belajar:
        base = _byCategory(NotificationCategory.belajar);
        break;
      case NotificationFilter.pencapaian:
        base = _byCategory(NotificationCategory.pencapaian);
        break;
    }

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return base.toList();
    return base
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.body.toLowerCase().contains(q) ||
              item.category.label.toLowerCase().contains(q),
        )
        .toList();
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

  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  bool get hasAnyNotification => notifications.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (_hasLoaded && !force) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
      _hasLoaded = true;
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

  void search(String value) {
    if (query == value) return;
    query = value;
    notifyListeners();
  }

  /// Menandai satu notifikasi telah dibaca.
  void markAsRead(String id) {
    final target = _notifications.where((item) => item.id == id);
    if (target.isEmpty || target.first.isRead) return;

    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    _service.markAsRead(id);
    notifyListeners();
  }

  /// Menandai seluruh notifikasi telah dibaca.
  void markAllAsRead() {
    if (unreadCount == 0) return;
    _notifications =
        _notifications.map((item) => item.copyWith(isRead: true)).toList();
    _service.markAllAsRead();
    notifyListeners();
  }

  List<AppNotification> _byCategory(NotificationCategory category) =>
      _notifications.where((item) => item.category == category).toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
