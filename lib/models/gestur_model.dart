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

  double get progress => latihanKe / totalLatihan;
  String get progressPercent => '${(progress * 100).round()}%';
}

const String _folderFoto = 'assets/images/';
const String _ekstensiFoto = 'png';

// Isi hanya huruf yang nama filenya BEDA dari pola a.png, b.png, dst.
const Map<String, String> _fotoKhusus = {
  'F': 'assets/images/f.jpg',
  'G': 'assets/images/g.jpg',
  'H': 'assets/images/h.jpg',
  'I': 'assets/images/i.jpg',
  'J': 'assets/images/j.jpg',
};

const Map<int, List<String>> _hurufPerMateri = {
  1: ['A', 'B', 'C', 'D', 'E'],
  2: ['F', 'G', 'H', 'I', 'J'],
  3: ['K', 'L', 'M', 'N', 'O'],
  4: ['P', 'Q', 'R', 'S', 'T'],
  5: ['U', 'V', 'W', 'X', 'Y', 'Z'],
};

const Map<String, List<String>> _deskripsi = {
  'F': ['Satu tangan menunjuk ke bawah, tangan lain sebagai penopang'],
  'G': ['Satu tangan mengepal, tangan lain menopang dari bawah'],
  'H': ['Dua jari telunjuk & tengah diangkat sejajar ke atas'],
  'I': ['Satu tangan menunjuk ke atas'],
  'J': ['Telunjuk menunjuk, lalu digerakkan menuju arah tertentu'],
};

List<Gestur> gesturUntukMateri(int materiId) {
  final huruf = _hurufPerMateri[materiId] ?? const <String>[];
  return List.generate(huruf.length, (i) {
    final h = huruf[i];
    return Gestur(
      huruf: h,
      badgeLabel: 'BISINDO',
      latihanKe: i + 1,
      totalLatihan: huruf.length,
      xpReward: 15,
      assetPath: _fotoKhusus[h] ?? '$_folderFoto${h.toLowerCase()}.$_ekstensiFoto',
      deskripsiLangkah: _deskripsi[h] ?? ['TODO: deskripsi huruf $h.'],
    );
  });
}