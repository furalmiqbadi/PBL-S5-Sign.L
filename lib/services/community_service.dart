import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Layer untuk fitur Komunitas & Event dari Supabase.
class CommunityService {
  final SupabaseClient? _customClient;

  CommunityService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil daftar postingan komunitas dari Supabase.
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final client = _safeClient;
    if (client == null) return [];

    try {
      final rows = await client
          .from('posts')
          .select('*, profiles(id, full_name, username, avatar_url, role)')
          .eq('is_hidden', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[CommunityService] Gagal fetch posts: $e');
      return [];
    }
  }

  /// Membuat postingan baru ke tabel `posts` di Supabase.
  Future<Map<String, dynamic>?> createPost({
    required String content,
    String? mediaUrl,
  }) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    try {
      final res = await client
          .from('posts')
          .insert({
            'user_id': userId,
            'konten': content.trim(),
            'media_url': mediaUrl,
          })
          .select('*, profiles(id, full_name, username, avatar_url, role)')
          .single();

      return res;
    } catch (e) {
      debugPrint('[CommunityService] Gagal create post di Supabase: $e');
      return null;
    }
  }

  /// Mengambil daftar event dari tabel `events` di Supabase.
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final client = _safeClient;
    if (client == null) return [];

    try {
      final rows = await client
          .from('events')
          .select('*')
          .order('event_date', ascending: true);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[CommunityService] Gagal fetch events: $e');
      return [];
    }
  }
}

