import 'package:flutter/material.dart';
import '../models/materi_model.dart';
import '../services/materi_service.dart';

class DetailMateriController extends ChangeNotifier {
  final MateriService _service;
  List<Materi> _materiList = dummyMateriList;
  bool _isLoading = false;

  DetailMateriController({MateriService? service})
      : _service = service ?? MateriService() {
    loadMateriList();
  }

  bool get isLoading => _isLoading;

  Future<void> loadMateriList() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _service.getDetailMateriList();
      if (list.isNotEmpty) {
        _materiList = list;
      }
    } catch (e) {
      debugPrint('[DetailMateriController] Gagal memuat materi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get completedMateri =>
      _materiList.where((m) => m.status == MateriStatus.completed).length;
  int get totalMateri => _materiList.length;
  double get totalProgress =>
      totalMateri > 0 ? (completedMateri / totalMateri) : 0.42;

  List<Materi> get materiList => _materiList;

  void continueLearning(int materiId) {
    debugPrint('Continue materi $materiId');
    // TODO: Navigate to camera or learning page
  }

  void startQuiz() {
    debugPrint('Start Quiz');
  }

  void openCameraAI() {
    debugPrint('Open Camera AI');
  }
}