/// Data profil pengguna dari tabel `profiles`.
///
/// `level` disimpan sebagai angka 1-3 di database; label tampilan
/// diturunkan lewat [levelLabel] dan [levelCode].
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.bio = '',
    this.phone,
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.points = 0,
    this.featuredBadges = const [],
    this.motivations = const [],
    this.updatedAt,
  });

  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String bio;
  final String? phone;
  final int level;
  final int xp;
  final int streak;
  final int points;
  final List<String> featuredBadges;
  final List<String> motivations;
  final DateTime? updatedAt;

  static const List<String> _levelLabels = [
    'Tingkat Pemula (Level 1)',
    'Tingkat Menengah (Level 2)',
    'Tingkat Mahir (Level 3)',
  ];

  static const List<String> _levelDescriptions = [
    'BISINDO dasar & alfabet',
    'BISINDO & Pemahaman Ekspresif',
    'Percakapan mahir & ekspresi kompleks',
  ];

  int get _safeLevel => level.clamp(1, 3);

  String get levelCode => 'L$_safeLevel';

  String get levelLabel => _levelLabels[_safeLevel - 1];

  String get levelDescription => _levelDescriptions[_safeLevel - 1];

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    if (username.trim().isNotEmpty) return username.trim();
    return 'Pengguna';
  }

  String get displayUsername {
    final name = username.trim();
    return name.isEmpty ? '' : '@$name';
  }

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    int? level,
    int? xp,
    int? streak,
    int? points,
    List<String>? featuredBadges,
    List<String>? motivations,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      points: points ?? this.points,
      featuredBadges: featuredBadges ?? this.featuredBadges,
      motivations: motivations ?? this.motivations,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: (json['bio'] as String?) ?? '',
      phone: json['phone'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      featuredBadges: _stringList(json['featured_badges']),
      motivations: _stringList(json['learning_motivations']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
