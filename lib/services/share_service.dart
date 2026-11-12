/// Penampung sementara konten yang akan dibagikan ke tab Komunitas.
///
/// Dipakai saat pengguna membagikan hasil kuis/pencapaian: konten disimpan
/// di sini, lalu [KomunitasPage] mengambilnya ketika tab dibuka.
class ShareService {
  static String? _pendingCommunityPost;

  static void queueCommunityPost(String text) {
    _pendingCommunityPost = text;
  }

  static String? takeCommunityPost() {
    final post = _pendingCommunityPost;
    _pendingCommunityPost = null;
    return post;
  }
}
