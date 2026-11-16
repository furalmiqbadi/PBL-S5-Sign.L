import 'dart:async';

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
  bool isCreatingGroup = false;
  String? contactsErrorMessage;

  // --- State ruang percakapan aktif ---
  ChatRoom? activeRoom;
  List<ChatMessage> activeMessages = [];
  bool isLoadingMessages = false;
  bool isSending = false;
  String? roomErrorMessage;

  final Set<String> _mutedRoomIds = {};

  // --- Realtime subscriptions ---
  StreamSubscription<ChatMessage>? _messagesSub;
  StreamSubscription<DateTime?>? _readStateSub;
  StreamSubscription<void>? _roomListSub;
  Timer? _roomListDebounce;

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

    var loaded = false;
    try {
      _rooms = await _service.getChatRooms();
      loaded = true;
      _mutedRoomIds
        ..clear()
        ..addAll(_rooms.where((room) => room.isMuted).map((room) => room.id));
    } catch (e) {
      errorMessage = 'Gagal memuat percakapan. Silakan coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }

    if (!loaded) return;

    // Subscribe stream perubahan daftar room (last message, unread count).
    // Dibatasi debounce 800 ms agar tidak terlalu banyak request ke server.
    _roomListSub?.cancel();
    _roomListSub = _service.watchRoomListChanges().listen((_) {
      _roomListDebounce?.cancel();
      _roomListDebounce = Timer(const Duration(milliseconds: 800), () async {
        try {
          final updated = await _service.getChatRooms();
          _rooms = updated;
          _mutedRoomIds
            ..clear()
            ..addAll(
              _rooms.where((r) => r.isMuted).map((r) => r.id),
            );
          notifyListeners();
        } catch (_) {
          // Gagal reload — abaikan, data lama tetap tampil.
        }
      });
    });
  }

  Future<void> loadContacts() async {
    isLoadingContacts = true;
    contactsErrorMessage = null;
    notifyListeners();

    try {
      contacts = await _service.getContacts();
    } catch (e) {
      contacts = [];
      contactsErrorMessage =
          'Gagal memuat kontak. Periksa koneksi lalu coba lagi.';
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

    // Batalkan subscription room lama sebelum buka room baru.
    await _messagesSub?.cancel();
    _messagesSub = null;
    await _readStateSub?.cancel();
    _readStateSub = null;

    var loaded = false;
    try {
      final readAtFuture =
          _service.getRoomReadAt(current.id).catchError((_) => null);
      activeMessages = await _service.getMessages(current.id);
      _sortActiveMessages();
      _applyReadState(await readAtFuture, notify: false);
      loaded = true;
    } catch (e) {
      debugPrint('Gagal memuat pesan room ${current.id}: $e');
      roomErrorMessage = 'Gagal memuat pesan. Silakan coba lagi.';
    }

    if (loaded) {
      _markRoomAsRead(current.id);
      // Menandai baca bersifat best-effort: jangan gagalkan tampilan pesan.
      try {
        await _service.markRoomRead(current.id);
      } catch (e) {
        debugPrint('Gagal menandai room ${current.id} dibaca: $e');
      }
    }

    isLoadingMessages = false;
    notifyListeners();

    if (!loaded) return;

    // Perbarui centang biru saat lawan bicara membaca pesan.
    _readStateSub = _service.watchRoomReadState(current.id).listen(
          (readAt) => _applyReadState(readAt),
        );

    // Subscribe pesan baru di room ini secara realtime.
    _messagesSub = _service.watchMessages(current.id).listen((message) {
      // Hindari duplikat pesan yang dikirim oleh diri sendiri
      // (sudah ditambahkan via sendMessage secara optimistik).
      final alreadyExists = activeMessages.any((m) => m.id == message.id);
      if (alreadyExists) return;

      activeMessages = [...activeMessages, message];
      _sortActiveMessages();

      // Kalau pesan dari orang lain, langsung tandai terbaca.
      if (!message.isMe) {
        _service.markRoomRead(current.id).catchError((_) {});
        _markRoomAsRead(current.id);
      }
      notifyListeners();
    });
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

  /// Membuat grup baru bersama kontak terpilih lalu membuka room-nya.
  Future<ChatRoom> startGroup({
    required String name,
    required List<ChatContact> members,
  }) async {
    isCreatingGroup = true;
    roomErrorMessage = null;
    notifyListeners();

    try {
      final room = await _service.createGroup(
        name: name.trim(),
        memberIds: members.map((member) => member.id).toList(),
      );
      _rooms = [
        room,
        ..._rooms.where((item) => item.id != room.id),
      ];
      await openRoom(room);
      return room;
    } catch (e) {
      roomErrorMessage = 'Gagal membuat grup. Coba lagi.';
      rethrow;
    } finally {
      isCreatingGroup = false;
      notifyListeners();
    }
  }

  Future<ChatRoom> loadRoomById(String roomId) async {
    final existing = _rooms.where((room) => room.id == roomId);
    if (existing.isNotEmpty) return existing.first;

    final room = await _service.getChatRoomById(roomId);
    _rooms = [room, ..._rooms];
    notifyListeners();
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
      if (!activeMessages.any((item) => item.id == message.id)) {
        activeMessages = [...activeMessages, message];
        _sortActiveMessages();
      }
      _updateRoomPreview(room.id, trimmed);
    } catch (e) {
      roomErrorMessage = 'Pesan gagal terkirim.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Menghapus seluruh riwayat pada ruang aktif.
  Future<bool> clearActiveMessages() async {
    final room = activeRoom;
    if (room == null) return false;
    roomErrorMessage = null;
    try {
      await _service.clearMessages(room.id);
      activeMessages = [];
      _rooms = _rooms
          .map(
            (item) => item.id == room.id
                ? item.copyWith(lastMessage: '', unreadCount: 0)
                : item,
          )
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      roomErrorMessage = 'Gagal membersihkan riwayat percakapan.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleMute(String roomId) async {
    final muted = !_mutedRoomIds.contains(roomId);
    if (muted) {
      _mutedRoomIds.add(roomId);
    } else {
      _mutedRoomIds.remove(roomId);
    }
    notifyListeners();
    try {
      await _service.setRoomMuted(roomId, muted);
      return true;
    } catch (e) {
      if (muted) {
        _mutedRoomIds.remove(roomId);
      } else {
        _mutedRoomIds.add(roomId);
      }
      roomErrorMessage = 'Gagal mengubah pengaturan notifikasi chat.';
      notifyListeners();
      return false;
    }
  }

  /// Menghentikan listener pesan ketika halaman room ditutup.
  void closeRoom() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _readStateSub?.cancel();
    _readStateSub = null;
    activeRoom = null;
    activeMessages = [];
  }

  /// Membersihkan data user lama setelah logout.
  void reset() {
    _messagesSub?.cancel();
    _readStateSub?.cancel();
    _roomListSub?.cancel();
    _roomListDebounce?.cancel();
    _messagesSub = null;
    _readStateSub = null;
    _roomListSub = null;
    _roomListDebounce = null;
    _rooms = [];
    contacts = [];
    isCreatingGroup = false;
    activeRoom = null;
    activeMessages = [];
    _mutedRoomIds.clear();
    errorMessage = null;
    roomErrorMessage = null;
    contactsErrorMessage = null;
    notifyListeners();
  }

  void _markRoomAsRead(String roomId) {
    _rooms = _rooms
        .map(
          (room) => room.id == roomId ? room.copyWith(unreadCount: 0) : room,
        )
        .toList();
  }

  /// Menandai pesan milik pengguna sebagai dibaca sampai waktu [readAt].
  void _applyReadState(DateTime? readAt, {bool notify = true}) {
    if (readAt == null) return;

    var changed = false;
    final updated = activeMessages.map((message) {
      if (!message.isMe || message.isRead) return message;
      if (message.time.isAfter(readAt)) return message;
      changed = true;
      return message.copyWith(isRead: true);
    }).toList();

    if (!changed) return;
    activeMessages = updated;
    if (notify) notifyListeners();
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

  void _sortActiveMessages() {
    activeMessages.sort((a, b) => a.time.compareTo(b.time));
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _roomListSub?.cancel();
    _roomListDebounce?.cancel();
    super.dispose();
  }
}
