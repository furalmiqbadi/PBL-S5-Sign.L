import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_model.dart';

abstract class ChatService {
  factory ChatService({SupabaseClient? client}) = SupabaseChatService;
  factory ChatService.inMemory() = InMemoryChatService;

  Future<List<ChatRoom>> getChatRooms();
  Future<List<ChatContact>> getContacts();
  Future<List<ChatMessage>> getMessages(String roomId);
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  });
  Future<void> markRoomRead(String roomId);
  Future<void> clearMessages(String roomId);
  Future<void> setRoomMuted(String roomId, bool muted);
  Future<ChatRoom> createRoom(ChatContact contact);
  Future<ChatRoom> createGroup({
    required String name,
    required List<String> memberIds,
  });
  Future<ChatRoom> getChatRoomById(String roomId);

  /// Stream pesan baru yang masuk ke [roomId].
  /// Emit setiap kali ada INSERT baru di tabel `chat_messages`.
  Stream<ChatMessage> watchMessages(String roomId);

  /// Waktu baca paling awal di antara seluruh anggota lain pada [roomId].
  /// `null` jika belum ada anggota lain yang membuka percakapan.
  Future<DateTime?> getRoomReadAt(String roomId);

  /// Stream waktu baca lawan bicara pada [roomId] yang berubah secara realtime.
  Stream<DateTime?> watchRoomReadState(String roomId);

  /// Stream yang emit setiap ada pesan baru di salah satu room yang diikuti user.
  /// Dipakai controller untuk reload daftar room (last message, unread count).
  Stream<void> watchRoomListChanges();
}

class SupabaseChatService implements ChatService {
  SupabaseChatService({SupabaseClient? client}) : _customClient = client;

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
    if (id == null) throw StateError('Silakan login untuk menggunakan chat.');
    return id;
  }

  bool get _hasAuthenticatedSession {
    try {
      return _client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Cache nama/foto pengirim untuk gelembung chat grup.
  ///
  /// Sumbernya RPC `get_chat_contacts` yang sudah dipakai untuk daftar kontak.
  /// Profil di bawah RLS hanya bisa dibaca milik sendiri, jadi nama pengirim
  /// lain harus lewat RPC tersebut.
  Map<String, ChatContact>? _contactCache;
  DateTime? _contactCacheAt;
  static const Duration _contactCacheTtl = Duration(minutes: 2);

  Future<Map<String, ChatContact>> _senderMap({
    bool force = false,
    String? requireId,
  }) async {
    final cachedAt = _contactCacheAt;
    final cacheFresh = _contactCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _contactCacheTtl;
    final cacheHasSender =
        requireId == null || (_contactCache?.containsKey(requireId) ?? false);
    if (!force && cacheFresh && cacheHasSender) {
      return _contactCache!;
    }
    // Cache masih segar tapi pengirim belum ada (mis. anggota baru) → muat ulang.
    final retry = !force && cacheFresh && !cacheHasSender;

    final contacts = await getContacts();
    _contactCache = {for (final contact in contacts) contact.id: contact};
    _contactCacheAt = DateTime.now();
    if (retry && !_contactCache!.containsKey(requireId)) {
      return _senderMap(force: true, requireId: requireId);
    }
    return _contactCache!;
  }

  String _nonEmptyText(Object? value, String fallback) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  void _requireAuthenticated() {
    if (_client.auth.currentUser == null) {
      throw StateError('Silakan login untuk menggunakan chat.');
    }
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    _requireAuthenticated();
    final rows = await _client.rpc('get_chat_rooms') as List<dynamic>;
    return rows.map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final lastSender = _nonEmptyText(row['last_sender_name'], '');
      return ChatRoom(
        id: row['id'].toString(),
        name: _nonEmptyText(row['name'], 'Percakapan'),
        avatarUrl: row['avatar_url'] as String?,
        lastMessage: row['last_message'] as String? ?? '',
        lastMessageTime: DateTime.tryParse(
              row['last_message_time']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now(),
        unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
        isGroup: row['is_group'] as bool? ?? false,
        memberCount: (row['member_count'] as num?)?.toInt(),
        lastSenderName: lastSender.isEmpty ? null : lastSender,
        isMuted: row['is_muted'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<List<ChatContact>> getContacts() async {
    _requireAuthenticated();
    final rows = await _client.rpc('get_chat_contacts') as List<dynamic>;
    return rows.map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final username = _nonEmptyText(row['username'], '');
      final fullName = _nonEmptyText(row['full_name'], '');
      final name = fullName.isNotEmpty
          ? fullName
          : (username.isNotEmpty ? username : 'Pengguna');
      return ChatContact(
        id: row['user_id'].toString(),
        name: name,
        avatarUrl: row['avatar_url'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final userId = _userId;
    final rows = await _client
        .from('chat_messages')
        .select('id, room_id, sender_id, body, created_at')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    final senders = await _senderMap(force: true).catchError(
      (_) => const <String, ChatContact>{},
    );
    return rows.map((row) {
      final senderId = row['sender_id'] as String;
      final sender = senders[senderId];
      return ChatMessage(
        id: row['id'] as String,
        roomId: row['room_id'] as String,
        senderId: senderId,
        text: row['body'] as String,
        time: DateTime.parse(row['created_at'] as String).toLocal(),
        isMe: senderId == userId,
        senderName: sender?.name,
        senderAvatarUrl: sender?.avatarUrl,
      );
    }).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final userId = _userId;
    final row = await _client
        .from('chat_messages')
        .insert({
          'room_id': roomId,
          'sender_id': userId,
          'body': text.trim(),
        })
        .select('id, room_id, sender_id, body, created_at')
        .single();
    return ChatMessage(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      senderId: row['sender_id'] as String,
      text: row['body'] as String,
      time: DateTime.parse(row['created_at'] as String).toLocal(),
      isMe: true,
    );
  }

  @override
  Future<void> markRoomRead(String roomId) async {
    await _client.rpc(
      'mark_chat_room_read',
      params: {'target_room_id': roomId},
    );
  }

  @override
  Future<DateTime?> getRoomReadAt(String roomId) async {
    if (!_hasAuthenticatedSession) return null;
    final value = await _client.rpc(
      'get_chat_room_read_at',
      params: {'target_room_id': roomId},
    );
    return _parseTimestamp(value);
  }

  @override
  Future<void> clearMessages(String roomId) async {
    await _client.rpc(
      'clear_chat_room_history',
      params: {'target_room_id': roomId},
    );
  }

  @override
  Future<void> setRoomMuted(String roomId, bool muted) async {
    await _client.rpc(
      'set_chat_room_muted',
      params: {'target_room_id': roomId, 'muted': muted},
    );
  }

  @override
  Future<ChatRoom> createRoom(ChatContact contact) async {
    final roomId = await _client.rpc(
      'get_or_create_direct_chat',
      params: {'target_user_id': contact.id},
    ) as String;
    final rooms = await getChatRooms();
    return rooms.firstWhere((room) => room.id == roomId);
  }

  @override
  Future<ChatRoom> getChatRoomById(String roomId) async {
    final rooms = await getChatRooms();
    return rooms.firstWhere(
      (room) => room.id == roomId,
      orElse: () => throw StateError('Percakapan tidak ditemukan.'),
    );
  }

  @override
  Future<ChatRoom> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    _requireAuthenticated();
    final roomId = await _client.rpc(
      'create_chat_group',
      params: {
        'group_name': name,
        'member_ids': memberIds,
      },
    ) as String;
    return ChatRoom(
      id: roomId,
      name: name.trim(),
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isGroup: true,
      memberCount: memberIds.length + 1,
    );
  }

  @override
  Stream<ChatMessage> watchMessages(String roomId) {
    if (!_hasAuthenticatedSession) return const Stream.empty();
    final userId = _userId;
    // ignore: close_sinks — StreamController di-close lewat onCancel
    late StreamController<ChatMessage> controller;
    RealtimeChannel? channel;

    controller = StreamController<ChatMessage>.broadcast(
      onListen: () {
        channel = _client
            .channel(
                'chat_messages:$roomId:${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'room_id',
                value: roomId,
              ),
              callback: (payload) async {
                if (controller.isClosed) return;
                final row = payload.newRecord;
                final senderId = row['sender_id'] as String? ?? '';
                String? senderName;
                String? senderAvatarUrl;
                if (senderId != userId) {
                  try {
                    final sender = (await _senderMap(
                      requireId: senderId,
                    ))[senderId];
                    senderName = sender?.name;
                    senderAvatarUrl = sender?.avatarUrl;
                  } catch (_) {
                    // Nama pengirim opsional; pesan tetap ditampilkan.
                  }
                }
                if (controller.isClosed) return;
                controller.add(
                  ChatMessage(
                    id: row['id'] as String? ?? '',
                    roomId: row['room_id'] as String? ?? roomId,
                    senderId: senderId,
                    text: row['body'] as String? ?? '',
                    time: DateTime.tryParse(
                          row['created_at'] as String? ?? '',
                        )?.toLocal() ??
                        DateTime.now(),
                    isMe: senderId == userId,
                    senderName: senderName,
                    senderAvatarUrl: senderAvatarUrl,
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

  @override
  Stream<DateTime?> watchRoomReadState(String roomId) {
    if (!_hasAuthenticatedSession) return const Stream.empty();
    // ignore: close_sinks
    late StreamController<DateTime?> controller;
    RealtimeChannel? channel;
    Timer? debounce;

    controller = StreamController<DateTime?>.broadcast(
      onListen: () {
        channel = _client
            .channel(
                'chat_read_state:$roomId:${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'chat_room_members',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'room_id',
                value: roomId,
              ),
              callback: (_) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 150), () async {
                  if (controller.isClosed) return;
                  try {
                    controller.add(await getRoomReadAt(roomId));
                  } catch (_) {
                    // Abaikan kegagalan sesaat; status akan disinkronkan lagi
                    // saat event berikutnya atau ketika room dibuka ulang.
                  }
                });
              },
            )
            .subscribe();
      },
      onCancel: () {
        debounce?.cancel();
        channel?.unsubscribe();
        controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Stream<void> watchRoomListChanges() {
    if (!_hasAuthenticatedSession) return const Stream.empty();
    // ignore: close_sinks
    late StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _client
            .channel(
                'room_list_changes:${DateTime.now().millisecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_messages',
              callback: (payload) {
                if (controller.isClosed) return;
                controller.add(null);
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'chat_room_members',
              callback: (payload) {
                if (controller.isClosed) return;
                controller.add(null);
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
class InMemoryChatService implements ChatService {
  List<ChatRoom>? _roomsCache;
  final Map<String, List<ChatMessage>> _messagesCache = {};
  final Set<String> _mutedRoomIds = {};
  final Map<String, DateTime?> _roomReadAt = {};
  final Map<String, StreamController<DateTime?>> _readStateControllers = {};

  /// Mengambil daftar ruang percakapan pengguna.
  @override
  Future<List<ChatRoom>> getChatRooms() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _roomsCache ??= _seedRooms();
    return List<ChatRoom>.from(_roomsCache!);
  }

  /// Mengambil daftar kontak untuk memulai percakapan baru.
  @override
  Future<List<ChatContact>> getContacts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
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
  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<ChatMessage>.from(
      _messagesCache.putIfAbsent(roomId, () => _seedMessages(roomId)),
    );
  }

  /// Mengirim pesan baru ke sebuah ruang percakapan.
  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: 'me',
      text: text,
      time: DateTime.now(),
      isMe: true,
    );
    _messagesCache
        .putIfAbsent(roomId, () => _seedMessages(roomId))
        .add(message);
    _updateRoomPreview(roomId, text);
    return message;
  }

  /// Menandai seluruh pesan pada ruang sebagai telah dibaca.
  @override
  Future<void> markRoomRead(String roomId) async {
    _roomsCache = _roomsCache
        ?.map(
          (room) => room.id == roomId ? room.copyWith(unreadCount: 0) : room,
        )
        .toList();
  }

  /// Mengosongkan riwayat pesan pada sebuah ruang.
  @override
  Future<void> clearMessages(String roomId) async {
    _messagesCache[roomId] = [];
  }

  /// Membuat ruang percakapan baru untuk sebuah kontak.
  @override
  Future<ChatRoom> createRoom(ChatContact contact) async {
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

  @override
  Future<ChatRoom> getChatRoomById(String roomId) async {
    _roomsCache ??= _seedRooms();
    return _roomsCache!.firstWhere(
      (room) => room.id == roomId,
      orElse: () => throw StateError('Percakapan tidak ditemukan.'),
    );
  }

  @override
  Future<ChatRoom> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    _roomsCache ??= _seedRooms();
    final room = ChatRoom(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      isGroup: true,
      memberCount: memberIds.length + 1,
    );
    _roomsCache!.insert(0, room);
    _messagesCache[room.id] = [];
    return room;
  }

  @override
  Future<void> setRoomMuted(String roomId, bool muted) async {
    if (muted) {
      _mutedRoomIds.add(roomId);
    } else {
      _mutedRoomIds.remove(roomId);
    }
  }

  /// In-memory tidak mendukung realtime — kembalikan stream kosong.
  @override
  Stream<ChatMessage> watchMessages(String roomId) => const Stream.empty();

  @override
  Future<DateTime?> getRoomReadAt(String roomId) async => _roomReadAt[roomId];

  @override
  Stream<DateTime?> watchRoomReadState(String roomId) {
    final controller = _readStateControllers.putIfAbsent(
      roomId,
      () => StreamController<DateTime?>.broadcast(),
    );
    return controller.stream;
  }

  /// Mensimulasikan lawan bicara membuka [roomId] pada waktu [readAt].
  void simulatePeerRead(String roomId, DateTime readAt) {
    _roomReadAt[roomId] = readAt;
    _readStateControllers[roomId]?.add(readAt);
  }

  /// In-memory tidak mendukung realtime — kembalikan stream kosong.
  @override
  Stream<void> watchRoomListChanges() => const Stream.empty();

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
        lastMessage: 'Minggu ini latihan di Tabel, ya!',
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
        lastMessage: 'Kamu. Selamat untuk sertifikatnya! 🎉',
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
          senderName: 'Dina S.',
          text: 'Hai Sarah, tentu! Kirim video gerakannya, ya. '
              'Kita belajar bareng 💪',
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
          senderName: 'Dina S.',
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
          senderName: 'Dina S.',
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
        senderName: 'Pengguna',
        text: 'Hai! Selamat datang di ruang percakapan. 👋',
        time: at(9, 0),
      ),
    ];
  }
}
