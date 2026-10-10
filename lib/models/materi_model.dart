enum MateriStatus { locked, inProgress, completed, available }

class Materi {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final int totalGestures;
  final int completedGestures;
  final int xpReward;
  final MateriStatus status;
  final double progress;
  final bool isQuiz;
  final bool isCameraPractice;
  final bool isFinalExam;

  const Materi({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.totalGestures,
    required this.completedGestures,
    required this.xpReward,
    required this.status,
    required this.progress,
    this.isQuiz = false,
    this.isCameraPractice = false,
    this.isFinalExam = false,
  });

  bool get isLocked => status == MateriStatus.locked;
  bool get isInProgress => status == MateriStatus.inProgress;
  String get progressText => '$completedGestures dari $totalGestures Selesai';
}

// Dummy data untuk Section A (Ejaan Alfabet)
final List<Materi> dummyMateriList = [
  Materi(
    id: 1,
    title: 'Huruf A - E: Bentuk Dasar Tangan',
    subtitle: '5 Gestur selesai • Akurasi gestur 98%',
    description: '5 Gestur selesai • Akurasi gestur 98%',
    totalGestures: 5,
    completedGestures: 5,
    xpReward: 50,
    status: MateriStatus.completed,
    progress: 1.0,
  ),
  Materi(
    id: 2,
    title: 'Huruf F - J: Orientasi & Gerak',
    subtitle: 'Transisi kelenturan jari telunjuk & jempol presisi tinggi.',
    description: 'Transisi kelenturan jari telunjuk & jempol presisi tinggi.',
    totalGestures: 5,
    completedGestures: 3,
    xpReward: 50,
    status: MateriStatus.inProgress,
    progress: 0.6,
  ),
  Materi(
    id: 3,
    title: 'Huruf K - O: Variasi Posisi Jari',
    subtitle: '5 Gerakan baru • Belum dimulai',
    description: '5 Gerakan baru • Belum dimulai',
    totalGestures: 5,
    completedGestures: 0,
    xpReward: 50,
    status: MateriStatus.locked,
    progress: 0.0,
  ),
  Materi(
    id: 4,
    title: 'Huruf P - T: Kombinasi Gestur Kompleks',
    subtitle: '5 Gerakan • Belum dimulai',
    description: '5 Gerakan • Belum dimulai',
    totalGestures: 5,
    completedGestures: 0,
    xpReward: 50,
    status: MateriStatus.locked,
    progress: 0.0,
  ),
  Materi(
    id: 5,
    title: 'Huruf U - Z: Penutup Alfabet',
    subtitle: '6 Gerakan • Penutup rangkaian alfabet',
    description: '6 Gerakan • Penutup rangkaian alfabet',
    totalGestures: 6,
    completedGestures: 0,
    xpReward: 60,
    status: MateriStatus.locked,
    progress: 0.0,
  ),
];