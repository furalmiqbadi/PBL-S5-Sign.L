import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_model.dart';
import '../models/nama_tampil.dart';

/// Service Chat nyata: percakapan di tabel `conversations` dan pesan di
/// `chat_messages`, dengan profil lawan bicara dari `profiles`.
///
/// Ruang laporan bersifat hanya-baca bagi pelapor (`is_read_only = true`),
/// sehingga kolom input dikunci dan hanya admin yang bisa membalas.
class ChatService {
  final SupabaseClient? _customClient;

  ChatService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient _requireClient() {
    final client = _safeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum terhubung. Periksa koneksi internet lalu coba lagi.',
      );
    }
    return client;
  }

  String? get _myId => _safeClient?.auth.currentUser?.id;

  /// Mengambil daftar ruang percakapan pengguna (termasuk ruang laporan).
  Future<List<ChatRoom>> getChatRooms() async {
    final client = _requireClient();
    final me = _myId;
    if (me == null) return const [];
    try {
      // Nama admin tidak bergantung pada daftar percakapan, jadi dijalankan
      // paralel agar daftar chat tampil lebih cepat.
      final adminFuture = _namaAdmin(client);
      final rows = await client
          .from('conversations')
          .select()
          .or('user_id.eq.$me,admin_id.eq.$me,peer_id.eq.$me')
          .order('last_message_at', ascending: false);

      final profil = await _fetchProfil(client, _peerIds(rows, me));
      final adminNama = await adminFuture;

      return rows.map((row) {
        final userId = row['user_id']?.toString();
        final adminId = row['admin_id']?.toString();
        final peerKolom = row['peer_id']?.toString();
        final akuPelapor = userId == me && peerKolom == null;
        final peerId = [userId, adminId, peerKolom].firstWhere(
          (id) => id != null && id != me,
          orElse: () => null,
        );
        final peer = peerId == null ? null : profil[peerId];
        final namaPeer = namaTampilDari(
          peer,
          fallback: akuPelapor ? 'Admin Sign.L' : labelNamaNetral,
        );
        return ChatRoom(
          id: row['id'].toString(),
          name: _adminDari(peer) ? (adminNama ?? namaPeer) : namaPeer,
          avatarUrl: peer?['avatar_url'] as String?,
          lastMessage: (row['last_message'] as String?) ?? '',
          lastMessageTime:
              DateTime.tryParse((row['last_message_at'] as String?) ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
          unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
          isOnline: false,
          isReadOnly: (row['is_read_only'] as bool?) ?? false,
          peerId: peerId,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal memuat percakapan: ${e.message}');
      throw Exception(
        'Fitur chat belum siap. Jalankan supabase/patch_signl_backend.sql '
        'di SQL Editor Supabase.',
      );
    } catch (e) {
      debugPrint('[Chat] Gagal memuat percakapan: $e');
      throw Exception(
        'Tidak dapat memuat percakapan. Periksa koneksi internet lalu coba lagi.',
      );
    }
  }

  /// Daftar kontak untuk memulai percakapan baru. Admin melihat semua pengguna;
  /// pengguna biasa melihat teman yang sudah berteman ditambah admin (kanal
  /// bantuan).
  Future<List<ChatContact>> getContacts() async {
    final client = _requireClient();
    final me = _myId;
    if (me == null) return const [];
    try {
      final admin = await _isAdmin(client, me);
      if (admin) {
        final rows = await client
            .from('profiles')
            .select('id, full_name, username, role, avatar_url')
            .neq('id', me)
            .order('full_name')
            .limit(50);
        return rows.map(_kontakDari).toList();
      }

      final temanIds = await _temanIds(client, me);
      final rows = <Map<String, dynamic>>[];
      if (temanIds.isNotEmpty) {
        final teman = await client
            .from('profiles')
            .select('id, full_name, username, role, avatar_url')
            .inFilter('id', temanIds);
        rows.addAll(teman);
      }
      final adminRows = await client
          .from('profiles')
          .select('id, full_name, username, role, avatar_url')
          .eq('role', 'admin')
          .neq('id', me)
          .limit(10);
      final adaAdmin = rows.any((row) => (row['role'] as String?) == 'admin');
      if (!adaAdmin) rows.addAll(adminRows);

      final kontak = rows.map(_kontakDari).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return kontak;
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal memuat kontak: ${e.message}');
      return const [];
    }
  }

  /// Riwayat pesan satu ruang percakapan.
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final client = _requireClient();
    final me = _myId;
    try {
      final rows = await client
          .from('chat_messages')
          .select('id, conversation_id, sender_id, isi, dari_admin, created_at')
          .eq('conversation_id', roomId)
          .order('created_at');
      return rows.map((row) {
        final senderId = row['sender_id']?.toString();
        final adalahAku = senderId == me;
        return ChatMessage(
          id: row['id'].toString(),
          roomId: roomId,
          senderId: senderId ?? '',
          text: (row['isi'] as String?) ?? '',
          time: DateTime.tryParse((row['created_at'] as String?) ?? '')
                  ?.toLocal() ??
              DateTime.now(),
          isMe: adalahAku,
          isRead: adalahAku,
          isAdmin: (row['dari_admin'] as bool?) ?? false,
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal memuat pesan: ${e.message}');
      throw Exception('Gagal memuat pesan. Coba lagi.');
    }
  }

  /// Mengirim pesan baru. Ditolak bila ruang hanya-baca dan pengirim bukan
  /// admin.
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final client = _requireClient();
    final me = _myId;
    if (me == null) {
      throw Exception('Kamu harus masuk dulu untuk mengirim pesan.');
    }
    final isi = text.trim();
    if (isi.isEmpty) throw Exception('Pesan tidak boleh kosong.');

    final jenisPesan = await _infoPercakapan(client, roomId);
    if (jenisPesan.readOnly && !jenisPesan.admin) {
      throw Exception(
        'Percakapan ini hanya-baca. Kamu tidak bisa membalas balasan admin.',
      );
    }

    try {
      final row = await client
          .from('chat_messages')
          .insert({
            'conversation_id': roomId,
            'sender_id': me,
            'isi': isi,
            'dari_admin': jenisPesan.admin,
          })
          .select('id, created_at')
          .single();

      // Update preview & unread dijalankan paralel setelah pesan tersimpan.
      await Future.wait([
        client.from('conversations').update({
          'last_message': isi,
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', roomId),
        _tambahUnread(client, roomId),
      ]);

      return ChatMessage(
        id: row['id'].toString(),
        roomId: roomId,
        senderId: me,
        text: isi,
        time: DateTime.tryParse((row['created_at'] as String?) ?? '')
                ?.toLocal() ??
            DateTime.now(),
        isMe: true,
        isRead: true,
        isAdmin: jenisPesan.admin,
      );
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal mengirim pesan: ${e.message}');
      throw Exception('Pesan gagal terkirim. Coba lagi.');
    }
  }

  /// Menandai seluruh pesan pada ruang sebagai telah dibaca.
  Future<void> markRoomRead(String roomId) async {
    final client = _safeClient;
    if (client == null) return;
    try {
      await client
          .from('conversations')
          .update({'unread_count': 0}).eq('id', roomId);
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal menandai dibaca: ${e.message}');
    }
  }

  /// Menghapus pesan yang dikirim pengguna sendiri pada ruang ini.
  Future<void> clearMessages(String roomId) async {
    final client = _requireClient();
    final me = _myId;
    if (me == null) return;
    try {
      await client
          .from('chat_messages')
          .delete()
          .eq('conversation_id', roomId)
          .eq('sender_id', me);
      await client.from('conversations').update({
        'last_message': '',
      }).eq('id', roomId);
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal membersihkan riwayat: ${e.message}');
      throw Exception('Gagal membersihkan riwayat. Coba lagi.');
    }
  }

  /// Membuat (atau memakai ulang) ruang percakapan dengan sebuah kontak.
  ///
  /// Tiga bentuk ruang: pengguna -> admin (kanal bantuan, `admin_id` terisi),
  /// admin -> pengguna (balasan laporan), dan pengguna <-> pengguna
  /// (`peer_id` terisi, `admin_id` kosong).
  Future<ChatRoom> createRoom(ChatContact contact) async {
    final client = _requireClient();
    final me = _myId;
    if (me == null) {
      throw Exception('Kamu harus masuk dulu untuk memulai chat.');
    }

    final akuAdmin = await _isAdmin(client, me);
    final diaAdmin = contact.isAdmin;
    var pencarian = client.from('conversations').select();
    final Map<String, dynamic> isiBaru;

    if (akuAdmin != diaAdmin) {
      final userId = akuAdmin ? contact.id : me;
      final adminId = akuAdmin ? me : contact.id;
      pencarian = pencarian.eq('user_id', userId).eq('admin_id', adminId);
      isiBaru = {
        'user_id': userId,
        'admin_id': adminId,
        'judul': 'Percakapan baru',
      };
    } else {
      // Arah ruang bisa dibuat oleh salah satu pihak, jadi cari dua arah.
      pencarian = pencarian.or(
        'and(user_id.eq.$me,peer_id.eq.${contact.id}),'
        'and(user_id.eq.${contact.id},peer_id.eq.$me)',
      );
      isiBaru = {
        'user_id': me,
        'peer_id': contact.id,
        'judul': 'Percakapan baru',
      };
    }

    try {
      final existing = await pencarian.limit(1);
      if (existing.isNotEmpty) {
        final row = existing.first;
        return ChatRoom(
          id: row['id'].toString(),
          name: contact.name,
          avatarUrl: contact.avatarUrl,
          lastMessage: (row['last_message'] as String?) ?? '',
          lastMessageTime:
              DateTime.tryParse((row['last_message_at'] as String?) ?? '')
                      ?.toLocal() ??
                  DateTime.now(),
          unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
          isReadOnly: (row['is_read_only'] as bool?) ?? false,
          peerId: contact.id,
        );
      }

      final row =
          await client.from('conversations').insert(isiBaru).select().single();
      return ChatRoom(
        id: row['id'].toString(),
        name: contact.name,
        avatarUrl: contact.avatarUrl,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        peerId: contact.id,
      );
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal membuat percakapan: ${e.message}');
      throw Exception('Gagal memulai percakapan. Coba lagi.');
    }
  }

  // ===== Helper =====

  Future<Map<String, Map<String, dynamic>>> _fetchProfil(
    SupabaseClient client,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await client
          .from('profiles')
          .select('id, full_name, username, avatar_url, role')
          .inFilter('id', ids);
      return {
        for (final row in rows) '${row['id']}': Map<String, dynamic>.from(row),
      };
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal membaca profil: ${e.message}');
      return const {};
    }
  }

  List<String> _peerIds(List<dynamic> rows, String me) {
    final ids = <String>{};
    for (final row in rows) {
      for (final key in ['user_id', 'admin_id', 'peer_id']) {
        final id = row[key]?.toString();
        if (id != null && id != me) ids.add(id);
      }
    }
    return ids.toList();
  }

  ChatContact _kontakDari(Map<String, dynamic> row) => ChatContact(
        id: row['id'].toString(),
        name: namaTampilDari(row),
        username: usernameTampilDari(row),
        avatarUrl: row['avatar_url'] as String?,
        role: (row['role'] as String?) ?? 'pembelajar',
      );

  /// Id teman yang pertemanannya sudah `accepted`. Bila tabel `friendships`
  /// belum ada (patch SQL belum dijalankan), hasilnya kosong.
  Future<List<String>> _temanIds(SupabaseClient client, String me) async {
    try {
      final rows = await client
          .from('friendships')
          .select('requester_id, addressee_id')
          .eq('status', 'accepted')
          .or('requester_id.eq.$me,addressee_id.eq.$me');
      final ids = <String>{};
      for (final row in rows) {
        for (final key in ['requester_id', 'addressee_id']) {
          final id = row[key]?.toString();
          if (id != null && id != me) ids.add(id);
        }
      }
      return ids.toList();
    } catch (e) {
      debugPrint('[Chat] friendships belum siap: $e');
      return const [];
    }
  }

  bool _adminDari(Map<String, dynamic>? profil) =>
      (profil?['role'] as String?) == 'admin';

  Future<String?> _namaAdmin(SupabaseClient client) async {
    try {
      final rows = await client
          .from('profiles')
          .select('full_name, username')
          .eq('role', 'admin')
          .limit(1);
      if (rows.isEmpty) return null;
      final nama = (rows.first['full_name'] as String?)?.trim();
      if (nama != null && nama.isNotEmpty) return 'Admin · $nama';
      return 'Admin Sign.L';
    } catch (e) {
      debugPrint('[Chat] Gagal membaca nama admin: $e');
      return null;
    }
  }

  Future<bool> _isAdmin(SupabaseClient client, String userId) async {
    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return (row?['role'] as String?) == 'admin';
    } catch (e) {
      debugPrint('[Chat] Gagal memeriksa role: $e');
      return false;
    }
  }

  Future<_InfoPercakapan> _infoPercakapan(
    SupabaseClient client,
    String roomId,
  ) async {
    try {
      final row = await client
          .from('conversations')
          .select('is_read_only, user_id, admin_id')
          .eq('id', roomId)
          .maybeSingle();
      final me = _myId;
      final adminId = row?['admin_id']?.toString();
      final admin = adminId == me || await _isAdmin(client, me ?? '');
      return _InfoPercakapan(
        readOnly: (row?['is_read_only'] as bool?) ?? false,
        admin: admin,
      );
    } on PostgrestException catch (e) {
      debugPrint('[Chat] Gagal membaca info percakapan: ${e.message}');
      return const _InfoPercakapan(readOnly: false, admin: false);
    }
  }

  Future<void> _tambahUnread(SupabaseClient client, String roomId) async {
    try {
      await client.rpc('bump_unread', params: {'p_conv': roomId});
    } catch (e) {
      debugPrint('[Chat] bump_unread gagal, memakai nilai 1: $e');
      try {
        await client
            .from('conversations')
            .update({'unread_count': 1}).eq('id', roomId);
      } catch (_) {
        // Abaikan: preview pesan tetap tersimpan.
      }
    }
  }
}

class _InfoPercakapan {
  final bool readOnly;
  final bool admin;

  const _InfoPercakapan({required this.readOnly, required this.admin});
}
