import 'package:flutter/foundation.dart';

import '../models/friend_model.dart';
import '../services/friend_service.dart';

/// State pertemanan: daftar teman, permintaan masuk/keluar, saran,
/// dan status relasi per pengguna.
class FriendController extends ChangeNotifier {
  FriendController({FriendService? service})
      : _service = service ?? FriendService();

  final FriendService _service;

  bool isLoading = false;
  String? errorMessage;

  List<Teman> teman = const [];
  List<PermintaanTeman> permintaanMasuk = const [];
  List<PermintaanTeman> permintaanKeluar = const [];
  List<Teman> saran = const [];

  final Map<String, StatusTeman> _status = {};
  final Set<String> _memproses = {};
  bool _hasLoaded = false;

  int get jumlahPermintaan => permintaanMasuk.length;

  StatusTeman statusUntuk(String userId) =>
      _status[userId] ?? StatusTeman.tidakAda;

  bool sedangMemproses(String userId) => _memproses.contains(userId);

  Future<void> load({bool force = false}) async {
    if (_hasLoaded && !force) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final hasil = await Future.wait([
        _service.daftarTeman(),
        _service.daftarPermintaanMasuk(),
        _service.daftarPermintaanKeluar(),
      ]);
      teman = hasil[0] as List<Teman>;
      permintaanMasuk = hasil[1] as List<PermintaanTeman>;
      permintaanKeluar = hasil[2] as List<PermintaanTeman>;
      _hasLoaded = true;
      _segarkanPeta();
    } catch (e) {
      errorMessage =
          e is Exception ? '$e'.replaceFirst('Exception: ', '') : null;
      errorMessage ??= 'Gagal memuat data teman. Silakan coba lagi.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSaran({int batas = 10}) async {
    try {
      saran = await _service.saranTeman(batas: batas);
      notifyListeners();
    } catch (e) {
      debugPrint('[Teman] Saran gagal dimuat: $e');
    }
  }

  /// Muat status relasi untuk daftar pengguna (mis. hasil pencarian).
  Future<void> muatStatus(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final hasil = await _service.statusBanyak(userIds);
    _status.addAll(hasil);
    notifyListeners();
  }

  Future<bool> tambahTeman(String userId) => _aksi(
        userId,
        () => _service.kirimPermintaan(userId),
        StatusTeman.menungguMereka,
      );

  Future<bool> terimaPermintaan(Teman pengguna) => _aksi(
        pengguna.id,
        () => _service.terimaPermintaan(pengguna.friendshipId!),
        StatusTeman.berteman,
      );

  Future<bool> tolakPermintaan(Teman pengguna) => _aksi(
        pengguna.id,
        () => _service.tolakPermintaan(pengguna.friendshipId!),
        StatusTeman.ditolak,
      );

  Future<bool> ikutiBalik(String userId) => _aksi(
        userId,
        () => _service.ikutiBalik(userId),
        StatusTeman.berteman,
      );

  Future<bool> batalkan(String userId) => _aksi(
        userId,
        () {
          final id = _relasiId(userId);
          if (id == null) return Future.value();
          return _service.batalkanPermintaan(id);
        },
        StatusTeman.tidakAda,
      );

  Future<bool> hapusTeman(String userId) => _aksi(
        userId,
        () {
          final id = _relasiId(userId);
          if (id == null) return Future.value();
          return _service.hapusTeman(id);
        },
        StatusTeman.tidakAda,
        hapusDariDaftar: true,
      );

  Future<bool> _aksi(
    String userId,
    Future<void> Function() jalankan,
    StatusTeman hasil, {
    bool hapusDariDaftar = false,
  }) async {
    if (_memproses.contains(userId)) return false;
    _memproses.add(userId);
    notifyListeners();

    try {
      await jalankan();
      _status[userId] = hasil;
      teman = teman
          .map((t) => t.id == userId ? t.copyWith(status: hasil) : t)
          .where((t) => !hapusDariDaftar || t.id != userId)
          .toList();
      permintaanMasuk =
          permintaanMasuk.where((p) => p.pengguna.id != userId).toList();
      permintaanKeluar =
          permintaanKeluar.where((p) => p.pengguna.id != userId).toList();
      return true;
    } catch (e) {
      errorMessage = '$e'.replaceFirst('Exception: ', '');
      return false;
    } finally {
      _memproses.remove(userId);
      notifyListeners();
    }
  }

  String? _relasiId(String userId) {
    for (final t in teman) {
      if (t.id == userId) return t.friendshipId;
    }
    for (final p in permintaanKeluar) {
      if (p.pengguna.id == userId) return p.friendshipId;
    }
    for (final p in permintaanMasuk) {
      if (p.pengguna.id == userId) return p.friendshipId;
    }
    return null;
  }

  void _segarkanPeta() {
    _status.clear();
    for (final t in teman) {
      _status[t.id] = StatusTeman.berteman;
    }
    for (final p in permintaanMasuk) {
      _status[p.pengguna.id] = StatusTeman.menungguKita;
    }
    for (final p in permintaanKeluar) {
      _status[p.pengguna.id] = StatusTeman.menungguMereka;
    }
  }

  /// Dipakai setelah memulai percakapan agar daftar tetap segar.
  void tandaiSudahMuat() {
    _hasLoaded = false;
  }
}
