import 'package:intl/intl.dart';

const List<String> _weekdaysId = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Format jam:menit, mis. `10.42`.
String clockTime(DateTime time) => DateFormat('HH.mm').format(time);

/// Label waktu untuk daftar percakapan (Chat List).
///
/// - Hari ini  → `10.42`
/// - Kemarin   → `Kemarin`
/// - < 7 hari  → nama hari (mis. `Rabu`)
/// - Lainnya   → `dd/MM/yy`
String chatListTime(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(time.year, time.month, time.day);
  final diffDays = today.difference(date).inDays;

  if (diffDays <= 0) return clockTime(time);
  if (diffDays == 1) return 'Kemarin';
  if (diffDays < 7) return _weekdaysId[time.weekday - 1];
  return DateFormat('dd/MM/yy').format(time);
}

/// Label waktu untuk notifikasi.
///
/// Hari ini → waktu relatif (`10 menit lalu`), selainnya → `HH.mm`.
String notificationTime(DateTime time) {
  final now = DateTime.now();
  if (isSameDay(time, now)) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    return '${diff.inHours} jam lalu';
  }
  return clockTime(time);
}
