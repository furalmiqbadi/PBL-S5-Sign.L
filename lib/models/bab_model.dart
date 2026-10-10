enum BabStatus { locked, inProgress, completed, available }

class Bab {
  final int id;
  final String number;
  final String title;
  final String subtitle;
  final String description;
  final int totalMateri;
  final int completedMateri;
  final int durationMinutes;
  final BabStatus status;
  final double progress;
  final String? imageUrl;

  const Bab({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.totalMateri,
    required this.completedMateri,
    required this.durationMinutes,
    required this.status,
    required this.progress,
    this.imageUrl,
  });

  String get progressText => '$completedMateri dari $totalMateri pelajaran';
  String get durationText => '~$durationMinutes Menit';
  bool get isLocked => status == BabStatus.locked;
  bool get isInProgress => status == BabStatus.inProgress;
}

// Dummy data - nanti bisa dipindah ke service
final List<Bab> dummyBabList = [
  Bab(
    id: 1,
    number: '01',
    title: 'Pengenalan & Alfabet A - Z',
    subtitle: 'Bab 1 • Sedang Berjalan',
    description: 'Alfabet dasar, artikulasi bentuk jari,\ndan validasi visual AI gerakan tangan',
    totalMateri: 5,
    completedMateri: 3,
    durationMinutes: 25,
    status: BabStatus.inProgress,
    progress: 0.65,
  ),
  Bab(
    id: 2,
    number: '02',
    title: 'Angka & Berhitung (1 - 20)',
    subtitle: 'Bab 2 • Siap Dimulai',
    description: 'Sistem gestur angka 1 hingga 20,\norientasi telapak tangan, dan pola…',
    totalMateri: 4,
    completedMateri: 0,
    durationMinutes: 15,
    status: BabStatus.available,
    progress: 0.0,
  ),
  Bab(
    id: 3,
    number: '03',
    title: 'Sapaan Sehari-hari & Etika',
    subtitle: 'Terkunci • Prasyarat Bab 2',
    description: 'Salam, terima kasih, permohonan maaf,\nserta etika kesantunan visual dalam…',
    totalMateri: 4,
    completedMateri: 0,
    durationMinutes: 20,
    status: BabStatus.locked,
    progress: 0.0,
  ),
  Bab(
    id: 4,
    number: '04',
    title: 'Pengenalan Diri & Kata Benda\nUmum',
    subtitle: 'Terkunci • Prasyarat Bab 3',
    description: 'Menyatakan nama, domisili, profesi,\nserta kosa kata perabotan dan benda…',
    totalMateri: 5,
    completedMateri: 0,
    durationMinutes: 25,
    status: BabStatus.locked,
    progress: 0.0,
  ),
  Bab(
    id: 5,
    number: '05',
    title: 'Ungkapan Emosi & Tanya Jawab',
    subtitle: 'Terkunci • Prasyarat Bab 4',
    description: 'Ekspresi wajah (non-manual marker),\npartikel tanya 5W1H, dan percakapan…',
    totalMateri: 4,
    completedMateri: 0,
    durationMinutes: 20,
    status: BabStatus.locked,
    progress: 0.0,
  ),
];