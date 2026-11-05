import 'package:flutter/material.dart';
import '../chat/chat_list_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PostModel {
  final String id;
  final String userName;
  final String userRole;
  final Color roleColor;
  final Color roleTextColor;
  final String timeText;
  final String categoryText;
  final String content;
  final String? videoTitle;
  final String? videoDuration;
  final bool isCertificate;
  final double? certScore;
  final bool isEvent;
  final String? eventLocation;
  final String? eventDate;
  int likes;
  final String likeLabel;
  int comments;
  List<String> commentList;
  bool isLiked;
  bool isSaved;
  bool isJoinedEvent;

  PostModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.roleColor,
    required this.roleTextColor,
    required this.timeText,
    required this.categoryText,
    required this.content,
    this.videoTitle,
    this.videoDuration,
    this.isCertificate = false,
    this.certScore,
    this.isEvent = false,
    this.eventLocation,
    this.eventDate,
    required this.likes,
    required this.likeLabel,
    required this.comments,
    required this.commentList,
    this.isLiked = false,
    this.isSaved = false,
    this.isJoinedEvent = false,
  });
}

class KomunitasPage extends StatefulWidget {
  const KomunitasPage({super.key});

  @override
  State<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends State<KomunitasPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Tanya Isyarat',
    'Tips & Trik',
    'Cerita Sukses',
    'Temu Belajar',
  ];

  late List<PostModel> _posts;

  @override
  void initState() {
    super.initState();
    _posts = [
      PostModel(
        id: '1',
        userName: 'Dina Safitri',
        userRole: 'Bab 1: Pemula',
        roleColor: AppColors.primary.withValues(alpha: 0.1),
        roleTextColor: AppColors.primary,
        timeText: '15 menit lalu',
        categoryText: 'Tanya Isyarat',
        content:
            "Teman-teman, apakah lekuk jari jempol saya untuk huruf 'D' BISINDO ini sudah pas atau terlalu miring ya? Mohon koreksinya 🙏",
        videoTitle: 'Deteksi AI: Huruf D (82%)',
        videoDuration: '0:06',
        likes: 19,
        likeLabel: 'Bantu',
        comments: 24,
        commentList: [
          'Sudah lumayan pas, coba lekukan jempol ditegakkan sikit!',
          'Bisa cek modul latihan 3 untuk referensi angle kamera ya.',
        ],
      ),
      PostModel(
        id: '2',
        userName: 'Budi Santoso',
        userRole: 'Streak 30 Hari 🔥',
        roleColor: AppColors.orangeSoft,
        roleTextColor: AppColors.tertiary,
        timeText: '2 jam lalu',
        categoryText: 'Cerita Sukses',
        content:
            "Akhirnya lulus ujian Bab 1 dengan akurasi kamera AI 98%! Kuncinya sering stretching jari sebelum latihan kawan-kawan. Konsistensi 10 menit sehari benar-benar terasa hasilnya 🙌✨",
        isCertificate: true,
        certScore: 98.4,
        likes: 142,
        likeLabel: 'Suka',
        comments: 18,
        commentList: ['Selamat mas Budi!', 'Keren banget, inspiratif!'],
      ),
      PostModel(
        id: '3',
        userName: 'Siti Rahma',
        userRole: 'Klub Jakarta',
        roleColor: AppColors.purpleSoft,
        roleTextColor: AppColors.secondary,
        timeText: '4 jam lalu',
        categoryText: 'Temu Belajar',
        content:
            "Halo teman-teman Jabodetabek! Minggu ini kita ada sesi tatap muka santai di Tebet Eco Park jam 09.00 WIB untuk latihan isyarat kata sehari-hari. Gratis dan terbuka untuk semua tingkatan ya! 🌿",
        isEvent: true,
        eventLocation: 'Tebet Eco Park, Jaksel',
        eventDate: 'Minggu, 19 Mei • 09:00 WIB',
        likes: 56,
        likeLabel: 'Suka',
        comments: 32,
        commentList: ['Aku bakal datang nih!', 'Ada grup WhatsApp-nya ga?'],
        isSaved: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PostModel> get _filteredPosts {
    return _posts.where((post) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          post.categoryText.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          post.userName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleLike(PostModel post) {
    setState(() {
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
    });
  }

  void _toggleBookmark(PostModel post) {
    setState(() {
      post.isSaved = !post.isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          post.isSaved ? 'Postingan disimpan' : 'Batal menyimpan postingan',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleJoinEvent(PostModel post) {
    setState(() {
      post.isJoinedEvent = !post.isJoinedEvent;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          post.isJoinedEvent
              ? 'Kamu berhasil terdaftar di sesi ini!'
              : 'Kamu membatalkan pendaftaran sesi.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _showCreatePostSheet() {
    final textController = TextEditingController();
    String selectedCat = 'Tanya Isyarat';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Buat Postingan Baru', style: AppTextStyles.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    decoration: InputDecoration(
                      labelText: 'Pilih Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .where((c) => c != 'Semua')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan, cerita, atau diskusi...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (textController.text.trim().isEmpty) return;
                        setState(() {
                          _posts.insert(
                            0,
                            PostModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userName: 'Kamu',
                              userRole: 'Pembelajar',
                              roleColor: AppColors.primary.withValues(alpha: 0.1),
                              roleTextColor: AppColors.primary,
                              timeText: 'Baru saja',
                              categoryText: selectedCat,
                              content: textController.text.trim(),
                              likes: 0,
                              likeLabel: 'Suka',
                              comments: 0,
                              commentList: [],
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Postingan berhasil dikirim!'),
                          ),
                        );
                      },
                      child: const Text(
                        'Kirim Postingan',
                        style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsSheet(PostModel post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Komentar (${post.comments})', style: AppTextStyles.titleMedium),
                    const Divider(),
                    Expanded(
                      child: post.commentList.isEmpty
                          ? const Center(
                              child: Text('Belum ada komentar. Jadi yang pertama!'),
                            )
                          : ListView.builder(
                              itemCount: post.commentList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(post.commentList[index]),
                                  subtitle: const Text('Anggota Komunitas'),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Tulis komentar...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary),
                          onPressed: () {
                            if (commentController.text.trim().isEmpty) return;
                            setState(() {
                              post.commentList.add(commentController.text.trim());
                              post.comments++;
                            });
                            setModalState(() {});
                            commentController.clear();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMoreOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text('Kirim Pesan ke ${post.userName}'),
              onTap: () {
                Navigator.pop(ctx);
                _openChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Salin Tautan Postingan'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan berhasil disalin!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
              title: const Text('Laporkan Postingan', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan telah dikirim ke moderator.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
        label: const Text('Postingan', style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSearchBar(),
          _buildFilterChips(),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Tidak ada postingan ditemukan.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = filtered[index];
                      return _buildPostCard(post);
                    },
                    childCount: filtered.length,
                  ),
                ),
          _buildBottomPromoBanner(),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari diskusi, pertanyaan, atau teman...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
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
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.pinkSoft,
                child: Text(
                  post.userName[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.userName,
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: post.roleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.userRole,
                            style: TextStyle(
                              color: post.roleTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.timeText} • ${post.categoryText}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                onPressed: () => _showMoreOptions(post),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.4, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (post.videoTitle != null)
            _buildVideoMedia(post.videoTitle!, post.videoDuration ?? '0:00'),
          if (post.isCertificate)
            _buildCertificateMedia(post.certScore ?? 0.0),
          if (post.isEvent)
            _buildEventMedia(post),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLike(post),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            size: 18,
                            color: post.isLiked ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likes} ${post.likeLabel}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: post.isLiked ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: post.isLiked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showCommentsSheet(post),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${post.comments} Komentar',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: post.isSaved ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _toggleBookmark(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMedia(String title, String duration) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Center(
            child: IconButton(
              iconSize: 48,
              icon: const Icon(Icons.play_circle_fill, color: AppColors.textOnPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Memutar video AI...')),
                );
              },
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Text(
              duration,
              style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateMedia(double score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pinkSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sertifikat Kelulusan: Alfabet & Angka',
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Skor Akurasi AI: $score%',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMedia(PostModel post) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.textOnPrimary, size: 16),
                const SizedBox(width: 4),
                Text(
                  post.eventLocation ?? '',
                  style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      post.eventDate ?? '',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: post.isJoinedEvent ? AppColors.textMuted : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _toggleJoinEvent(post),
                  child: Text(
                    post.isJoinedEvent ? 'Tergabung ✓' : 'Ikut Sesi',
                    style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomPromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: GestureDetector(
          onTap: _showCreatePostSheet,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.pinkSoft, AppColors.purpleSoft],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ragu dengan bentuk isyaratmu?',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unggah video singkat dan minta tanggapan hangat dari komunitas dan mentor Tuli.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
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