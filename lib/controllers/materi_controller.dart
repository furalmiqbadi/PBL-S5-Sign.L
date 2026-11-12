import 'package:flutter/material.dart';
import '../models/bab_model.dart';
import '../services/materi_service.dart';

enum FilterType { all, inProgress, completed }

class MateriController extends ChangeNotifier {
  final MateriService _service;
  FilterType _currentFilter = FilterType.all;
  List<Bab> _babList = dummyBabList;
  bool _isLoading = false;

  MateriController({MateriService? service})
      : _service = service ?? MateriService() {
    loadBabList();
  }

  bool get isLoading => _isLoading;

  Future<void> loadBabList() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _service.getBabList();
      if (list.isNotEmpty) {
        _babList = list;
      }
    } catch (e) {
      debugPrint('[MateriController] Gagal memuat bab: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  FilterType get currentFilter => _currentFilter;
  List<Bab> get filteredBabList {
    switch (_currentFilter) {
      case FilterType.all:
        return _babList;
      case FilterType.inProgress:
        return _babList.where((b) => b.isInProgress).toList();
      case FilterType.completed:
        return _babList.where((b) => b.status == BabStatus.completed).toList();
    }
  }

  // Data untuk header
  Bab? get currentBab => _babList.firstWhere(
        (b) => b.isInProgress,
        orElse: () => _babList.first,
      );

  int get totalBab => _babList.length;
  int get completedBab => _babList.where((b) => b.status == BabStatus.completed).length;

  void setFilter(FilterType filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void continueLearning(int babId) {
    // TODO: Navigate to detail bab
    debugPrint('Continue Bab $babId');
  }

  void startBab(int babId) {
    // TODO: Start bab
    debugPrint('Start Bab $babId');
  }
}