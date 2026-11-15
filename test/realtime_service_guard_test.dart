import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/services/chat_service.dart';
import 'package:sign_l/services/notification_service.dart';

void main() {
  test('chat realtime aman saat Supabase belum siap', () async {
    final service = ChatService();

    await expectLater(service.watchMessages('room'), emitsDone);
    await expectLater(service.watchRoomListChanges(), emitsDone);
  });

  test('notification realtime aman saat Supabase belum siap', () async {
    final service = NotificationService();

    await expectLater(service.watchNewNotifications(), emitsDone);
  });
}
