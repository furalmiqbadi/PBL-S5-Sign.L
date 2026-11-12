import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final int points;
  final int xp;
  final int streak;
  final int rank;
  final bool isMe;

  const LeaderboardUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.xp,
    required this.streak,
    required this.rank,
    this.isMe = false,
  });
}

/// Service Layer untuk mengambil data Peringkat (Leaderboard) dari Supabase.
class LeaderboardService {
  final SupabaseClient? _customClient;

  LeaderboardService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil daftar peringkat dari RPC `get_leaderboard` atau query tabel `profiles`.
  Future<List<LeaderboardUser>> getLeaderboard({int limit = 10}) async {
    final client = _safeClient;
    if (client == null) return [];

    final currentUserId = client.auth.currentUser?.id;

    // Coba via RPC get_leaderboard terlebih dahulu
    try {
      final res = await client.rpc(
        'get_leaderboard',
        params: {'limit_count': limit},
      );
      if (res is List && res.isNotEmpty) {
        return res.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value as Map<String, dynamic>;
          final id = (row['id'] ?? '').toString();
          final fullName = (row['full_name'] as String?)?.trim() ?? '';
          final username = (row['username'] as String?)?.trim() ?? '';
          final name = fullName.isNotEmpty
              ? fullName
              : (username.isNotEmpty ? username : 'Pengguna Sign.L');

          return LeaderboardUser(
            id: id,
            name: name,
            avatarUrl: row['avatar_url'] as String?,
            points: (row['points'] as num?)?.toInt() ?? 0,
            xp: (row['xp'] as num?)?.toInt() ?? 0,
            streak: (row['streak'] as num?)?.toInt() ?? 0,
            rank: (row['rank'] as num?)?.toInt() ?? (index + 1),
            isMe: id == currentUserId,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint(
          '[LeaderboardService] RPC get_leaderboard fallback ke query profiles: $e');
    }

    // Fallback: Query tabel profiles langsung
    try {
      final rows = await client
          .from('profiles')
          .select('id, username, full_name, avatar_url, points, xp, streak')
          .order('xp', ascending: false)
          .order('points', ascending: false)
          .limit(limit);

      return rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final id = (row['id'] ?? '').toString();
        final fullName = (row['full_name'] as String?)?.trim() ?? '';
        final username = (row['username'] as String?)?.trim() ?? '';
        final name = fullName.isNotEmpty
            ? fullName
            : (username.isNotEmpty ? username : 'Pengguna Sign.L');

        return LeaderboardUser(
          id: id,
          name: name,
          avatarUrl: row['avatar_url'] as String?,
          points: (row['points'] as num?)?.toInt() ?? 0,
          xp: (row['xp'] as num?)?.toInt() ?? 0,
          streak: (row['streak'] as num?)?.toInt() ?? 0,
          rank: index + 1,
          isMe: id == currentUserId,
        );
      }).toList();
    } catch (e) {
      debugPrint('[LeaderboardService] Gagal fetch leaderboard: $e');
      return [];
    }
  }
}
