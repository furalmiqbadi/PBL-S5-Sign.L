import 'package:flutter/material.dart';

import '../models/bab_model.dart';
import '../services/materi_service.dart';

enum FilterType { all, inProgress, completed }

/// Controller tab Materi: daftar [Bab] nyata dari tabel `materi` Supabase.
class MateriController extends ChangeNotifier {
  MateriController({MateriService? service})
      : _service = service ?? MateriService();

  final MateriService _service;

  FilterType _currentFilter = FilterType.all;
  List<Bab> _babList = const [];
  bool _isLoading = true;
  String? _errorMessage;

  FilterType get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && !hasError && _babList.isEmpty;

  List<Bab> get filteredBabList => switch (_currentFilter) {
        FilterType.all => _babList,
        FilterType.inProgress => _babList.where((b) => b.isInProgress).toList(),
        FilterType.completed => _babList.where((b) => b.isCompleted).toList(),
      };

  /// Bab yang sedang berjalan, atau bab pertama yang bisa dibuka.
  Bab? get currentBab {
    for (final bab in _babList) {
      if (bab.isInProgress) return bab;
    }
    for (final bab in _babList) {
      if (!bab.isLocked) return bab;
    }
    return _babList.isEmpty ? null : _babList.first;
  }

  int get totalBab => _babList.length;
  int get completedBab => _babList.where((b) => b.isCompleted).length;

  Future<void> load({bool force = false}) async {
    if (!force && !_isLoading && _babList.isNotEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _babList = await _service.fetchBabList();
    } catch (e) {
      _babList = const [];
      _errorMessage =
          e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Membaca satu bab berdasarkan UUID materi (dipakai halaman detail).
  Future<Bab?> fetchBab(String materiId) => _service.fetchBabById(materiId);

  void setFilter(FilterType filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }
}
