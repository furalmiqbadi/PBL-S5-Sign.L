import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../chat/chat_list_view.dart';
import '../../models/nama_tampil.dart';
import '../../services/image_compress_service.dart';
import '../../services/post_service.dart';
import '../../services/share_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/user_avatar.dart';
import '../widgets/app_bottom_nav_bar.dart';

class PostModel {
  final String id;
  final String authorId;
  final String userName;
  final String userRole;
  final Color roleColor;
  final Color roleTextColor;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String categoryText;
  final String content;
  final String? mediaUrl;
  final bool mediaIsVideo;
  int likes;
  final String likeLabel;
  int comments;
  bool isLiked;
  bool isSaved;

  PostModel({
    required this.id,
    this.authorId = '',
    required this.userName,
    required this.userRole,
    required this.roleColor,
    required this.roleTextColor,
    this.avatarUrl,
    this.createdAt,
    required this.categoryText,
    required this.content,
    this.mediaUrl,
    this.mediaIsVideo = false,
    required this.likes,
    this.likeLabel = 'Bantu',
    required this.comments,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory PostModel.fromRow(Map<String, dynamic> row) {
    final role = '${row['author_role'] ?? 'pembelajar'}';
    final mediaUrl = row['media_url'] as String?;
    final url = (mediaUrl == null || mediaUrl.isEmpty) ? null : mediaUrl;
    return PostModel(
      id: '${row['id']}',
      authorId: '${row['user_id'] ?? ''}',
      userName: namaTampilDari({
        'full_name': row['author_name'],
        'username': row['author_username'],
      }),
      userRole: switch (role) {
        'admin' => 'Admin',
        'mentor' => 'Mentor Tuli',
        _ => 'Pembelajar',
      },
      roleColor: switch (role) {
        'admin' => AppColors.pinkSoft,
        'mentor' => AppColors.purpleSoft,
        _ => AppColors.fieldFill,
      },
      roleTextColor: switch (role) {
        'admin' => AppColors.primary,
        'mentor' => AppColors.secondary,
        _ => AppColors.textSecondary,
      },
      avatarUrl: row['author_avatar'] as String?,
      createdAt: DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal(),
      categoryText: '${row['kategori'] ?? 'Tanya Isyarat'}',
      content: '${row['konten'] ?? ''}',
      mediaUrl: url,
      mediaIsVideo: (url?.contains('/video_') ?? false) ||
          (url?.contains('.mp4') ?? false) ||
          (url?.contains('.mov') ?? false),
      likes: (row['like_count'] as num?)?.toInt() ?? 0,
      comments: (row['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: row['is_liked'] == true,
    );
  }
}

class _VideoPlayerBox extends StatefulWidget {
  final String path;

  const _VideoPlayerBox({required this.path});

  @override
  State<_VideoPlayerBox> createState() => _VideoPlayerBoxState();
}

/// Pemutar video untuk media kiriman yang tersimpan di Storage.
class _NetworkVideoBox extends _VideoPlayerBox {
  const _NetworkVideoBox({required super.path});

  @override
  State<_VideoPlayerBox> createState() => _NetworkVideoBoxState();
}

class _NetworkVideoBoxState extends _VideoPlayerBoxState {
  @override
  VideoPlayerController _buatController(String path) =>
      VideoPlayerController.networkUrl(Uri.parse(path));
}

class _VideoPlayerBoxState extends State<_VideoPlayerBox> {
  static const double _tinggi = 220;

  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  VideoPlayerController _buatController(String path) =>
      VideoPlayerController.file(File(path));

  @override
  void initState() {
    super.initState();
    _controller = _buatController(widget.path);
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: _tinggi,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: AppColors.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('Video tidak bisa diputar',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: _tinggi,
        width: double.infinity,
        color: Colors.black,
        child: !_ready
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : GestureDetector(
                onTap: _togglePlay,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    if (!_controller.value.isPlaying)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primary,
                          backgroundColor: Colors.white24,
                          bufferedColor: Colors.white38,
                        ),
                        padding: const EdgeInsets.only(top: 8),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN UTAMA
// ─────────────────────────────────────────────────────────────────────────────

class KomunitasPage extends StatefulWidget {
  const KomunitasPage({super.key});

  @override
  State<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends State<KomunitasPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Semua',
    'Tanya Isyarat',
    'Tips & Trik',
    'Cerita Sukses',
    'Temu Belajar',
  ];

  final PostService _postService = PostService();

  List<PostModel> _posts = [];
  bool _loading = true;
  String? _error;

  /// Hasil filter disimpan agar tidak dihitung ulang setiap build.
  List<PostModel>? _filteredCache;

  @override
  void initState() {
    super.initState();
    ShareService.perubahan.addListener(_kirimPostinganTertunda);
    _muatPostingan();
  }

  /// Memuat kiriman komunitas dari Supabase.
  Future<void> _muatPostingan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _postService.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts = rows.map(PostModel.fromRow).toList();
        _filteredCache = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Gagal memuat komunitas.';
      });
    }
    _kirimPostinganTertunda();
  }

  /// Mengirim pencapaian yang dibagikan dari halaman lain.
  Future<void> _kirimPostinganTertunda() async {
    if (!mounted) return;
    final shared = ShareService.takeCommunityPost();
    final mediaUrl = ShareService.takeCommunityMediaUrl();
    if (shared == null) return;
    try {
      await _postService.buatPostingan(
        konten: shared,
        kategori: 'Cerita Sukses',
        mediaUrl: mediaUrl,
      );
      await _muatPostingan();
    } catch (e) {
      if (!mounted) return;
      _showStyledSnackBar(
        e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Gagal membagikan pencapaian.',
        icon: Icons.error_outline,
      );
    }
  }

  @override
  void dispose() {
    ShareService.perubahan.removeListener(_kirimPostinganTertunda);
    _searchController.dispose();
    super.dispose();
  }

  List<PostModel> get _filteredPosts {
    final cached = _filteredCache;
    if (cached != null) return cached;
    final query = _searchQuery.toLowerCase();
    final category = _selectedCategory.toLowerCase();
    final hasil = _posts.where((post) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          post.categoryText.toLowerCase() == category;
      final matchesSearch = query.isEmpty ||
          post.content.toLowerCase().contains(query) ||
          post.userName.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList(growable: false);
    _filteredCache = hasil;
    return hasil;
  }

  Future<void> _toggleLike(PostModel post) async {
    final sebelumnyaLiked = post.isLiked;
    final sebelumnyaLikes = post.likes;
    setState(() {
      post.isLiked = !post.isLiked;
      post.isLiked ? post.likes++ : post.likes--;
    });
    try {
      final liked = await _postService.toggleLike(post.id, sebelumnyaLiked);
      if (!mounted || liked == post.isLiked) return;
      setState(() {
        post.isLiked = liked;
        post.likes = sebelumnyaLikes + (liked ? 1 : -1);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        post.isLiked = sebelumnyaLiked;
        post.likes = sebelumnyaLikes;
      });
      _showStyledSnackBar(
        e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Gagal menyimpan suka.',
        icon: Icons.error_outline,
      );
    }
  }

  void _toggleBookmark(PostModel post) {
    setState(() {
      post.isSaved = !post.isSaved;
    });
    _showStyledSnackBar(
      post.isSaved ? 'Postingan disimpan' : 'Batal menyimpan postingan',
      icon: post.isSaved
          ? Icons.bookmark_added_rounded
          : Icons.bookmark_remove_outlined,
    );
  }

  void _showStyledSnackBar(String message, {IconData? icon}) {
    showAppSnackBar(
      context,
      message,
      type: icon == Icons.error_outline
          ? AppSnackType.error
          : (icon == Icons.warning_amber_rounded || icon == Icons.flag_rounded
              ? AppSnackType.warning
              : (icon == Icons.check_circle_rounded
                  ? AppSnackType.success
                  : AppSnackType.info)),
      duration: const Duration(seconds: 2),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  // ─────────────────────── BOTTOM SHEET: BUAT POSTINGAN ────────────────────
  void _showCreatePostSheet() {
    final textController = TextEditingController();
    String selectedCat = 'Tanya Isyarat';
    String? pickedPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickFoto(ImageSource source) async {
              try {
                final XFile? file = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                  maxWidth: 1280,
                  maxHeight: 1280,
                );
                if (file == null) return;
                final path = await ImageCompressService.toWebP(file.path);
                if (!mounted) return;
                setModalState(() => pickedPath = path);
              } catch (e) {
                if (!mounted) return;
                _showStyledSnackBar('Gagal mengambil foto.',
                    icon: Icons.error_outline);
              }
            }

            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_note_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Buat Postingan',
                                style: AppTextStyles.titleLarge),
                          ),
                          Material(
                            color: AppColors.fieldFill,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(ctx),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close_rounded,
                                    size: 20, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.border),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dropdown kategori
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCat,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                labelStyle: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textMuted),
                              dropdownColor: Colors.white,
                              items: _categories
                                  .where((c) => c != 'Semua')
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c,
                                            style: AppTextStyles.bodyMedium),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedCat = val);
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Text area
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: textController,
                              maxLines: 4,
                              style: AppTextStyles.bodyMedium,
                              decoration: InputDecoration(
                                hintText:
                                    'Tulis pertanyaan, cerita, atau diskusi...',
                                hintStyle: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Preview media
                          if (pickedPath != null) ...[
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(pickedPath!),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setModalState(() => pickedPath = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Tombol foto: galeri atau kamera
                          Row(
                            children: [
                              _MediaPickerButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Galeri',
                                color: AppColors.primary,
                                onTap: () => pickFoto(ImageSource.gallery),
                              ),
                              const SizedBox(width: 10),
                              _MediaPickerButton(
                                icon: Icons.photo_camera_outlined,
                                label: 'Kamera',
                                color: AppColors.secondary,
                                onTap: () => pickFoto(ImageSource.camera),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Tombol Kirim
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  'Kirim Postingan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                onPressed: () async {
                                  final text = textController.text.trim();
                                  if (text.isEmpty && pickedPath == null) {
                                    return;
                                  }
                                  final navigator = Navigator.of(ctx);
                                  try {
                                    await _postService.buatPostingan(
                                      konten: text,
                                      kategori: selectedCat,
                                      mediaPath: pickedPath,
                                    );
                                    navigator.pop();
                                    await _muatPostingan();
                                    _showStyledSnackBar(
                                      'Postingan berhasil dikirim!',
                                      icon: Icons.check_circle_rounded,
                                    );
                                  } catch (e) {
                                    _showStyledSnackBar(
                                      e is Exception
                                          ? e
                                              .toString()
                                              .replaceFirst('Exception: ', '')
                                          : 'Gagal mengirim postingan.',
                                      icon: Icons.error_outline,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        textController.dispose();
      });
    });
  }

  // ─────────────────────── BOTTOM SHEET: KOMENTAR ─────────────────────────
  void _showCommentsSheet(PostModel post) {
    final commentController = TextEditingController();
    List<Map<String, dynamic>> komentar = [];
    bool memuat = true;
    bool mengirim = false;
    bool sudahDimuat = false;
    String? gagal;
    Map<String, dynamic>? komentarDibalas;

    Future<void> muat(StateSetter setModalState) async {
      setModalState(() {
        memuat = true;
        gagal = null;
      });
      try {
        final data = await _postService.fetchKomentar(post.id);
        if (!mounted) return;
        setModalState(() {
          komentar = data;
          memuat = false;
        });
      } catch (e) {
        if (!mounted) return;
        setModalState(() {
          memuat = false;
          gagal = e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Gagal memuat komentar.';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!sudahDimuat) {
              sudahDimuat = true;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => muat(setModalState));
            }

            Future<void> kirim() async {
              final isi = commentController.text.trim();
              if (isi.isEmpty || mengirim) return;
              setModalState(() => mengirim = true);
              try {
                await _postService.kirimKomentar(post.id, isi,
                    parentId: komentarDibalas?['id']?.toString());
                setModalState(() => komentarDibalas = null);
                commentController.clear();
                await muat(setModalState);
                if (mounted) {
                  setState(() => post.comments = komentar.length);
                }
              } catch (e) {
                if (!mounted) return;
                _showStyledSnackBar(
                  e is Exception
                      ? e.toString().replaceFirst('Exception: ', '')
                      : 'Gagal mengirim komentar.',
                  icon: Icons.error_outline,
                );
              } finally {
                setModalState(() => mengirim = false);
              }
            }

            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Komentar', style: AppTextStyles.titleMedium),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.pinkSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${komentar.length}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    Flexible(
                      child: memuat
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : gagal != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 32, horizontal: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 44, color: AppColors.danger),
                                      const SizedBox(height: 12),
                                      Text(gagal!,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodyMedium),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () => muat(setModalState),
                                        child: const Text('Coba lagi'),
                                      ),
                                    ],
                                  ),
                                )
                              : komentar.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 48,
                                              color: AppColors.border),
                                          const SizedBox(height: 12),
                                          Text('Belum ada komentar',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                      color:
                                                          AppColors.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Jadilah yang pertama berkomentar!',
                                              style: AppTextStyles.bodySmall),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 4),
                                      shrinkWrap: true,
                                      itemCount: komentar.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = komentar[index];
                                        final nama = _namaKomentar(item);
                                        final role =
                                            '${item['author_role'] ?? item['role'] ?? ''}';
                                        final username =
                                            '${item['author_username'] ?? ''}';
                                        final isReply =
                                            item['parent_id'] != null;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              left: isReply ? 28 : 0),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.fieldFill,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.pinkSoft,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    nama.isNotEmpty
                                                        ? nama[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(nama,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: AppTextStyles
                                                                    .labelSmall
                                                                    .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColors
                                                                      .textPrimary,
                                                                )),
                                                          ),
                                                          if (role ==
                                                              'admin') ...[
                                                            const SizedBox(
                                                                width: 6),
                                                            const _RoleBadge(
                                                              label: 'Admin',
                                                              bg: AppColors
                                                                  .pinkSoft,
                                                              textColor:
                                                                  AppColors
                                                                      .primary,
                                                            ),
                                                          ],
                                                          if (item['is_current_user'] ==
                                                                  true &&
                                                              '${item['user_id']}' !=
                                                                  post.authorId) ...[
                                                            const SizedBox(
                                                                width: 6),
                                                            const _RoleBadge(
                                                                label: 'Anda',
                                                                bg: AppColors
                                                                    .purpleSoft,
                                                                textColor: AppColors
                                                                    .secondary),
                                                          ],
                                                          if ('${item['user_id']}' ==
                                                              post.authorId) ...[
                                                            const SizedBox(
                                                                width: 6),
                                                            const _RoleBadge(
                                                                label:
                                                                    'Pembuat',
                                                                bg: AppColors
                                                                    .successSoft,
                                                                textColor:
                                                                    AppColors
                                                                        .success),
                                                          ],
                                                          if (role ==
                                                              'mentor') ...[
                                                            const SizedBox(
                                                                width: 6),
                                                            const _RoleBadge(
                                                              label:
                                                                  'Mentor Tuli',
                                                              bg: AppColors
                                                                  .purpleSoft,
                                                              textColor:
                                                                  AppColors
                                                                      .secondary,
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      if (username.isNotEmpty)
                                                        Text('@$username',
                                                            style: AppTextStyles
                                                                .labelSmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                            )),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                          '${item['isi'] ?? ''}',
                                                          style: AppTextStyles
                                                              .bodyMedium
                                                              .copyWith(
                                                                  height: 1.4)),
                                                      TextButton(
                                                        onPressed: () =>
                                                            setModalState(() {
                                                          komentarDibalas =
                                                              item;
                                                          final sebut = username
                                                                  .isNotEmpty
                                                              ? username
                                                              : nama;
                                                          commentController
                                                                  .text =
                                                              '@$sebut ';
                                                          commentController
                                                                  .selection =
                                                              TextSelection.fromPosition(
                                                                  TextPosition(
                                                                      offset: commentController
                                                                          .text
                                                                          .length));
                                                        }),
                                                        style: TextButton
                                                            .styleFrom(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                minimumSize:
                                                                    const Size(
                                                                        48,
                                                                        28)),
                                                        child:
                                                            const Text('Balas'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),

                    // Input komentar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: AppTextStyles.bodyMedium,
                              decoration: InputDecoration(
                                hintText: komentarDibalas == null
                                    ? 'Tulis komentar...'
                                    : 'Membalas ${_namaKomentar(komentarDibalas!)}...',
                                hintStyle: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textMuted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                                onTap: mengirim ? null : kirim,
                                child: mengirim
                                    ? const Padding(
                                        padding: EdgeInsets.all(11),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        commentController.dispose();
      });
    });
  }

  // ─────────────────────── BOTTOM SHEET: OPSI LAINNYA ─────────────────────
  void _showMoreOptions(PostModel post) {
    showAppBottomSheet<void>(
      context,
      title: 'Opsi Postingan',
      icon: Icons.more_horiz_rounded,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetOptionTile(
            icon: Icons.chat_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.pinkSoft,
            title: 'Kirim Pesan ke ${post.userName}',
            onTap: () {
              Navigator.pop(ctx);
              _openChat();
            },
          ),
          AppSheetOptionTile(
            icon: Icons.link_rounded,
            iconColor: AppColors.secondary,
            iconBackground: AppColors.purpleSoft,
            title: 'Salin Tautan Postingan',
            onTap: () {
              Navigator.pop(ctx);
              _showStyledSnackBar('Tautan berhasil disalin!',
                  icon: Icons.check_circle_rounded);
            },
          ),
          AppSheetOptionTile(
            icon: Icons.flag_outlined,
            iconColor: AppColors.danger,
            iconBackground: AppColors.dangerSoft,
            title: 'Laporkan Postingan',
            titleColor: AppColors.danger,
            onTap: () {
              Navigator.pop(ctx);
              _laporkanPostingan(post);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _laporkanPostingan(PostModel post) async {
    final ok = await showAppDialog(
      context,
      title: 'Laporkan postingan?',
      message: 'Laporan "${post.userName}" akan masuk ke panel admin.',
      icon: Icons.flag_rounded,
      confirmLabel: 'Laporkan',
      isDestructive: true,
    );
    if (ok != true || !mounted) return;
    try {
      await _postService.laporkanPostingan(
        konten: post.content,
        penulis: post.userName,
      );
      if (!mounted) return;
      _showStyledSnackBar('Laporan telah dikirim ke admin.',
          icon: Icons.check_circle_rounded);
    } catch (e) {
      if (!mounted) return;
      _showStyledSnackBar(
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;

    return Scaffold(
      // Transparan agar gradasi [AppBackground] dari MainShell terlihat.
      backgroundColor: Colors.transparent,
      // Shell memakai `extendBody`, jadi FAB digeser manual agar melayang
      // sedikit di atas navbar.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: AppBottomNavBar.barTopOffset(context) + 28,
        ),
        child: _buildFAB(),
      ),
      body: RefreshIndicator(
        onRefresh: _muatPostingan,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSearchBar(),
            _buildFilterChips(),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 56, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _muatPostingan,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 56, color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(
                        _posts.isEmpty
                            ? 'Belum ada postingan. Jadilah yang pertama berbagi!'
                            : 'Tidak ada postingan ditemukan.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            _buildBottomPromoBanner(),
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppBottomNavBar.reservedSpace(context) + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AppFab(
      label: 'Postingan',
      onPressed: _showCreatePostSheet,
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            // Radius sama dengan tombol header Beranda/Komunitas.
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _filteredCache = null;
                  }),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Cari diskusi, pertanyaan, atau teman...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filteredCache = null;
                    });
                  },
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppChoiceChip(
                label: cat,
                isSelected: _selectedCategory == cat,
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _filteredCache = null;
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────── KARTU POSTINGAN ────────────────────────────────
  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        // Samakan sudut kartu dengan kartu Beranda (AppCard = AppRadii.xl).
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kartu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(post),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.userName,
                              style: AppTextStyles.labelLarge
                                  .copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RoleBadge(
                            label: post.userRole,
                            bg: post.roleColor,
                            textColor: post.roleTextColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _PostMetaBadge(
                            icon: Icons.schedule_rounded,
                            label: _formatWaktu(post.createdAt),
                          ),
                          _PostMetaBadge(
                            icon: Icons.sell_outlined,
                            label: post.categoryText,
                            accent: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showMoreOptions(post),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.more_horiz_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten teks
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                post.content,
                style: AppTextStyles.bodyMedium
                    .copyWith(height: 1.5, color: AppColors.textPrimary),
              ),
            ),

          // Media section
          if (post.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildUserMedia(post),
            ),

          // Divider
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Divider(height: 1, color: AppColors.border),
          ),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _ActionButton(
                  icon: post.isLiked
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: '${post.likes} ${post.likeLabel}',
                  color: post.isLiked
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  filled: post.isLiked,
                  onTap: () => _toggleLike(post),
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments} Komentar',
                  color: AppColors.textSecondary,
                  onTap: () => _showCommentsSheet(post),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _toggleBookmark(post),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        post.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: post.isSaved
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(PostModel post) {
    return UserAvatar(
      imageUrl: (post.avatarUrl?.isEmpty ?? true) ? null : post.avatarUrl,
      name: post.userName,
      size: 42,
    );
  }

  /// "Baru saja", "5 menit lalu", "2 hari lalu", atau tanggal singkat.
  String _namaKomentar(Map<String, dynamic> item) => namaTampilDari({
        'full_name': item['author_name'],
        'username': item['author_username'],
      });

  String _formatWaktu(DateTime? waktu) {
    if (waktu == null) return 'Baru saja';
    final selisih = DateTime.now().difference(waktu);
    if (selisih.inMinutes < 1) return 'Baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}';
  }

  Widget _buildUserMedia(PostModel post) {
    final url = post.mediaUrl!;
    if (post.mediaIsVideo) {
      return _NetworkVideoBox(path: url);
    }
    // Lebar media = lebar layar - margin kartu (40) - padding media (32).
    // Decode dibatasi agar foto besar tidak memakan memori penuh.
    final lebarMedia = MediaQuery.sizeOf(context).width - 72;
    final cacheSize =
        (lebarMedia * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      // Radius media sama dengan tile di Beranda (AppRadii.md).
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Image.network(
        url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: AppColors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text('Foto tidak bisa ditampilkan',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: GestureDetector(
          onTap: _showCreatePostSheet,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.pinkSoft,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ragu dengan bentuk isyaratmu?',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bagikan videomu dan dapatkan masukan dari komunitas & mentor Tuli.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET HELPER REUSABLE
// ─────────────────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _RoleBadge({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PostMetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _PostMetaBadge({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: filled
              ? BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: filled ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
