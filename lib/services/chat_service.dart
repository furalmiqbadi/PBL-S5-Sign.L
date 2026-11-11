import '../models/chat_model.dart';

/// Service Layer untuk fitur Chat.
///
/// Saat ini memakai data dummy yang disimpan di memori agar percakapan yang
/// dikirim pengguna tetap ada selama aplikasi berjalan. Implementasi dapat
/// diganti dengan query Cloud Firestore tanpa mengubah Controller maupun View.
class ChatService {
  List<ChatRoom>? _roomsCache;
  final Map<String, List<ChatMessage>> _messagesCache = {};

  /// Mengambil daftar ruang percakapan pengguna.
  Future<List<ChatRoom>> getChatRooms() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _roomsCache ??= _seedRooms();
    return List<ChatRoom>.from(_roomsCache!);
  }

  /// Mengambil daftar kontak untuk memulai percakapan baru.
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
  Future<List<ChatMessage>> getMessages(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<ChatMessage>.from(
      _messagesCache.putIfAbsent(roomId, () => _seedMessages(roomId)),
    );
  }

  /// Mengirim pesan baru ke sebuah ruang percakapan.
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
  Future<void> markRoomRead(String roomId) async {
    _roomsCache = _roomsCache
        ?.map(
          (room) => room.id == roomId ? room.copyWith(unreadCount: 0) : room,
        )
        .toList();
  }

  /// Mengosongkan riwayat pesan pada sebuah ruang.
  Future<void> clearMessages(String roomId) async {
    _messagesCache[roomId] = [];
  }

  /// Membuat ruang percakapan baru untuk sebuah kontak.
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
