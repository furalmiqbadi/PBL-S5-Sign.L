/// Model data murni untuk fitur Chat.
///
/// Tidak boleh berisi logika UI, Firebase, maupun perhitungan berat.
library;

/// Representasi sebuah ruang percakapan (personal atau grup).
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isGroup = false,
    this.memberCount,
    this.isOnline = false,
    this.lastSenderName,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final int? memberCount;
  final bool isOnline;

  /// Nama pengirim terakhir (dipakai untuk preview grup, mis. "Siti: ...").
  final String? lastSenderName;

  bool get hasUnread => unreadCount > 0;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime:
          DateTime.tryParse(json['lastMessageTime'] as String? ?? '') ??
              DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isGroup: json['isGroup'] as bool? ?? false,
      memberCount: json['memberCount'] as int?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSenderName: json['lastSenderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'unreadCount': unreadCount,
        'isGroup': isGroup,
        'memberCount': memberCount,
        'isOnline': isOnline,
        'lastSenderName': lastSenderName,
      };

  ChatRoom copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isGroup,
    int? memberCount,
    bool? isOnline,
    String? lastSenderName,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      memberCount: memberCount ?? this.memberCount,
      isOnline: isOnline ?? this.isOnline,
      lastSenderName: lastSenderName ?? this.lastSenderName,
    );
  }
}

/// Representasi satu pesan di dalam ruang percakapan.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.time,
    this.isMe = false,
    this.isRead = false,
    this.isNew = false,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final DateTime time;

  /// `true` jika pesan dikirim oleh pengguna saat ini.
  final bool isMe;

  /// Status centang (telah dibaca lawan bicara).
  final bool isRead;

  /// Penanda pemisah "N pesan baru".
  final bool isNew;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      isMe: json['isMe'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'senderId': senderId,
        'text': text,
        'time': time.toIso8601String(),
        'isMe': isMe,
        'isRead': isRead,
        'isNew': isNew,
      };
}
