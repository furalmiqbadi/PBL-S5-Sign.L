import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_vision/mediapipe_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Model deteksi belum bisa dipakai (berkas `assets/ml/model.tflite` kosong,
/// rusak, atau belum diganti dengan model hasil training).
class ModelTidakTersedia implements Exception {
  final String pesan;
  const ModelTidakTersedia(this.pesan);

  @override
  String toString() => pesan;
}

/// Hasil satu kali deteksi isyarat tangan.
class HasilDeteksi {
  final String huruf;
  final double keyakinan;

  const HasilDeteksi({required this.huruf, required this.keyakinan});

  int get persen => (keyakinan * 100).round();
}

/// Inferensi model gestur huruf BISINDO.
///
/// Model dilatih atas 126 fitur landmark (2 tangan x 21 titik x 3 koordinat),
/// bukan atas piksel. Karena itu pipeline-nya: foto -> MediaPipe HandLandmarker
/// -> normalisasi fitur -> TFLite. Aturan normalisasi mengikuti `mlwebtest/app.py`:
/// tangan diurutkan dari pergelangan paling kiri, origin = rata-rata pergelangan,
/// scale = rata-rata jarak titik 0-9, tangan kosong diisi nol.
class MlService {
  MlService._();

  static final MlService instance = MlService._();

  static const String _pathModel = 'assets/ml/model.tflite';
  static const String _pathLabel = 'assets/ml/labels.txt';
  static const int _jumlahTitik = 21;
  static const int _fiturPerTangan = _jumlahTitik * 3;
  static const int _ukuranFitur = _fiturPerTangan * 2;

  Interpreter? _interpreter;
  HandLandmarker? _landmarker;
  List<String> _label = const [];
  String? _pesanGagal;
  Future<bool>? _memuat;

  bool get siap => _interpreter != null && _landmarker != null;
  String? get pesanGagal => _pesanGagal;

  /// Memuat model, label, dan HandLandmarker. Aman dipanggil berulang.
  Future<bool> siapkan() {
    if (siap) return Future.value(true);
    if (_pesanGagal != null) return Future.value(false);
    return _memuat ??= _muat();
  }

  Future<bool> _muat() async {
    try {
      final label = await rootBundle.loadString(_pathLabel);
      _label = label
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _interpreter = await Interpreter.fromAsset(_pathModel);
      _landmarker = await HandLandmarker.create(
        HandLandmarkerOptions(
          model: VisionModels.handLandmarker,
          numHands: 2,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[ML] Model tidak bisa dimuat: $e');
      _pesanGagal =
          'Model deteksi belum tersedia. Minta berkas model.tflite hasil '
          'training terbaru ke ML Engineer.';
      _interpreter?.close();
      _interpreter = null;
      return false;
    } finally {
      _memuat = null;
    }
  }

  /// Menjalankan inferensi pada foto kamera dan mengembalikan huruf paling
  /// mirip beserta tingkat keyakinan.
  Future<HasilDeteksi> deteksi(
    String pathFoto, {
    required String target,
  }) async {
    final interpreter = _interpreter;
    final landmarker = _landmarker;
    if (interpreter == null || landmarker == null) {
      throw ModelTidakTersedia(
        _pesanGagal ?? 'Model deteksi belum siap. Jalankan ulang halaman ini.',
      );
    }

    final tensorMasukan = interpreter.getInputTensor(0);
    final bentukMasukan = tensorMasukan.shape;
    if (bentukMasukan.length != 2 || bentukMasukan[1] != _ukuranFitur) {
      throw const ModelTidakTersedia(
        'Bentuk masukan model tidak didukung (harus [1, 126]).',
      );
    }

    final hasil = await landmarker.detect(VisionImage.fromFile(pathFoto));
    final fitur = _hitungFitur(hasil);
    if (fitur == null) {
      throw const ModelTidakTersedia(
        'Tangan tidak terdeteksi. Posisikan tangan di tengah bingkai, '
        'pastikan cahaya cukup, lalu coba lagi.',
      );
    }

    final tensorKeluaran = interpreter.getOutputTensor(0);
    final bentuk = tensorKeluaran.shape;
    if (bentuk.length != 2) {
      throw const ModelTidakTersedia(
        'Model ini bukan klasifikasi huruf. Ekspor ulang model klasifikasi '
        'dengan keluaran [1, jumlah kelas].',
      );
    }
    if (bentuk[1] != _label.length) {
      throw const ModelTidakTersedia(
        'Jumlah kelas model tidak sama dengan daftar label.',
      );
    }

    final keluaran = List.generate(1, (_) => List.filled(bentuk[1], 0.0));
    interpreter.run([fitur], keluaran);

    final mentah =
        (keluaran.first as List).cast<num>().map((e) => e.toDouble()).toList();
    final peluang = _peluang(mentah);
    var terbaik = 0;
    for (var i = 1; i < peluang.length; i++) {
      if (peluang[i] > peluang[terbaik]) terbaik = i;
    }

    final huruf = _label[terbaik].isNotEmpty
        ? _label[terbaik].toUpperCase()
        : target.toUpperCase();

    return HasilDeteksi(huruf: huruf, keyakinan: peluang[terbaik]);
  }

  /// Porting `hitung_fitur` dari `mlwebtest/app.py`.
  List<double>? _hitungFitur(HandLandmarkerResult hasil) {
    final lebar = hasil.imageWidth.toDouble();
    final tinggi = hasil.imageHeight.toDouble();
    if (lebar <= 0 || tinggi <= 0 || hasil.handLandmarks.isEmpty) return null;

    final tangan = hasil.handLandmarks
        .map(
          (landmarks) => landmarks
              .map((lm) => [lm.x * lebar, lm.y * tinggi, lm.z * lebar])
              .toList(),
        )
        .toList()
      ..sort((a, b) => a[0][0].compareTo(b[0][0]));

    final origin = List<double>.filled(3, 0);
    for (final pts in tangan) {
      for (var k = 0; k < 3; k++) {
        origin[k] += pts[0][k];
      }
    }
    for (var k = 0; k < 3; k++) {
      origin[k] /= tangan.length;
    }

    var totalJarak = 0.0;
    for (final pts in tangan) {
      totalJarak += math.sqrt(
        math.pow(pts[9][0] - pts[0][0], 2) + math.pow(pts[9][1] - pts[0][1], 2),
      );
    }
    final skala = totalJarak / tangan.length;
    if (skala < 1e-6) return null;

    final fitur = <double>[];
    for (final pts in tangan.take(2)) {
      for (final titik in pts) {
        for (var k = 0; k < 3; k++) {
          fitur.add((titik[k] - origin[k]) / skala);
        }
      }
    }
    fitur.addAll(List<double>.filled(_ukuranFitur - fitur.length, 0));
    return fitur.length > _ukuranFitur ? fitur.sublist(0, _ukuranFitur) : fitur;
  }

  /// Keluaran model sudah berupa peluang (softmax di dalam grafik). Bila
  /// totalnya masih berupa skor, normalkan seperti `mlwebtest/app.py`.
  List<double> _peluang(List<double> skor) {
    if (skor.isEmpty) return const [];
    final total = skor.fold<double>(0, (a, b) => a + b);
    if (total > 0 && (total - 1).abs() > 0.05) {
      return skor.map((e) => e / total).toList();
    }
    if (total <= 0) return _softmax(skor);
    return skor;
  }

  List<double> _softmax(List<double> skor) {
    final maks = skor.reduce(math.max);
    final eksp = skor.map((e) => math.exp(e - maks)).toList();
    final total = eksp.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return List.filled(skor.length, 0.0);
    return eksp.map((e) => e / total).toList();
  }

  /// Melepas model dari memori.
  Future<void> tutup() async {
    _interpreter?.close();
    _interpreter = null;
    final landmarker = _landmarker;
    _landmarker = null;
    await landmarker?.dispose();
  }
}
