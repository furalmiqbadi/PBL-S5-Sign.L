import '../models/chat_model.dart';

/// Service Layer untuk fitur Chat.
///
/// Saat ini mengembalikan data dummy agar UI dapat dikembangkan lebih dulu.
/// Nanti implementasi dapat diganti dengan query Cloud Firestore tanpa
/// mengubah Controller maupun View.
class ChatService {
  /// Mengambil daftar ruang percakapan pengguna.
  Future<List<ChatRoom>> getChatRooms() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

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

  /// Mengambil riwayat pesan pada sebuah ruang percakapan.
  Future<List<ChatMessage>> getMessages(String roomId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

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

  /// Mengirim pesan baru ke sebuah ruang percakapan.
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: 'me',
      text: text,
      time: DateTime.now(),
      isMe: true,
    );
  }
}
