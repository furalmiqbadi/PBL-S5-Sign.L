import 'nama_tampil.dart';

/// Satu baris tabel `profiles` yang dipakai halaman Profil, Edit Profil,
/// dan Papan Peringkat.
class ProfilPengguna {
  final String id;
  final String nama;
  final String username;
  final String role;
  final String avatarUrl;
  final int xp;
  final int points;
  final int streak;

  /// Kolom tambahan; kosong bila belum tersedia di server.
  final String bio;
  final String phone;
  final int level;
  final List<String> motivation;
  final List<String> featuredBadges;
  final DateTime? dibuat;

  const ProfilPengguna({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    required this.avatarUrl,
    required this.xp,
    required this.points,
    required this.streak,
    this.bio = '',
    this.phone = '',
    this.level = 1,
    this.motivation = const [],
    this.featuredBadges = const [],
    this.dibuat,
  });

  factory ProfilPengguna.fromRow(Map<String, dynamic> row) {
    final nama = (row['full_name'] as String?)?.trim() ?? '';
    final username = (row['username'] as String?)?.trim() ?? '';
    return ProfilPengguna(
      id: row['id'].toString(),
      nama: nama.isNotEmpty
          ? nama
          : (username.isNotEmpty ? username : labelNamaNetral),
      username: username,
      role: (row['role'] as String?) ?? 'user',
      avatarUrl: (row['avatar_url'] as String?)?.trim() ?? '',
      xp: (row['xp'] as num?)?.toInt() ?? 0,
      points: (row['points'] as num?)?.toInt() ?? 0,
      streak: (row['streak'] as num?)?.toInt() ?? 0,
      bio: (row['bio'] as String?)?.trim() ?? '',
      phone: (row['phone'] as String?)?.trim() ?? '',
      level: (row['level'] as num?)?.toInt() ?? 1,
      motivation: _keDaftar(row['motivation']),
      featuredBadges: _keDaftar(row['featured_badges']),
      dibuat: DateTime.tryParse((row['created_at'] as String?) ?? ''),
    );
  }

  static List<String> _keDaftar(Object? nilai) {
    if (nilai is List) {
      return nilai
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String get usernameText => username.isEmpty ? '-' : '@$username';

  String get roleLabel => labelPeran(role);

  /// "1280" -> "1.280"
  static String formatAngka(int nilai) {
    final s = nilai.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
