import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile_model.dart';

/// Error yang pesannya sudah layak ditampilkan ke pengguna.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Menerjemahkan error service/Supabase menjadi pesan yang ramah.
String mapProfileError(Object error) {
  if (error is ProfileException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '23505') return 'Username sudah dipakai';
    if (error.code == '42501') {
      return 'Kamu tidak punya izin mengubah profil ini.';
    }
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }
  if (error is StateError) return error.message;
  return 'Gagal menyimpan profil. Periksa koneksi lalu coba lagi.';
}

abstract class ProfileService {
  factory ProfileService({SupabaseClient? client}) = SupabaseProfileService;
  factory ProfileService.inMemory() = InMemoryProfileService;

  Future<UserProfile> fetchMyProfile();

  Future<UserProfile> updateMyProfile({
    String? fullName,
    String? username,
    String? bio,
    String? phone,
    int? level,
    String? avatarUrl,
    List<String>? featuredBadges,
    List<String>? motivations,
  });

  /// Mengunggah foto profil (WebP) dan mengembalikan URL publiknya.
  Future<String> uploadAvatar(String filePath);
}

class SupabaseProfileService implements ProfileService {
  SupabaseProfileService({SupabaseClient? client}) : _customClient = client;

  static const String _avatarBucket = 'avatars';

  final SupabaseClient? _customClient;

  SupabaseClient get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw const ProfileException('Supabase belum terhubung.');
    }
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const ProfileException('Silakan login untuk mengubah profil.');
    }
    return id;
  }

  static const String _columns =
      'id, username, full_name, avatar_url, bio, phone, level, xp, streak, '
      'points, featured_badges, learning_motivations, updated_at';

  @override
  Future<UserProfile> fetchMyProfile() async {
    final row = await _client
        .from('profiles')
        .select(_columns)
        .eq('id', _userId)
        .maybeSingle();
    if (row == null) {
      throw const ProfileException('Profil tidak ditemukan.');
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<UserProfile> updateMyProfile({
    String? fullName,
    String? username,
    String? bio,
    String? phone,
    int? level,
    String? avatarUrl,
    List<String>? featuredBadges,
    List<String>? motivations,
  }) async {
    final raw = await _client.rpc(
      'update_my_profile',
      params: {
        'p_full_name': fullName,
        'p_username': username,
        'p_bio': bio,
        'p_phone': phone,
        'p_level': level,
        'p_avatar_url': avatarUrl,
        'p_featured_badges': featuredBadges,
        'p_motivations': motivations,
      },
    );
    final row = raw is List ? (raw.isEmpty ? null : raw.first) : raw;
    if (row is! Map) {
      throw const ProfileException('Gagal menyimpan profil. Coba lagi.');
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    if (kIsWeb) {
      throw const ProfileException('Unggah foto belum didukung di web.');
    }
    final uid = _userId;
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const ProfileException('File foto tidak ditemukan.');
    }
    final lower = filePath.toLowerCase();
    final isPng = lower.endsWith('.png');
    final isJpeg = lower.endsWith('.jpg') || lower.endsWith('.jpeg');
    final extension = isPng
        ? 'png'
        : isJpeg
            ? 'jpg'
            : 'webp';
    final contentType = isPng
        ? 'image/png'
        : isJpeg
            ? 'image/jpeg'
            : 'image/webp';
    final path = '$uid/avatar.$extension';
    await _client.storage.from(_avatarBucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
    final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

class InMemoryProfileService implements ProfileService {
  InMemoryProfileService({UserProfile? profile})
      : _profile = profile ??
            const UserProfile(
              id: 'in-memory-user',
              username: 'sarah.creates',
              fullName: 'Sarah Chen',
              bio: 'Pelajar Bahasa Isyarat BISINDO Pemula',
              phone: '+62 812-3456-7890',
              level: 2,
              xp: 320,
              streak: 7,
              points: 1250,
              featuredBadges: ['perfect_100', 'streak_7', 'fast_signer'],
              motivations: ['Komunikasi Keluarga', 'Pekerjaan', 'Teman Tuli'],
            );

  UserProfile _profile;

  @override
  Future<UserProfile> fetchMyProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _profile;
  }

  @override
  Future<UserProfile> updateMyProfile({
    String? fullName,
    String? username,
    String? bio,
    String? phone,
    int? level,
    String? avatarUrl,
    List<String>? featuredBadges,
    List<String>? motivations,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final normalized = username?.trim().toLowerCase();
    if (normalized == 'taken') {
      throw const ProfileException('Username sudah dipakai');
    }
    if (level != null && (level < 1 || level > 3)) {
      throw const ProfileException('Level harus 1, 2, atau 3');
    }
    if (featuredBadges != null && featuredBadges.length > 3) {
      throw const ProfileException('Maksimal 3 lencana unggulan');
    }
    _profile = _profile.copyWith(
      fullName: fullName,
      username: normalized ?? _profile.username,
      bio: bio,
      phone: phone,
      level: level,
      avatarUrl: avatarUrl,
      featuredBadges: featuredBadges,
      motivations: motivations,
      updatedAt: DateTime.now(),
    );
    return _profile;
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return 'https://example.com/avatars/$filePath'
        '?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
