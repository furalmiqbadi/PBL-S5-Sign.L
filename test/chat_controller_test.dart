import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/controllers/chat_controller.dart';

void main() {
  group('ChatController', () {
    test('memuat, memfilter, dan mencari percakapan', () async {
      final controller = ChatController();
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
      final controller = ChatController();
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
      final controller = ChatController();
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

    test('toggle mute menyimpan state per ruang', () async {
      final controller = ChatController();
      await controller.loadRooms();

      expect(controller.isMuted('dina'), isFalse);
      controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isTrue);
      controller.toggleMute('dina');
      expect(controller.isMuted('dina'), isFalse);
    });
  });
}
