import 'package:flutter/material.dart';
import '../models/gestur_model.dart';

class IsiMateriController extends ChangeNotifier {
  IsiMateriController({required this.daftarGestur, int startIndex = 0})
      : _index = startIndex.clamp(0, daftarGestur.length - 1).toInt();

  final List<Gestur> daftarGestur;
  int _index;

  Gestur get gestur => daftarGestur[_index];
  bool get isFirst => _index == 0;
  bool get isLast => _index == daftarGestur.length - 1;

  VoidCallback? onBack;
  VoidCallback? onOpenCamera;
  VoidCallback? onFinished;

  void goBack() => onBack?.call();
  void openCamera() => onOpenCamera?.call();

  void nextGestur() {
    if (isLast) {
      onFinished?.call();
      return;
    }
    _index++;
    notifyListeners();
  }

  void previousGestur() {
    if (isFirst) return;
    _index--;
    notifyListeners();
  }
}