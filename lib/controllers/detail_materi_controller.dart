import 'package:flutter/foundation.dart';

import '../models/bab_model.dart';
import '../services/kuis_service.dart';
import '../services/materi_service.dart';

/// Controller halaman detail materi: satu [Bab] beserta bagian materi dan
/// kuis miliknya.
///
/// Sumber data: tabel `materi` (lewat [MateriService]) dan `kuis`
/// (lewat [KuisService]). Tidak ada data dummy.
class DetailMateriController extends ChangeNotifier {
  DetailMateriController({
    String? materiId,
    MateriService? materiService,
    KuisService? kuisService,
  })  : _materiId = materiId,
        _materiService = materiService ?? MateriService(),
        _kuisService = kuisService ?? KuisService();

  final String? _materiId;
  final MateriService _materiService;
  final KuisService _kuisService;

  Bab? _bab;
  List<KuisInfo> _kuis = const [];
  List<MateriBagian> _bagian = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  Bab? get bab => _bab;
  List<KuisInfo> get kuis => _kuis;
  List<MateriBagian> get bagian => _bagian;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get kuisSelesai => _kuis.where((k) => k.sudahDikerjakan).length;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Halaman bisa ditutup saat [load] masih berjalan.
  void _beritahu() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (!force && !_isLoading && _bab != null) return;
    _isLoading = true;
    _errorMessage = null;
    _beritahu();

    try {
      final bab = await _muatBab();
      if (bab == null) {
        _bab = null;
        _kuis = const [];
        _bagian = const [];
        _errorMessage = 'Materi tidak ditemukan di server.';
        return;
      }
      // Kuis dan bagian materi tidak saling bergantung, jadi dimuat paralel.
      final daftarKuisFuture = _kuisService.fetchDaftarKuis();
      final bagianFuture = _materiService.fetchBagian(bab.id);
      final daftarKuis = await daftarKuisFuture;
      final bagian = await bagianFuture;
      _bab = bab;
      _kuis = daftarKuis.where((k) => k.materiId == bab.id).toList();
      _bagian = bagian;
    } catch (e) {
      _bab = null;
      _kuis = const [];
      _bagian = const [];
      _errorMessage =
          e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
    } finally {
      _isLoading = false;
      _beritahu();
    }
  }

  Future<Bab?> _muatBab() async {
    final id = _materiId;
    if (id != null) {
      final bab = await _materiService.fetchBabById(id);
      if (bab != null) return bab;
    }
    final daftar = await _materiService.fetchBabList();
    if (daftar.isEmpty) return null;
    for (final bab in daftar) {
      if (bab.isInProgress) return bab;
    }
    for (final bab in daftar) {
      if (!bab.isLocked) return bab;
    }
    return daftar.first;
  }
}
