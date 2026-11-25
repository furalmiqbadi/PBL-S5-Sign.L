import 'package:flutter/foundation.dart';

/// Penampung sementara konten yang akan dibagikan ke tab Komunitas.
///
/// Dipakai saat pengguna membagikan hasil kuis/pencapaian: konten disimpan
/// di sini, lalu [KomunitasPage] mengambilnya ketika tab dibuka.
class ShareService {
  static String? _pendingCommunityPost;
  static String? _pendingMediaUrl;

  /// Dinaikkan setiap ada konten baru, agar tab Komunitas yang sudah terbuka
  /// (di-keep-alive) langsung mengirim tanpa menunggu dimuat ulang.
  static final ValueNotifier<int> perubahan = ValueNotifier<int>(0);

  /// Menyimpan teks postingan; [mediaUrl] opsional (mis. banner kuis).
  static void queueCommunityPost(String text, {String? mediaUrl}) {
    _pendingCommunityPost = text;
    _pendingMediaUrl = mediaUrl;
    perubahan.value++;
  }

  static String? takeCommunityPost() {
    final post = _pendingCommunityPost;
    _pendingCommunityPost = null;
    return post;
  }

  /// URL media yang menyertai postingan tertunda, bila ada.
  static String? takeCommunityMediaUrl() {
    final url = _pendingMediaUrl;
    _pendingMediaUrl = null;
    return url;
  }
}
