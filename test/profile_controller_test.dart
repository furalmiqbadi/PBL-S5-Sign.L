import 'package:flutter_test/flutter_test.dart';
import 'package:sign_l/controllers/profile_controller.dart';
import 'package:sign_l/models/user_profile_model.dart';
import 'package:sign_l/services/profile_service.dart';

void main() {
  group('ProfileController', () {
    test('memuat profil dari service in-memory', () async {
      final controller = ProfileController(service: ProfileService.inMemory());

      await controller.load();

      expect(controller.profile, isNotNull);
      expect(controller.profile!.displayName, 'Sarah Chen');
      expect(controller.profile!.displayUsername, '@sarah.creates');
      expect(controller.profile!.levelCode, 'L2');
      expect(controller.profile!.featuredBadges, hasLength(3));
      expect(controller.errorMessage, isNull);
    });

    test('menyimpan perubahan profil dan memperbarui state', () async {
      final controller = ProfileController(service: ProfileService.inMemory());
      await controller.load();

      final saved = await controller.save(
        fullName: 'Sarah Chen',
        username: 'sarah.baru',
        bio: 'Bio baru',
        phone: '+62 812-0000-0000',
        level: 3,
        avatarUrl: 'https://example.com/avatars/u/avatar.webp',
        featuredBadges: ['perfect_100'],
        motivations: ['Pekerjaan'],
      );

      expect(saved, isTrue);
      expect(controller.isSaving, isFalse);
      expect(controller.profile!.username, 'sarah.baru');
      expect(controller.profile!.bio, 'Bio baru');
      expect(controller.profile!.level, 3);
      expect(controller.profile!.levelLabel, 'Tingkat Mahir (Level 3)');
      expect(controller.profile!.featuredBadges, ['perfect_100']);
      expect(controller.profile!.motivations, ['Pekerjaan']);
      expect(controller.profile!.updatedAt, isNotNull);
    });

    test('menampilkan pesan saat username sudah dipakai', () async {
      final controller = ProfileController(service: ProfileService.inMemory());
      await controller.load();

      final saved = await controller.save(username: 'taken');

      expect(saved, isFalse);
      expect(controller.errorMessage, 'Username sudah dipakai');
      expect(controller.profile!.username, 'sarah.creates');
    });

    test('menolak level di luar 1-3', () async {
      final controller = ProfileController(service: ProfileService.inMemory());
      await controller.load();

      final saved = await controller.save(level: 5);

      expect(saved, isFalse);
      expect(controller.errorMessage, 'Level harus 1, 2, atau 3');
    });

    test('mengunggah avatar mengembalikan URL publik', () async {
      final controller = ProfileController(service: ProfileService.inMemory());
      await controller.load();

      final url = await controller.uploadAvatar('avatar.webp');

      expect(url, isNotNull);
      expect(url, startsWith('https://'));
      expect(controller.errorMessage, isNull);
    });

    test('reset membersihkan profil saat logout', () async {
      final controller = ProfileController(service: ProfileService.inMemory());
      await controller.load();
      expect(controller.profile, isNotNull);

      controller.reset();

      expect(controller.profile, isNull);
      expect(controller.errorMessage, isNull);
    });
  });

  group('UserProfile', () {
    test('memetakan JSON ke model dan mengubah level menjadi label', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'username': 'budi',
        'full_name': 'Budi Pratama',
        'bio': 'Halo',
        'phone': null,
        'level': 3,
        'xp': 120,
        'streak': 4,
        'points': 900,
        'featured_badges': ['perfect_100', 'streak_7'],
        'learning_motivations': ['Pekerjaan'],
        'updated_at': '2026-11-15T10:00:00Z',
      });

      expect(profile.displayName, 'Budi Pratama');
      expect(profile.displayUsername, '@budi');
      expect(profile.levelCode, 'L3');
      expect(profile.levelLabel, 'Tingkat Mahir (Level 3)');
      expect(profile.featuredBadges, hasLength(2));
      expect(profile.motivations, ['Pekerjaan']);
      expect(profile.initials, 'BP');
      expect(profile.updatedAt!.isUtc, isFalse);
    });

    test('memakai username sebagai nama bila full_name kosong', () {
      const profile = UserProfile(id: 'u2', username: 'sarah', fullName: '');

      expect(profile.displayName, 'sarah');
      expect(profile.initials, 'S');
    });
  });
}
