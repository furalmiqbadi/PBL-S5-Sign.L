import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Filter kategori pada layar Notifikasi.
enum NotificationFilter { semua, komunitas, belajar, pencapaian, chat }

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

  // --- Realtime subscription ---
  StreamSubscription<AppNotification>? _notifSub;

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
      case NotificationFilter.chat:
        base = _byCategory(NotificationCategory.chat);
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

    var loaded = false;
    try {
      _notifications = await _service.getNotifications();
      _hasLoaded = true;
      loaded = true;
    } catch (e) {
      errorMessage = 'Gagal memuat notifikasi. Silakan coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }

    if (!loaded) return;

    // Subscribe stream notifikasi baru secara realtime.
    // Re-subscribe setiap force reload agar pakai credentials user terbaru.
    _notifSub?.cancel();
    _notifSub = _service.watchNewNotifications().listen((notif) {
      // Hindari duplikat jika notif sudah ada di cache.
      final alreadyExists = _notifications.any((n) => n.id == notif.id);
      if (alreadyExists) return;

      // Prepend notifikasi baru (urutan terbaru di atas).
      _notifications = [notif, ..._notifications];
      notifyListeners();
    });
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
  Future<void> markAsRead(String id) async {
    final target = _notifications.where((item) => item.id == id);
    if (target.isEmpty || target.first.isRead) return;

    final previous = _notifications;
    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    notifyListeners();
    try {
      await _service.markAsRead(id);
    } catch (e) {
      errorMessage = 'Gagal menyimpan status notifikasi.';
      _notifications = previous;
      notifyListeners();
    }
  }

  /// Menandai seluruh notifikasi telah dibaca.
  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    final previous = _notifications;
    _notifications =
        _notifications.map((item) => item.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _service.markAllAsRead();
    } catch (e) {
      errorMessage = 'Gagal menyimpan status notifikasi.';
      _notifications = previous;
      notifyListeners();
    }
  }

  /// Membersihkan notifikasi user lama setelah logout.
  void reset() {
    _notifSub?.cancel();
    _notifSub = null;
    _notifications = [];
    _hasLoaded = false;
    errorMessage = null;
    notifyListeners();
  }

  List<AppNotification> _byCategory(NotificationCategory category) =>
      _notifications.where((item) => item.category == category).toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }
}
