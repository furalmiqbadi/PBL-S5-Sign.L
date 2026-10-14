import 'package:flutter/material.dart';
import '../models/materi_model.dart';

class DetailMateriController extends ChangeNotifier {
  final List<Materi> _materiList = dummyMateriList;
  
  int get completedMateri => _materiList.where((m) => m.status == MateriStatus.completed).length;
  int get totalMateri => _materiList.length;
  double get totalProgress => 0.42; // 42% dari header
  
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