/// Huruf alfabet BISINDO yang punya berkas gambar di `assets/images/`.
const List<String> hurufAlfabet = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J'
];

/// Seluruh kelas huruf yang bisa dipilih admin untuk satu bagian materi.
const List<String> hurufLatihan = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// Deskripsi bentuk tangan untuk huruf yang sudah terdokumentasi.
const Map<String, List<String>> _deskripsi = {
  'F': ['Satu tangan menunjuk ke bawah, tangan lain sebagai penopang'],
  'G': ['Satu tangan mengepal, tangan lain menopang dari bawah'],
  'H': ['Dua jari telunjuk & tengah diangkat sejajar ke atas'],
  'I': ['Satu tangan menunjuk ke atas'],
  'J': ['Telunjuk menunjuk, lalu digerakkan menuju arah tertentu'],
};

const String _deskripsiUmum =
    'Perhatikan gambar, lalu tirukan posisi jari dan telapak tangan sesuai contoh.';

/// Satu butir latihan huruf pada halaman isi materi.
class Gestur {
  final String huruf;
  final String badgeLabel;
  final List<String> deskripsiLangkah;
  final int latihanKe;
  final int totalLatihan;
  final int xpReward;
  final String assetPath;

  const Gestur({
    required this.huruf,
    required this.badgeLabel,
    required this.deskripsiLangkah,
    required this.latihanKe,
    required this.totalLatihan,
    required this.xpReward,
    required this.assetPath,
  });

  double get progress =>
      totalLatihan <= 0 ? 0 : (latihanKe / totalLatihan).clamp(0.0, 1.0);
  String get progressPercent => '${(progress * 100).round()}%';
}

/// Jalur gambar huruf berdasarkan berkas yang tersedia.
String gesturAssetPath(String huruf) =>
    'assets/images/kuis${huruf.toLowerCase()}.jpg';

/// Seluruh huruf alfabet sebagai daftar latihan.
List<Gestur> gesturAlfabet() {
  return List.generate(hurufAlfabet.length, (i) {
    final h = hurufAlfabet[i];
    return Gestur(
      huruf: h,
      badgeLabel: 'BISINDO',
      latihanKe: i + 1,
      totalLatihan: hurufAlfabet.length,
      xpReward: 15,
      assetPath: gesturAssetPath(h),
      deskripsiLangkah: _deskripsi[h] ?? const [_deskripsiUmum],
    );
  });
}

const List<String> _kataAlfabet = ['abjad', 'alfabet', 'alphabet'];

/// Daftar latihan huruf untuk satu materi. Materi non-alfabet hanya berisi
/// kuis, sehingga tidak punya latihan huruf.
List<Gestur> gesturUntukMateri(String judulMateri) {
  final lower = judulMateri.toLowerCase();
  final isAlphabet = _kataAlfabet.any(lower.contains);
  return isAlphabet ? gesturAlfabet() : const [];
}
