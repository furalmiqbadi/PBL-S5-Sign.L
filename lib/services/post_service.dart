import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nama_tampil.dart';

/// Ringkasan kiriman untuk kartu Komunitas di Beranda.
class PostRingkas {
  const PostRingkas({
    required this.id,
    required this.namaTampil,
    required this.avatarUrl,
    required this.konten,
    required this.dibuat,
  });

  final String id;
  final String namaTampil;
  final String avatarUrl;
  final String konten;
  final DateTime? dibuat;
}

/// Service data komunitas: kiriman (`posts`), suka (`post_likes`), dan
/// komentar (`post_comments`) di Supabase, beserta unggahan media ke bucket
/// `post-media`.
class PostService {
  final SupabaseClient? _customClient;

  PostService({SupabaseClient? client}) : _customClient = client;

  static const String bucketMedia = 'post-media';

  static const String _kolom =
      'id, user_id, konten, media_url, kategori, created_at';

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Seluruh kiriman terbaru beserta nama pengirim, jumlah suka, dan komentar.
  Future<List<Map<String, dynamic>>> fetchPosts({int batas = 50}) async {
    final client = _safeClient;
    if (client == null) return const [];
    try {
      final rows = await _queryPosts(client, batas: batas);
      return await _lengkapi(client, rows);
    } on PostgrestException catch (e) {
      if (e.code == '42703') {
        debugPrint('[Post] Kolom kategori belum ada, memakai kolom dasar.');
        final rows = await _queryPosts(client, batas: batas, dasar: true);
        return _lengkapi(client, rows);
      }
      debugPrint('[Post] Gagal membaca kiriman: ${e.message}');
      throw Exception('Gagal memuat komunitas. Coba lagi.');
    }
  }

  Future<List<Map<String, dynamic>>> _lengkapi(
    SupabaseClient client,
    List<dynamic> rows,
  ) async {
    final posts = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    if (posts.isEmpty) return posts;

    final ids = posts.map((p) => p['id']).toList();
    final userIds =
        posts.map((p) => p['user_id']).whereType<String>().toSet().toList();

    // Semua permintaan pendukung dijalankan paralel agar daftar kiriman
    // tampil lebih cepat (4 request berurutan sebelumnya).
    final userId = client.auth.currentUser?.id;
    final sukaFuture = _groupCount(client, 'post_likes', 'post_id', ids);
    final komentarFuture = _groupCount(client, 'post_comments', 'post_id', ids);
    final penulisFuture = _fetchPenulis(client, userIds);
    final disukaiFuture = userId == null
        ? Future<Set<String>>.value(const <String>{})
        : _fetchDisukai(client, userId, ids);

    final suka = await sukaFuture;
    final komentar = await komentarFuture;
    final penulis = await penulisFuture;
    final disukai = await disukaiFuture;

    for (final post in posts) {
      final pid = '${post['id']}';
      final author = penulis['${post['user_id']}'];
      final nama = namaTampilDari(author);
      // Label netral berarti nama asli tidak diketahui; biarkan kosong agar UI
      // memakai username sebagai gantinya.
      post['author_name'] = nama == labelNamaNetral ? null : nama;
      post['author_username'] = usernameTampilDari(author);
      post['author_role'] = author?['role'] ?? 'pembelajar';
      post['author_avatar'] = author?['avatar_url'];
      post['like_count'] = suka[pid] ?? 0;
      post['comment_count'] = komentar[pid] ?? 0;
      post['is_liked'] = disukai.contains(pid);
    }
    return posts;
  }

  /// Tiga kiriman terbaru untuk kartu Komunitas di Beranda.
  Future<List<PostRingkas>> fetchTerbaru({int batas = 3}) async {
    try {
      final rows = await fetchPosts(batas: batas);
      return rows.map((row) {
        final nama = '${row['author_name'] ?? ''}'.trim();
        final username = '${row['author_username'] ?? ''}'.trim();
        return PostRingkas(
          id: '${row['id']}',
          namaTampil: nama.isNotEmpty
              ? nama
              : (username.isNotEmpty ? username : labelNamaNetral),
          avatarUrl: '${row['author_avatar'] ?? ''}',
          konten: '${row['konten'] ?? ''}',
          dibuat: DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Post] Gagal memuat kiriman terbaru: $e');
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _queryPosts(
    SupabaseClient client, {
    required int batas,
    bool dasar = false,
  }) {
    final kolom = dasar ? 'id, user_id, konten, media_url, created_at' : _kolom;
    return client
        .from('posts')
        .select(kolom)
        .order('created_at', ascending: false)
        .limit(batas);
  }

  Future<Map<String, int>> _groupCount(
    SupabaseClient client,
    String tabel,
    String kolom,
    List<Object?> ids,
  ) async {
    try {
      final rows = await client.from(tabel).select(kolom).inFilter(
            kolom,
            ids.map((e) => '$e').toList(),
          );
      final hasil = <String, int>{};
      for (final row in rows) {
        final key = '${row[kolom]}';
        hasil[key] = (hasil[key] ?? 0) + 1;
      }
      return hasil;
    } on PostgrestException catch (e) {
      debugPrint('[Post] Tabel $tabel belum tersedia: ${e.message}');
      return const {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPenulis(
    SupabaseClient client,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const {};
    try {
      List<dynamic> rows;
      try {
        rows = await client
            .from('profiles')
            .select('id, full_name, username, role, avatar_url')
            .inFilter('id', userIds);
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        debugPrint('[Post] Kolom profil belum lengkap, memakai kolom dasar.');
        rows = await client
            .from('profiles')
            .select('id, full_name, username')
            .inFilter('id', userIds);
      }
      return {
        for (final row in rows) '${row['id']}': Map<String, dynamic>.from(row),
      };
    } on PostgrestException catch (e) {
      debugPrint('[Post] Select profil gagal (${e.code}), mencoba RPC publik.');
      return _profilPublikRpc(client, userIds);
    }
  }

  /// Jalur cadangan saat RLS menolak SELECT `profiles`.
  /// Membutuhkan `public.get_profil_publik(uuid[])` dari
  /// `supabase/patch_signl_profil_publik.sql`.
  Future<Map<String, Map<String, dynamic>>> _profilPublikRpc(
    SupabaseClient client,
    List<String> userIds,
  ) async {
    try {
      final data = await client.rpc(
        'get_profil_publik',
        params: {'ids': userIds},
      );
      return {
        for (final row in (data as List<dynamic>))
          '${row['id']}': Map<String, dynamic>.from(row as Map),
      };
    } on PostgrestException catch (e) {
      debugPrint('[Post] RPC profil publik gagal: ${e.message}');
      return const {};
    }
  }

  Future<Set<String>> _fetchDisukai(
    SupabaseClient client,
    String userId,
    List<Object?> ids,
  ) async {
    try {
      final rows = await client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', ids.map((e) => '$e').toList());
      return rows.map((r) => '${r['post_id']}').toSet();
    } on PostgrestException catch (e) {
      debugPrint('[Post] Tabel suka belum tersedia: ${e.message}');
      return {};
    }
  }

  /// Mengirim kiriman baru, lalu mengunggah media bila ada.
  ///
  /// [mediaUrl] dipakai untuk media yang sudah ada di server (mis. banner
  /// kuis) sehingga tidak perlu diunggah ulang.
  Future<void> buatPostingan({
    required String konten,
    required String kategori,
    String? mediaPath,
    bool mediaIsVideo = false,
    String? mediaUrl,
  }) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw Exception('Kamu harus masuk dulu untuk membuat postingan.');
    }
    try {
      String? url = mediaUrl;
      if (url == null && mediaPath != null) {
        url = await _unggahMedia(client, userId, mediaPath, mediaIsVideo);
      }
      await client.from('posts').insert({
        'user_id': userId,
        'konten': konten,
        'kategori': kategori,
        if (url != null) 'media_url': url,
      });
    } on PostgrestException catch (e) {
      debugPrint('[Post] Gagal mengirim: ${e.message}');
      throw Exception('Gagal mengirim postingan. Coba lagi.');
    }
  }

  Future<String> _unggahMedia(
    SupabaseClient client,
    String userId,
    String pathLokal,
    bool isVideo,
  ) async {
    final berkas = File(pathLokal);
    if (!berkas.existsSync()) {
      throw Exception('Berkas media tidak ditemukan.');
    }
    final ekstensi = pathLokal.split('.').last.toLowerCase();
    final objectPath =
        '$userId/${isVideo ? 'video' : 'foto'}_${DateTime.now().millisecondsSinceEpoch}.$ekstensi';
    try {
      await client.storage.from(bucketMedia).upload(
            objectPath,
            berkas,
            fileOptions: FileOptions(
              contentType: isVideo ? 'video/mp4' : 'image/webp',
              upsert: true,
            ),
          );
      return client.storage.from(bucketMedia).getPublicUrl(objectPath);
    } on StorageException catch (e) {
      debugPrint('[Post] Gagal mengunggah media: ${e.message}');
      throw Exception(
        'Gagal mengunggah media. Pastikan bucket "post-media" sudah dibuat.',
      );
    }
  }

  /// Menambah/menghapus suka milik pengguna.
  Future<bool> toggleLike(String postId, bool isLiked) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return isLiked;
    try {
      if (isLiked) {
        await client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await client
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': userId});
      }
      return !isLiked;
    } on PostgrestException catch (e) {
      debugPrint('[Post] Gagal menyimpan suka: ${e.message}');
      throw Exception('Gagal menyimpan suka. Coba lagi.');
    }
  }

  /// Daftar komentar sebuah kiriman (terlama lebih dahulu).
  Future<List<Map<String, dynamic>>> fetchKomentar(String postId) async {
    final client = _safeClient;
    if (client == null) return const [];
    try {
      List<dynamic> rows;
      try {
        rows = await client
            .from('post_comments')
            .select('id, user_id, parent_id, isi, created_at')
            .eq('post_id', postId)
            .order('created_at');
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        debugPrint('[Post] Kolom parent_id belum ada, memakai kolom dasar.');
        rows = await client
            .from('post_comments')
            .select('id, user_id, isi, created_at')
            .eq('post_id', postId)
            .order('created_at');
      }
      final data = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      final penulis = await _fetchPenulis(
        client,
        data.map((r) => '${r['user_id']}').toSet().toList(),
      );
      for (final row in data) {
        final profil = penulis['${row['user_id']}'];
        final nama = namaTampilDari(profil);
        row['author_name'] = nama == labelNamaNetral ? null : nama;
        row['author_avatar'] = profil?['avatar_url'];
        row['author_username'] = usernameTampilDari(profil);
        row['author_role'] = profil?['role'] ?? 'pembelajar';
        row['role'] = profil?['role'] ?? 'pembelajar';
        row['is_current_user'] =
            '${row['user_id']}' == client.auth.currentUser?.id;
      }
      return data;
    } on PostgrestException catch (e) {
      debugPrint('[Post] Gagal membaca komentar: ${e.message}');
      throw Exception('Gagal memuat komentar. Coba lagi.');
    }
  }

  Future<void> kirimKomentar(String postId, String isi,
      {String? parentId}) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw Exception('Kamu harus masuk dulu untuk menulis komentar.');
    }
    final teks = isi.trim();
    if (teks.isEmpty) {
      throw Exception('Komentar tidak boleh kosong.');
    }
    try {
      await client.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'isi': teks,
        if (parentId != null) 'parent_id': parentId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42703' && parentId != null) {
        debugPrint('[Post] Kolom parent_id belum ada, kirim tanpa balasan.');
        try {
          await client.from('post_comments').insert({
            'post_id': postId,
            'user_id': userId,
            'isi': teks,
          });
          return;
        } on PostgrestException catch (e2) {
          debugPrint('[Post] Gagal mengirim komentar: ${e2.message}');
          throw Exception('Gagal mengirim komentar. Coba lagi.');
        }
      }
      debugPrint('[Post] Gagal mengirim komentar: ${e.message}');
      throw Exception('Gagal mengirim komentar. Coba lagi.');
    }
  }

  /// Mengirim laporan kiriman ke tabel `laporan` agar masuk panel admin.
  Future<void> laporkanPostingan({
    required String konten,
    required String penulis,
    String alasan = 'Konten tidak pantas',
  }) async {
    final client = _safeClient;
    if (client == null) {
      throw Exception('Supabase belum terhubung. Coba lagi nanti.');
    }
    final userId = client.auth.currentUser?.id;
    try {
      final profil = userId == null
          ? const <String, dynamic>{}
          : await client
              .from('profiles')
              .select('full_name, username')
              .eq('id', userId)
              .maybeSingle();
      final namaPelapor = (profil?['full_name'] as String?)?.trim();
      final username = (profil?['username'] as String?)?.trim();
      await client.from('laporan').insert({
        'tipe': 'post',
        'pelapor': (namaPelapor == null || namaPelapor.isEmpty)
            ? (username == null || username.isEmpty
                ? labelNamaNetral
                : username)
            : namaPelapor,
        'terlapor': penulis,
        'alasan': alasan,
        'detail':
            konten.length > 200 ? '${konten.substring(0, 200)}...' : konten,
        'pesan': '',
        'status': 'baru',
      });
    } on PostgrestException catch (e) {
      debugPrint('[Post] Gagal mengirim laporan: ${e.message}');
      throw Exception(
        'Gagal mengirim laporan. Jalankan supabase/patch_signl_backend.sql '
        'agar tabel laporan tersedia.',
      );
    }
  }
}
