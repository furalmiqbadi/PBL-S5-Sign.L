import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Filter daftar percakapan pada layar Chat.
enum ChatFilter { semua, belumDibaca, grup }

/// Thin Controller untuk fitur Chat.
///
/// Hanya mengelola state UI dan mendelegasikan pengambilan data ke
/// [ChatService]. Tidak boleh memuat logika berat / akses database langsung.
class ChatController extends ChangeNotifier {
  ChatController({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  // --- State daftar percakapan ---
  bool isLoading = false;
  String? errorMessage;
  List<ChatRoom> _rooms = [];
  ChatFilter filter = ChatFilter.semua;
  String query = '';

  // --- State daftar kontak untuk pesan baru ---
  List<ChatContact> contacts = [];
  bool isLoadingContacts = false;

  // --- State ruang percakapan aktif ---
  ChatRoom? activeRoom;
  List<ChatMessage> activeMessages = [];
  bool isLoadingMessages = false;
  bool isSending = false;
  String? roomErrorMessage;

  final Set<String> _mutedRoomIds = {};

  /// Daftar percakapan setelah difilter (kategori + kata kunci pencarian).
  List<ChatRoom> get rooms {
    Iterable<ChatRoom> result = _rooms;

    switch (filter) {
      case ChatFilter.semua:
        break;
      case ChatFilter.belumDibaca:
        result = result.where((room) => room.hasUnread);
        break;
      case ChatFilter.grup:
        result = result.where((room) => room.isGroup);
        break;
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where(
        (room) =>
            room.name.toLowerCase().contains(q) ||
            room.lastMessage.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  /// Jumlah percakapan yang masih memiliki pesan belum dibaca.
  int get unreadRoomsCount => _rooms.where((room) => room.hasUnread).length;

  /// Total pesan belum dibaca (untuk badge pada bottom navigation).
  int get totalUnreadMessages =>
      _rooms.fold(0, (sum, room) => sum + room.unreadCount);

  bool isMuted(String roomId) => _mutedRoomIds.contains(roomId);

  Future<void> loadRooms() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _rooms = await _service.getChatRooms();
    } catch (e) {
      errorMessage = 'Gagal memuat percakapan. Silakan coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContacts() async {
    isLoadingContacts = true;
    notifyListeners();

    try {
      contacts = await _service.getContacts();
    } catch (e) {
      contacts = [];
    } finally {
      isLoadingContacts = false;
      notifyListeners();
    }
  }

  void setFilter(ChatFilter value) {
    if (filter == value) return;
    filter = value;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  /// Membuka ruang percakapan dan memuat riwayat pesannya.
  Future<void> openRoom(ChatRoom room) async {
    final current = _rooms.firstWhere(
      (item) => item.id == room.id,
      orElse: () => room,
    );
    activeRoom = current;
    activeMessages = [];
    roomErrorMessage = null;
    isLoadingMessages = true;
    notifyListeners();

    try {
      activeMessages = await _service.getMessages(current.id);
      _markRoomAsRead(current.id);
      await _service.markRoomRead(current.id);
    } catch (e) {
      roomErrorMessage = 'Gagal memuat pesan. Silakan coba lagi.';
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Memulai percakapan dengan sebuah kontak, membuat ruang baru bila perlu.
  Future<ChatRoom> startChat(ChatContact contact) async {
    for (final room in _rooms) {
      if (room.name.toLowerCase() == contact.name.toLowerCase()) {
        await openRoom(room);
        return room;
      }
    }

    final room = await _service.createRoom(contact);
    _rooms = [room, ..._rooms];
    notifyListeners();
    await openRoom(room);
    return room;
  }

  /// Mengirim pesan baru pada ruang aktif.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final room = activeRoom;
    if (trimmed.isEmpty || room == null || isSending) return;

    isSending = true;
    roomErrorMessage = null;
    notifyListeners();

    try {
      final message = await _service.sendMessage(
        roomId: room.id,
        text: trimmed,
      );
      activeMessages = [...activeMessages, message];
      _updateRoomPreview(room.id, trimmed);
    } catch (e) {
      roomErrorMessage = 'Pesan gagal terkirim.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Menghapus seluruh riwayat pada ruang aktif.
  Future<void> clearActiveMessages() async {
    final room = activeRoom;
    if (room == null) return;
    await _service.clearMessages(room.id);
    activeMessages = [];
    notifyListeners();
  }

  void toggleMute(String roomId) {
    if (!_mutedRoomIds.remove(roomId)) {
      _mutedRoomIds.add(roomId);
    }
    notifyListeners();
  }

  void _markRoomAsRead(String roomId) {
    _rooms = _rooms
        .map(
          (room) => room.id == roomId ? room.copyWith(unreadCount: 0) : room,
        )
        .toList();
  }

  void _updateRoomPreview(String roomId, String text) {
    final updated = _rooms.map((room) {
      if (room.id != roomId) return room;
      return room.copyWith(
        lastMessage: text,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        lastSenderName: 'Aku',
      );
    }).toList();

    updated.sort(
      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
    );
    _rooms = updated;
  }
}
