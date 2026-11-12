import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String defaultAvatarUrl = 'https://i.pravatar.cc/150?img=47';

/// Helper untuk menghasilkan ImageProvider yang fleksibel dan aman di Web maupun Mobile:
/// - Mendukung raw byte memory (Uint8List)
/// - Mendukung URL internet (http/https) serta blob (Flutter Web)
/// - Mendukung Data URI Base64 (data:image/...;base64,...)
/// - Mendukung file lokal perangkat (hanya non-web)
/// - Fallback ke foto default jika kosong/gagal
ImageProvider getAvatarImageProvider(
  String? pathOrUrl, {
  Uint8List? bytes,
  String fallback = defaultAvatarUrl,
}) {
  // 0. Jika ada raw bytes dari hasil image picker, langsung tampilkan
  if (bytes != null && bytes.isNotEmpty) {
    return MemoryImage(bytes);
  }

  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) {
    return NetworkImage(fallback);
  }

  final trimmed = pathOrUrl.trim();

  // 1. Data URI Base64
  if (trimmed.startsWith('data:')) {
    try {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        final base64String = trimmed.substring(commaIndex + 1);
        final decodedBytes = base64Decode(base64String);
        return MemoryImage(decodedBytes);
      }
    } catch (e) {
      debugPrint('[AvatarHelper] Gagal decode base64 avatar: $e');
    }
  }

  // 2. URL HTTP / HTTPS / BLOB (Web)
  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('blob:')) {
    return NetworkImage(trimmed);
  }

  // 3. File Lokal Perangkat (Non-Web)
  if (!kIsWeb) {
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
  }

  // Fallback
  return NetworkImage(fallback);
}
