/// Model data murni untuk fitur Notifikasi.
///
/// Tidak boleh berisi logika UI, Firebase, maupun perhitungan berat.
library;

/// Kategori notifikasi (dipakai untuk filter dan pemilihan ikon di View).
enum NotificationCategory { komunitas, belajar, pencapaian }

extension NotificationCategoryX on NotificationCategory {
  /// Label Indonesia untuk ditampilkan pada tag kategori.
  String get label {
    switch (this) {
      case NotificationCategory.komunitas:
        return 'Komunitas';
      case NotificationCategory.belajar:
        return 'Belajar';
      case NotificationCategory.pencapaian:
        return 'Pencapaian';
    }
  }

  static NotificationCategory fromName(String value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationCategory.komunitas,
    );
  }
}

/// Representasi satu notifikasi aplikasi.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.actionLabel,
    this.avatarUrl,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  /// Label tautan aksi, mis. "Lihat diskusi", "Lanjutkan belajar".
  final String? actionLabel;

  /// URL avatar pengirim (opsional). Jika null, ikon kategori yang dipakai.
  final String? avatarUrl;

  bool get hasAction => actionLabel != null && actionLabel!.isNotEmpty;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      category: NotificationCategoryX.fromName(
        json['category'] as String? ?? 'komunitas',
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      actionLabel: json['actionLabel'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'isRead': isRead,
        'actionLabel': actionLabel,
        'avatarUrl': avatarUrl,
      };

  AppNotification copyWith({
    String? id,
    NotificationCategory? category,
    String? title,
    String? body,
    DateTime? time,
    bool? isRead,
    String? actionLabel,
    String? avatarUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
