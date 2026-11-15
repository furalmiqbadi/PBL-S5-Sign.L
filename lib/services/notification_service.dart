import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

abstract class NotificationService {
  factory NotificationService({SupabaseClient? client}) =
      SupabaseNotificationService;
  factory NotificationService.inMemory() = InMemoryNotificationService;

  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();

  /// Stream notifikasi baru untuk user yang sedang login.
  /// Emit setiap kali ada INSERT baru di tabel `notifications` milik user ini.
  Stream<AppNotification> watchNewNotifications();
}

class SupabaseNotificationService implements NotificationService {
  SupabaseNotificationService({SupabaseClient? client})
      : _customClient = client;

  final SupabaseClient? _customClient;

  SupabaseClient get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError('Supabase belum diinisialisasi.');
    }
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Silakan login untuk melihat notifikasi.');
    }
    return id;
  }

  bool get _hasAuthenticatedSession {
    try {
      return _client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final rows = await _client
        .from('notifications')
        .select(
          'id, category, title, body, action_label, avatar_url, created_at, read_at, target_type, target_id',
        )
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((row) {
      return AppNotification(
        id: row['id'] as String,
        category: NotificationCategoryX.fromName(
          row['category'] as String,
        ),
        title: row['title'] as String,
        body: row['body'] as String? ?? '',
        actionLabel: row['action_label'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        time: DateTime.parse(row['created_at'] as String).toLocal(),
        isRead: row['read_at'] != null,
        destination: _targetFromName(row['target_type'] as String?),
        targetId: row['target_id'] as String?,
      );
    }).toList();
  }

  NotificationTarget? _targetFromName(String? value) {
    for (final target in NotificationTarget.values) {
      if (target.name == value) return target;
    }
    return null;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq(
            'user_id', _userId);
  }

  @override
  Stream<AppNotification> watchNewNotifications() {
    if (!_hasAuthenticatedSession) return const Stream.empty();
    final userId = _userId;
    // ignore: close_sinks
    late StreamController<AppNotification> controller;
    RealtimeChannel? channel;

    controller = StreamController<AppNotification>.broadcast(
      onListen: () {
        channel = _client
            .channel(
                'notifications:$userId:${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                if (controller.isClosed) return;
                final row = payload.newRecord;
                controller.add(
                  AppNotification(
                    id: row['id'] as String? ?? '',
                    category: NotificationCategoryX.fromName(
                      row['category'] as String? ?? 'komunitas',
                    ),
                    title: row['title'] as String? ?? '',
                    body: row['body'] as String? ?? '',
                    actionLabel: row['action_label'] as String?,
                    avatarUrl: row['avatar_url'] as String?,
                    time: DateTime.tryParse(
                          row['created_at'] as String? ?? '',
                        )?.toLocal() ??
                        DateTime.now(),
                    isRead: false,
                    destination: _targetFromName(row['target_type'] as String?),
                    targetId: row['target_id'] as String?,
                  ),
                );
              },
            )
            .subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );
    return controller.stream;
  }
}

/// Service in-memory khusus untuk test controller; tidak dipakai aplikasi.
class InMemoryNotificationService implements NotificationService {
  List<AppNotification>? _cache;

  /// Mengambil seluruh notifikasi pengguna (terbaru lebih dahulu).
  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _cache ??= _seedNotifications();
    return List<AppNotification>.from(_cache!);
  }

  /// Menandai satu notifikasi telah dibaca.
  @override
  Future<void> markAsRead(String id) async {
    _cache = _cache
        ?.map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
  }

  /// Menandai seluruh notifikasi telah dibaca.
  @override
  Future<void> markAllAsRead() async {
    _cache = _cache?.map((item) => item.copyWith(isRead: true)).toList();
  }

  /// In-memory tidak mendukung realtime — kembalikan stream kosong.
  @override
  Stream<AppNotification> watchNewNotifications() => const Stream.empty();

  List<AppNotification> _seedNotifications() {
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
        body:
            'Latihan kata sehari-hari di Tebo Eco Park, Minggu pukul 09.00 WIB.',
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
        body:
            'Gerakan huruf D-mu makin baik. Terus berlatih bersama komunitas!',
        time: yesterdayAt(19, 45),
        isRead: true,
      ),
    ];
  }
}
