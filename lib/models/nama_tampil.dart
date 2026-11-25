/// Aturan nama tampil tunggal untuk seluruh konten (kiriman, komentar,
/// percakapan, notifikasi): `full_name` -> `username` -> label netral.
///
/// Label "Pengguna" polos tidak dipakai selama pengguna punya username.
library;

const String labelNamaNetral = 'Anggota Komunitas';

String _teks(Object? nilai) => (nilai as String?)?.trim() ?? '';

/// Nama tampil dari sebuah baris profil (`full_name`, `username`).
String namaTampilDari(
  Map<String, dynamic>? profil, {
  String fallback = labelNamaNetral,
}) {
  if (profil == null) return fallback;
  final nama = _teks(profil['full_name']);
  if (nama.isNotEmpty) return nama;
  final username = _teks(profil['username']);
  if (username.isNotEmpty) return username;
  return fallback;
}

/// `@username` untuk badge, atau string kosong bila tidak tersedia.
String usernameTampilDari(Map<String, dynamic>? profil) =>
    _teks(profil?['username']);

/// Label peran Indonesia dari kolom `role`.
String labelPeran(String? role) => switch (_teks(role)) {
      'admin' => 'Admin',
      'mentor' => 'Mentor Tuli',
      _ => 'Pembelajar',
    };
