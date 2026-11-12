import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Mengubah foto menjadi WebP agar ukuran file lebih ringan
/// (umumnya 25-35% lebih kecil daripada JPEG dengan kualitas sama).
class ImageCompressService {
  /// Mengembalikan path file WebP hasil kompresi.
  /// Bila gagal, path asli dikembalikan supaya unggahan tetap berjalan.
  static Future<String> toWebP(
    String inputPath, {
    int maxWidth = 1280,
    int quality = 70,
  }) async {
    // Plugin ini hanya untuk Android/iOS. Di web, image_picker sudah
    // melakukan resize sehingga file asli dipakai langsung.
    if (kIsWeb) return inputPath;

    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/img_${DateTime.now().microsecondsSinceEpoch}.webp';

      final result = await FlutterImageCompress.compressAndGetFile(
        inputPath,
        target,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
      );

      return result?.path ?? inputPath;
    } catch (e) {
      debugPrint('[ImageCompress] Gagal konversi WebP: $e');
      return inputPath;
    }
  }
}
