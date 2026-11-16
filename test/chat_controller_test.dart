import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/models/chat_model.dart';
import 'package:sign_l/controllers/chat_controller.dart';
import 'package:sign_l/services/chat_service.dart';

class _ReversedMessagesService extends InMemoryChatService {
  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final messages = await super.getMessages(roomId);
    return messages.reversed.toList();
  }
}

void main() {
  group('ChatController', () {
    test('memuat, memfilter, dan mencari percakapan', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();

      expect(controller.rooms.length, 6);
      expect(controller.unreadRoomsCount, 3);
      expect(controller.totalUnreadMessages, 4);

      controller.setFilter(ChatFilter.grup);
      expect(controller.rooms.length, 2);
      expect(controller.rooms.every((room) => room.isGroup), isTrue);

      controller.setFilter(ChatFilter.semua);
      controller.search('Dina');
      expect(controller.rooms.length, 1);
      expect(controller.rooms.first.name, 'Dina Saftri');
    });

    test('membuka ruang menandai dibaca dan pesan tersimpan', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();

      final dina = controller.rooms.firstWhere((room) => room.id == 'dina');
      expect(dina.unreadCount, 1);

      await controller.openRoom(dina);
      expect(controller.unreadRoomsCount, 2);
      expect(controller.totalUnreadMessages, 3);
      expect(
        controller.activeMessages
            .firstWhere((message) => !message.isMe)
            .senderName,
        'Dina S.',
      );

      await controller.sendMessage('Halo Dina');
      expect(
        controller.activeMessages.any((message) => message.text == 'Halo Dina'),
        isTrue,
      );

      await controller.openRoom(dina);
      expect(
        controller.activeMessages.any((message) => message.text == 'Halo Dina'),
        isTrue,
      );
    });

    test('mengurutkan pesan dari lama ke baru', () async {
      final controller = ChatController(service: _ReversedMessagesService());
      await controller.loadRooms();
      await controller.openRoom(controller.rooms.firstWhere(
        (room) => room.id == 'dina',
      ));

      for (var index = 1; index < controller.activeMessages.length; index++) {
        expect(
          controller.activeMessages[index - 1].time
              .isBefore(controller.activeMessages[index].time),
          isTrue,
        );
      }
    });

    test('memulai chat baru dan membersihkan riwayat', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();
      await controller.loadContacts();

      final contact =
          controller.contacts.firstWhere((item) => item.id == 'ayu');
      final room = await controller.startChat(contact);

      expect(room.name, 'Ayu Lestari');
      expect(controller.activeRoom?.id, room.id);
      expect(controller.activeMessages, isEmpty);

      await controller.sendMessage('Hai Ayu');
      expect(controller.activeMessages.length, 1);

      await controller.clearActiveMessages();
      expect(controller.activeMessages, isEmpty);
    });

    test('membuat grup dari kontak terpilih', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();
      await controller.loadContacts();

      final members = controller.contacts
          .where((contact) => contact.id == 'ayu' || contact.id == 'rian')
          .toList();
      final room = await controller.startGroup(
        name: 'Grup Belajar',
        members: members,
      );

      expect(room.isGroup, isTrue);
      expect(room.name, 'Grup Belajar');
      expect(room.memberCount, 3);
      expect(controller.activeRoom?.id, room.id);
      expect(controller.activeMessages, isEmpty);
      expect(controller.isCreatingGroup, isFalse);
      expect(controller.rooms.any((item) => item.id == room.id), isTrue);

      controller.setFilter(ChatFilter.grup);
      expect(controller.rooms.any((item) => item.id == room.id), isTrue);
    });

    test('toggle mute menyimpan state per ruang', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();

      expect(controller.isMuted('dina'), isFalse);
      await controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isTrue);
      await controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isFalse);
    });

    test('menandai centang biru saat lawan membaca pesan', () async {
      final service = ChatService.inMemory() as InMemoryChatService;
      final controller = ChatController(service: service);
      await controller.loadRooms();
      await controller.openRoom(
        controller.rooms.firstWhere((room) => room.id == 'dina'),
      );

      await controller.sendMessage('Pesan untuk centang biru');
      final sent = controller.activeMessages
          .firstWhere((message) => message.text == 'Pesan untuk centang biru');
      expect(sent.isMe, isTrue);
      expect(sent.isRead, isFalse);

      service.simulatePeerRead(
        'dina',
        sent.time.add(const Duration(seconds: 1)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.activeMessages
            .firstWhere((message) => message.text == 'Pesan untuk centang biru')
            .isRead,
        isTrue,
      );
    });

    test('tidak menandai biru jika lawan membaca sebelum pesan dikirim',
        () async {
      final service = ChatService.inMemory() as InMemoryChatService;
      final controller = ChatController(service: service);
      await controller.loadRooms();
      await controller.openRoom(
        controller.rooms.firstWhere((room) => room.id == 'dina'),
      );

      await controller.sendMessage('Pesan terbaru');
      final sent = controller.activeMessages
          .firstWhere((message) => message.text == 'Pesan terbaru');

      service.simulatePeerRead(
        'dina',
        sent.time.subtract(const Duration(seconds: 1)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.activeMessages
            .firstWhere((message) => message.text == 'Pesan terbaru')
            .isRead,
        isFalse,
      );
    });

    test('reset membersihkan data saat logout', () async {
      final controller = ChatController(service: ChatService.inMemory());
      await controller.loadRooms();
      await controller.openRoom(controller.rooms.first);

      controller.reset();

      expect(controller.rooms, isEmpty);
      expect(controller.activeRoom, isNull);
      expect(controller.activeMessages, isEmpty);
    });
  });
}
