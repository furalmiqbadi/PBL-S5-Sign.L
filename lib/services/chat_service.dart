import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

/// Service Layer untuk fitur Chat yang terhubung ke Supabase Realtime & Database.
class ChatService {
  final SupabaseClient? _customClient;
  List<ChatRoom>? _roomsCache;
  final Map<String, List<ChatMessage>> _messagesCache = {};

  ChatService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient? get _safeClient {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Mengambil daftar ruang percakapan pengguna dari Supabase.
  Future<List<ChatRoom>> getChatRooms() async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null && userId != null) {
      try {
        final members = await client
            .from('chat_room_members')
            .select('room_id, chat_rooms(*)')
            .eq('user_id', userId);

        if (members.isNotEmpty) {
          final List<ChatRoom> rooms = [];
          for (final m in members) {
            final r = m['chat_rooms'] as Map<String, dynamic>?;
            if (r == null) continue;

            final roomId = r['id'].toString();
            final isGroup = (r['is_group'] as bool?) ?? false;
            final name = (r['name'] as String?) ?? (isGroup ? 'Grup Isyarat' : 'Teman Belajar');
            final avatarUrl = r['avatar_url'] as String?;
            final lastMsgAt = r['last_message_at'] is String
                ? DateTime.tryParse(r['last_message_at']) ?? DateTime.now()
                : DateTime.now();

            // Ambil pesan terakhir untuk preview
            String lastMessage = '';
            try {
              final lastMsgRow = await client
                  .from('chat_messages')
                  .select('body')
                  .eq('room_id', roomId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();
              if (lastMsgRow != null && lastMsgRow['body'] is String) {
                lastMessage = lastMsgRow['body'];
              }
            } catch (_) {}

            rooms.add(ChatRoom(
              id: roomId,
              name: name,
              avatarUrl: avatarUrl,
              lastMessage: lastMessage.isNotEmpty ? lastMessage : 'Mulai obrolan...',
              lastMessageTime: lastMsgAt,
              isGroup: isGroup,
              isOnline: true,
            ));
          }

          if (rooms.isNotEmpty) {
            _roomsCache = rooms;
            return List<ChatRoom>.from(rooms);
          }
        }
      } catch (e) {
        debugPrint('[ChatService] Gagal fetch rooms: $e');
      }
    }

    _roomsCache ??= _seedRooms();
    return List<ChatRoom>.from(_roomsCache!);
  }

  /// Mengambil daftar kontak untuk memulai percakapan baru dari tabel `profiles`.
  Future<List<ChatContact>> getContacts() async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null) {
      try {
        var query = client
            .from('profiles')
            .select('id, full_name, username, avatar_url, last_seen_at');
        if (userId != null) {
          query = query.neq('id', userId);
        }
        final rows = await query.limit(20);

        if (rows.isNotEmpty) {
          return rows.map((r) {
            final fullName = (r['full_name'] as String?)?.trim() ?? '';
            final username = (r['username'] as String?)?.trim() ?? '';
            final name = fullName.isNotEmpty
                ? fullName
                : (username.isNotEmpty ? username : 'Teman Isyarat');

            bool isOnline = false;
            if (r['last_seen_at'] is String) {
              final lastSeen = DateTime.tryParse(r['last_seen_at']);
              if (lastSeen != null) {
                isOnline = DateTime.now().difference(lastSeen).inMinutes < 15;
              }
            }

            return ChatContact(
              id: r['id'].toString(),
              name: name,
              avatarUrl: r['avatar_url'] as String?,
              isOnline: isOnline,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('[ChatService] Gagal fetch contacts: $e');
      }
    }

    return const [
      ChatContact(
        id: 'dina',
        name: 'Dina Saftri',
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
        isOnline: true,
      ),
      ChatContact(
        id: 'rian',
        name: 'Rian Pratama',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        isOnline: true,
      ),
      ChatContact(
        id: 'budi',
        name: 'Budi Santoso',
        avatarUrl: 'https://i.pravatar.cc/150?img=33',
      ),
      ChatContact(
        id: 'siti',
        name: 'Siti Rahma',
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
      ),
      ChatContact(
        id: 'ayu',
        name: 'Ayu Lestari',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        isOnline: true,
      ),
      ChatContact(
        id: 'fajar',
        name: 'Fajar Nugroho',
        avatarUrl: 'https://i.pravatar.cc/150?img=15',
      ),
    ];
  }

  /// Mengambil riwayat pesan pada sebuah ruang percakapan.
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null && roomId.contains('-')) {
      try {
        final rows = await client
            .from('chat_messages')
            .select('*')
            .eq('room_id', roomId)
            .order('created_at', ascending: true);

        if (rows.isNotEmpty) {
          final list = rows.map((r) {
            final senderId = (r['sender_id'] ?? '').toString();
            final createdAt = r['created_at'] is String
                ? DateTime.tryParse(r['created_at']) ?? DateTime.now()
                : DateTime.now();

            return ChatMessage(
              id: (r['id'] ?? '').toString(),
              roomId: roomId,
              senderId: senderId,
              text: (r['body'] as String?) ?? '',
              time: createdAt,
              isMe: senderId == userId,
              isRead: true,
            );
          }).toList();

          _messagesCache[roomId] = list;
          return list;
        }
      } catch (e) {
        debugPrint('[ChatService] Gagal fetch messages: $e');
      }
    }

    return List<ChatMessage>.from(
      _messagesCache.putIfAbsent(roomId, () => _seedMessages(roomId)),
    );
  }

  /// Mengirim pesan baru ke sebuah ruang percakapan.
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null && userId != null && roomId.contains('-')) {
      try {
        final res = await client
            .from('chat_messages')
            .insert({
              'room_id': roomId,
              'sender_id': userId,
              'body': text.trim(),
            })
            .select()
            .single();

        await client.from('chat_rooms').update({
          'last_message_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId);

        final msg = ChatMessage(
          id: res['id'].toString(),
          roomId: roomId,
          senderId: userId,
          text: text,
          time: DateTime.now(),
          isMe: true,
        );

        _messagesCache.putIfAbsent(roomId, () => []).add(msg);
        _updateRoomPreview(roomId, text);
        return msg;
      } catch (e) {
        debugPrint('[ChatService] Gagal kirim pesan ke Supabase: $e');
      }
    }

    final message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: 'me',
      text: text,
      time: DateTime.now(),
      isMe: true,
    );
    _messagesCache.putIfAbsent(roomId, () => _seedMessages(roomId)).add(message);
    _updateRoomPreview(roomId, text);
    return message;
  }

  /// Menandai seluruh pesan pada ruang sebagai telah dibaca.
  Future<void> markRoomRead(String roomId) async {
    _roomsCache = _roomsCache
        ?.map((room) => room.id == roomId ? room.copyWith(unreadCount: 0) : room)
        .toList();
  }

  /// Mengosongkan riwayat pesan pada sebuah ruang.
  Future<void> clearMessages(String roomId) async {
    _messagesCache[roomId] = [];
  }

  /// Membuat ruang percakapan baru untuk sebuah kontak.
  Future<ChatRoom> createRoom(ChatContact contact) async {
    final client = _safeClient;
    final userId = client?.auth.currentUser?.id;

    if (client != null && userId != null && contact.id.contains('-')) {
      try {
        final roomId = await client.rpc(
          'get_or_create_room',
          params: {'p_target_user_id': contact.id},
        );

        if (roomId != null) {
          final room = ChatRoom(
            id: roomId.toString(),
            name: contact.name,
            avatarUrl: contact.avatarUrl,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            isOnline: contact.isOnline,
          );
          _roomsCache ??= [];
          _roomsCache!.removeWhere((r) => r.id == room.id);
          _roomsCache!.insert(0, room);
          _messagesCache[room.id] = [];
          return room;
        }
      } catch (e) {
        debugPrint('[ChatService] Gagal create room via RPC: $e');
      }
    }

    _roomsCache ??= _seedRooms();
    final room = ChatRoom(
      id: contact.id,
      name: contact.name,
      avatarUrl: contact.avatarUrl,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isOnline: contact.isOnline,
    );
    _roomsCache!.insert(0, room);
    _messagesCache[room.id] = [];
    return room;
  }

  void _updateRoomPreview(String roomId, String text) {
    final rooms = _roomsCache;
    if (rooms == null) return;
    final updated = rooms.map((room) {
      if (room.id != roomId) return room;
      return room.copyWith(
        lastMessage: text,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        lastSenderName: 'Aku',
      );
    }).toList();
    updated.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _roomsCache = updated;
  }

  List<ChatRoom> _seedRooms() {
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    final yesterday = now.subtract(const Duration(days: 1));
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return [
      ChatRoom(
        id: 'dina',
        name: 'Dina Saftri',
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
        lastMessage: 'Sama-sama! Sampai nanti di sesi latihan 😊',
        lastMessageTime: at(10, 42),
        unreadCount: 1,
        isOnline: true,
      ),
      ChatRoom(
        id: 'klub_bisindo',
        name: 'Klub BISINDO Jakarta',
        isGroup: true,
        memberCount: 24,
        lastSenderName: 'Siti',
        lastMessage: 'Minggu ini latihan di Tebet Eco Park, ya!',
        lastMessageTime: at(10, 30),
        unreadCount: 2,
      ),
      ChatRoom(
        id: 'rian',
        name: 'Rian Pratama',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        lastMessage: "Sudah cocok ya? Coba 'terima kasih'?",
        lastMessageTime: at(9, 15),
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'budi',
        name: 'Budi Santoso',
        avatarUrl: 'https://i.pravatar.cc/150?img=33',
        lastMessage: 'Kamu luar biasa. Selamat untuk sertifikatnya! 🎉',
        lastMessageTime: yesterday,
      ),
      ChatRoom(
        id: 'teman_bab1',
        name: 'Teman Belajar Bab 1',
        isGroup: true,
        memberCount: 12,
        lastSenderName: 'Ayu',
        lastMessage: 'Yuk, ulang huruf J sampai R.',
        lastMessageTime: yesterday,
      ),
      ChatRoom(
        id: 'siti',
        name: 'Siti Rahma',
        avatarUrl: 'https://i.pravatar.cc/150?img=45',
        lastMessage: 'Aku kirim lokasi sesi belajarnya, ya.',
        lastMessageTime: threeDaysAgo,
      ),
    ];
  }

  List<ChatMessage> _seedMessages(String roomId) {
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    if (roomId == 'dina') {
      return [
        ChatMessage(
          id: 'm1',
          roomId: roomId,
          senderId: 'me',
          text: "Hai Dina! Aku masih bingung bentuk huruf 'D' di BISINDO. "
              'Boleh bantu cek? 😊',
          time: at(10, 32),
          isMe: true,
          isRead: true,
        ),
        ChatMessage(
          id: 'm2',
          roomId: roomId,
          senderId: 'dina',
          text: 'Hai! Tentu, kirim video gerakannya ya. Kita belajar bareng 💪',
          time: at(10, 34),
        ),
        ChatMessage(
          id: 'm3',
          roomId: roomId,
          senderId: 'me',
          text: 'Bingung gerakannya, sudah pas?',
          time: at(10, 36),
          isMe: true,
          isRead: true,
        ),
        ChatMessage(
          id: 'm4',
          roomId: roomId,
          senderId: 'dina',
          text: 'Sudah hampir pas! Coba tegakkan telunjuk dan rapatkan jari '
              'lainnya. Jangan lupa rilekskan tangan, ya.',
          time: at(10, 39),
        ),
        ChatMessage(
          id: 'm5',
          roomId: roomId,
          senderId: 'me',
          text: 'Oh, paham! Terima kasih, Dina. Nanti aku coba lagi di sesi '
              'latihan.',
          time: at(10, 41),
          isMe: true,
          isRead: true,
        ),
        ChatMessage(
          id: 'm6',
          roomId: roomId,
          senderId: 'dina',
          text: 'Sama-sama! Sampai nanti di sesi latihan 😊',
          time: at(10, 42),
          isNew: true,
        ),
      ];
    }

    return [
      ChatMessage(
        id: '$roomId-1',
        roomId: roomId,
        senderId: 'other',
        text: 'Hai! Selamat datang di ruang percakapan. 👋',
        time: at(9, 0),
      ),
    ];
  }
}
