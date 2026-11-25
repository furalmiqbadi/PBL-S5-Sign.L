import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

/// Service Layer untuk fitur Notifikasi, dibaca dari tabel `notifications`.
///
/// Kolom yang dipakai: `id, user_id, title, body, category, is_read,
/// created_at, action_label, avatar_url`.
class NotificationService {
  final SupabaseClient? _customClient;

  /// Sumber data kustom untuk pengujian (menggantikan tabel `notifications`).
  final List<AppNotification>? _seed;

  NotificationService({SupabaseClient? client, List<AppNotification>? seed})
      : _customClient = client,
        _seed = seed;

  static const String _kolom =
      'id, title, body, category, is_read, created_at, action_label, avatar_url, target_type, target_id';

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Status dibaca selama sesi untuk sumber data uji ([seed]).
  final Set<String> _seedDibaca = {};

  /// Mengambil seluruh notifikasi pengguna (terbaru lebih dahulu).
  Future<List<AppNotification>> getNotifications() async {
    final seed = _seed;
    if (seed != null) {
      return seed
          .map((n) => _seedDibaca.contains(n.id) ? n.copyWith(isRead: true) : n)
          .toList();
    }
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];

    try {
      final rows = await client
          .from('notifications')
          .select(_kolom)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(_dariRow).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Notifikasi] Gagal membaca: ${e.message}');
      throw Exception('Gagal memuat notifikasi. Coba lagi.');
    }
  }

  Stream<AppNotification> watchNewNotifications() {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (_seed != null || client == null || userId == null) {
      return const Stream.empty();
    }

    late StreamController<AppNotification> controller;
    RealtimeChannel? channel;
    controller = StreamController<AppNotification>.broadcast(
      onListen: () {
        channel = client
            .channel(
              'notifications:$userId:${DateTime.now().millisecondsSinceEpoch}',
            )
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
                if (!controller.isClosed) {
                  controller.add(_dariRow(payload.newRecord));
                }
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

  /// Menandai satu notifikasi telah dibaca.
  Future<void> markAsRead(String id) async {
    if (_seed != null) {
      _seedDibaca.add(id);
      return;
    }
    final client = _safeClient;
    if (client == null) return;
    try {
      await client.from('notifications').update({'is_read': true}).eq('id', id);
    } on PostgrestException catch (e) {
      debugPrint('[Notifikasi] Gagal menandai dibaca: ${e.message}');
    }
  }

  /// Menandai seluruh notifikasi pengguna telah dibaca.
  Future<void> markAllAsRead() async {
    final seed = _seed;
    if (seed != null) {
      _seedDibaca.addAll(seed.map((n) => n.id));
      return;
    }
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      debugPrint('[Notifikasi] Gagal menandai semua dibaca: ${e.message}');
    }
  }

  AppNotification _dariRow(Map<String, dynamic> row) {
    return AppNotification(
      id: '${row['id']}',
      category: NotificationCategoryX.fromName('${row['category'] ?? ''}'),
      title: '${row['title'] ?? ''}',
      body: '${row['body'] ?? ''}',
      time: DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      isRead: row['is_read'] == true,
      actionLabel: row['action_label'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      destination: _targetDari(row['target_type'] as String?),
      targetId: row['target_id'] as String?,
    );
  }
}

NotificationTarget? _targetDari(String? value) {
  for (final target in NotificationTarget.values) {
    if (target.name == value) return target;
  }
  return null;
}
