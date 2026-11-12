import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

/// Service Layer untuk fitur Notifikasi yang terhubung ke Supabase.
class NotificationService {
  final SupabaseClient? _customClient;
  List<AppNotification>? _cache;

  NotificationService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil seluruh notifikasi pengguna dari tabel `notifications` di Supabase.
  Future<List<AppNotification>> getNotifications() async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null && userId != null) {
      try {
        final rows = await client
            .from('notifications')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        if (rows.isNotEmpty) {
          final list = rows.map((r) {
            final catString = (r['category'] as String?) ?? 'komunitas';
            final cat = NotificationCategoryX.fromName(catString);
            final createdAt = r['created_at'] is String
                ? DateTime.tryParse(r['created_at']) ?? DateTime.now()
                : DateTime.now();

            return AppNotification(
              id: (r['id'] ?? '').toString(),
              category: cat,
              title: (r['title'] as String?) ?? '',
              body: (r['body'] as String?) ?? '',
              time: createdAt,
              actionLabel: r['action_label'] as String?,
              avatarUrl: r['avatar_url'] as String?,
              isRead: (r['is_read'] as bool?) ?? false,
            );
          }).toList();

          _cache = list;
          return list;
        }
      } catch (e) {
        debugPrint('[NotificationService] Gagal fetch notifikasi: $e');
      }
    }

    _cache ??= _seedNotifications();
    return List<AppNotification>.from(_cache!);
  }

  /// Menandai satu notifikasi telah dibaca.
  Future<void> markAsRead(String id) async {
    final client = _safeClient;
    if (client != null && !id.startsWith('n')) {
      try {
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id);
      } catch (e) {
        debugPrint('[NotificationService] Gagal markAsRead di Supabase: $e');
      }
    }

    _cache = _cache
        ?.map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
  }

  /// Menandai seluruh notifikasi telah dibaca.
  Future<void> markAllAsRead() async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('[NotificationService] Gagal markAllAsRead di Supabase: $e');
      }
    }

    _cache = _cache?.map((item) => item.copyWith(isRead: true)).toList();
  }

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
            'Latihan kata sehari-hari di Tebet Eco Park, Minggu pukul 09.00 WIB.',
        actionLabel: 'Lihat sesi',
        time: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n4',
        category: NotificationCategory.pencapaian,
        title: 'Lencana Konsisten 7 Hari terbuka!',
        body: 'Hebat! Kamu belajar selama 7 hari berturut-turut. +50 XP',
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
