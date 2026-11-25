import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/controllers/chat_controller.dart';
import 'package:sign_l/models/chat_model.dart';
import 'package:sign_l/services/chat_service.dart';

/// Pengganti [ChatService] berbasis data uji, tanpa jaringan Supabase.
class _FakeChatService extends ChatService {
  _FakeChatService() : super(client: null);

  final _pesan = <String, List<ChatMessage>>{};

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final now = DateTime.now();
    return [
      ChatRoom(
        id: 'dina',
        name: 'Dina Saftri',
        lastMessage: 'Sampai jumpa besok',
        lastMessageTime: now,
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'grup1',
        name: 'Klub BISINDO Jakarta',
        lastMessage: 'Latihan dimulai jam 4',
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isGroup: true,
        memberCount: 24,
      ),
      ChatRoom(
        id: 'rian',
        name: 'Rian Pratama',
        lastMessage: 'Terima kasih penjelasannya',
        lastMessageTime: now.subtract(const Duration(minutes: 12)),
        unreadCount: 1,
      ),
      ChatRoom(
        id: 'ayu',
        name: 'Ayu Lestari',
        lastMessage: 'Besok kita latihan lagi ya',
        lastMessageTime: now.subtract(const Duration(hours: 1)),
      ),
      ChatRoom(
        id: 'budi',
        name: 'Budi Santoso',
        lastMessage: 'Gambarnya sudah kukirim',
        lastMessageTime: now.subtract(const Duration(hours: 3)),
      ),
      ChatRoom(
        id: 'grup2',
        name: 'Kelas Alfabet Dasar',
        lastMessage: 'Tugas minggu ini sudah dibuka',
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        isGroup: true,
        memberCount: 12,
      ),
    ];
  }

  @override
  Future<List<ChatContact>> getContacts() async => const [
        ChatContact(id: 'ayu', name: 'Ayu Lestari'),
      ];

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async =>
      List<ChatMessage>.from(_pesan[roomId] ?? const []);

  @override
  Future<void> markRoomRead(String roomId) async {}

  @override
  Future<ChatRoom> createRoom(ChatContact contact) async => ChatRoom(
        id: 'baru-${contact.id}',
        name: contact.name,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        peerId: contact.id,
      );

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final pesan = ChatMessage(
      id: 'm${(_pesan[roomId]?.length ?? 0) + 1}',
      roomId: roomId,
      senderId: 'aku',
      text: text.trim(),
      time: DateTime.now(),
      isMe: true,
      isRead: true,
    );
    _pesan.update(roomId, (list) => [...list, pesan], ifAbsent: () => [pesan]);
    return pesan;
  }

  @override
  Future<void> clearMessages(String roomId) async => _pesan[roomId] = [];
}

ChatController _controller() => ChatController(service: _FakeChatService());

void main() {
  group('ChatController', () {
    test('memuat, memfilter, dan mencari percakapan', () async {
      final controller = _controller();
      await controller.loadRooms();

      expect(controller.rooms.length, 6);
      expect(controller.unreadRoomsCount, 3);
      expect(controller.totalUnreadMessages, 4);

      controller.setFilter(ChatFilter.semua);
      controller.search('Dina');
      expect(controller.rooms.length, 1);
      expect(controller.rooms.first.name, 'Dina Saftri');
    });

    test('membuka ruang menandai dibaca dan pesan tersimpan', () async {
      final controller = _controller();
      await controller.loadRooms();

      final dina = controller.rooms.firstWhere((room) => room.id == 'dina');
      expect(dina.unreadCount, 1);

      await controller.openRoom(dina);
      expect(controller.unreadRoomsCount, 2);
      expect(controller.totalUnreadMessages, 3);

      await controller.sendMessage('Halo Dina');
      expect(controller.activeMessages.last.text, 'Halo Dina');

      await controller.openRoom(dina);
      expect(
        controller.activeMessages.any((message) => message.text == 'Halo Dina'),
        isTrue,
      );
    });

    test('memulai chat baru dan membersihkan riwayat', () async {
      final controller = _controller();
      await controller.loadRooms();
      await controller.loadContacts();

      final contact =
          controller.contacts.firstWhere((item) => item.id == 'ayu');
      controller.search('');
      final room = await controller.startChat(contact);

      expect(room.name, 'Ayu Lestari');
      expect(controller.activeRoom?.id, room.id);
      expect(controller.activeMessages, isEmpty);

      await controller.sendMessage('Hai Ayu');
      expect(controller.activeMessages.length, 1);

      await controller.clearActiveMessages();
      expect(controller.activeMessages, isEmpty);
    });

    test('toggle mute menyimpan state per ruang', () async {
      final controller = _controller();
      await controller.loadRooms();

      expect(controller.isMuted('dina'), isFalse);
      controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isTrue);
      controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isFalse);
    });
  });
}
