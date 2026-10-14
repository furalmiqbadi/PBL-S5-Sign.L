import 'package:flutter/material.dart';
import '../models/bab_model.dart';

enum FilterType { all, inProgress, completed }

class MateriController extends ChangeNotifier {
  FilterType _currentFilter = FilterType.all;
  List<Bab> _babList = dummyBabList;

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