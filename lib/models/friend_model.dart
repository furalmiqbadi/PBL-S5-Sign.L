import 'nama_tampil.dart';

/// Hubungan antara pengguna yang sedang login dengan pengguna lain.
enum StatusTeman {
  /// Belum ada relasi apa pun.
  tidakAda,

  /// Kita sudah mengirim permintaan, menunggu jawaban mereka.
  menungguMereka,

  /// Mereka mengirim permintaan, menunggu jawaban kita.
  menungguKita,

  /// Sudah berteman.
  berteman,

  /// Permintaan ditolak (bisa dikirim ulang).
  ditolak,

  /// Diblokir.
  diblokir,
}

extension StatusTemanLabel on StatusTeman {
  String get label => switch (this) {
        StatusTeman.tidakAda => 'Tambah teman',
        StatusTeman.menungguMereka => 'Menunggu',
        StatusTeman.menungguKita => 'Terima',
        StatusTeman.berteman => 'Teman',
        StatusTeman.ditolak => 'Tambah teman',
        StatusTeman.diblokir => 'Diblokir',
      };

  bool get bisaMinta =>
      this == StatusTeman.tidakAda || this == StatusTeman.ditolak;
}

/// Satu pengguna yang tampil di daftar teman, saran, atau hasil pencarian.
class Teman {
  const Teman({
    required this.id,
    required this.nama,
    this.username = '',
    this.avatarUrl,
    this.role = 'pembelajar',
    this.points = 0,
    this.friendshipId,
    this.status = StatusTeman.tidakAda,
  });

  final String id;
  final String nama;
  final String username;
  final String? avatarUrl;
  final String role;
  final int points;

  /// Id baris `friendships`; null bila belum ada relasi.
  final String? friendshipId;
  final StatusTeman status;

  bool get isAdmin => role == 'admin';

  /// Label peran siap tampil, mis. `Admin`, `Mentor Tuli`, `Pembelajar`.
  String get peran => labelPeran(role);

  Teman copyWith({StatusTeman? status, String? friendshipId}) => Teman(
        id: id,
        nama: nama,
        username: username,
        avatarUrl: avatarUrl,
        role: role,
        points: points,
        friendshipId: friendshipId ?? this.friendshipId,
        status: status ?? this.status,
      );

  factory Teman.fromProfil(
    Map<String, dynamic> row, {
    String? friendshipId,
    StatusTeman status = StatusTeman.tidakAda,
  }) =>
      Teman(
        id: row['id'].toString(),
        nama: namaTampilDari(row),
        username: usernameTampilDari(row),
        avatarUrl: (row['avatar_url'] as String?)?.trim().isEmpty ?? true
            ? null
            : (row['avatar_url'] as String).trim(),
        role: (row['role'] as String?) ?? 'pembelajar',
        points: (row['points'] as num?)?.toInt() ?? 0,
        friendshipId: friendshipId,
        status: status,
      );
}

/// Permintaan pertemanan yang masuk atau keluar.
class PermintaanTeman {
  const PermintaanTeman({
    required this.friendshipId,
    required this.pengguna,
    this.waktu,
  });

  final String friendshipId;
  final Teman pengguna;
  final DateTime? waktu;
}
