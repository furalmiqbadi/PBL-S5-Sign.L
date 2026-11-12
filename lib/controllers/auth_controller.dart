import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Thin controller: menyimpan status tampilan autentikasi dan
/// menjembatani View dengan AuthService (Supabase).
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String _currentEmail = 'budi@gmail.com';
  String _currentName = 'Budi Pratama';
  String _currentUsername = 'budipratama';
  String _currentBio = 'Pelajar Bahasa Isyarat BISINDO';
  String _currentPhone = '';
  String? _currentAvatarUrl;
  int _points = 420;
  int _xp = 350;
  int _streak = 7;
  int _level = 1;
  List<String> _featuredBadges = const ['perfect_100', 'streak_7', 'fast_signer'];

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _syncUserFromSession();
  }

  Future<void> _syncUserFromSession() async {
    final user = _authService.currentUser;
    if (user != null) {
      _isLoggedIn = true;
      _currentEmail = user.email ?? _currentEmail;
      final metaName = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _currentName = metaName;
      } else if (user.email != null && user.email!.contains('@')) {
        _currentName = user.email!.split('@').first;
      }
      final metaUsername = user.userMetadata?['username'] as String?;
      if (metaUsername != null && metaUsername.isNotEmpty) {
        _currentUsername = metaUsername;
      }

      // Ambil data profil dari tabel `profiles` di Supabase
      try {
        final profile = await _authService.fetchProfile();
        if (profile != null) {
          if (profile['full_name'] is String && (profile['full_name'] as String).isNotEmpty) {
            _currentName = profile['full_name'];
          }
          if (profile['username'] is String && (profile['username'] as String).isNotEmpty) {
            _currentUsername = profile['username'];
          }
          if (profile['bio'] is String) {
            _currentBio = profile['bio'];
          }
          if (profile['phone'] is String) {
            _currentPhone = profile['phone'];
          }
          if (profile['avatar_url'] is String) {
            _currentAvatarUrl = profile['avatar_url'];
          }
          if (profile['points'] is int) {
            _points = profile['points'];
          }
          if (profile['xp'] is int) {
            _xp = profile['xp'];
          }
          if (profile['streak'] is int) {
            _streak = profile['streak'];
          }
          if (profile['level'] is int) {
            _level = profile['level'];
          }
          if (profile['featured_badges'] is List) {
            _featuredBadges = List<String>.from(profile['featured_badges']);
          }
        }
      } catch (e) {
        debugPrint('[AuthController] Gagal sync profile: $e');
      }

      if (_authService.isAuthenticated) {
        _isAdmin = await _authService.fetchRole() == 'admin';
        notifyListeners();
      }
    }
  }

  bool get isLoading => _isLoading;
  bool get showPassword => _showPassword;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String get currentEmail => _currentEmail;
  String get currentName => _currentName;
  String get currentUsername => _currentUsername;
  String get currentBio => _currentBio;
  String get currentPhone => _currentPhone;
  String? get currentAvatarUrl => _currentAvatarUrl;
  int get points => _points;
  int get xp => _xp;
  int get streak => _streak;
  int get level => _level;
  List<String> get featuredBadges => _featuredBadges;

  Future<void> refreshProfile() async {
    await _syncUserFromSession();
  }

  Future<String?> uploadAvatarBytes(Uint8List bytes, {String fileExt = 'webp'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _authService.uploadAvatarBytes(bytes, fileExt: fileExt);
      if (url != null) {
        _currentAvatarUrl = url;
        notifyListeners();
      }
      return url;
    } catch (e) {
      debugPrint('[AuthController] Gagal upload avatar bytes: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar(dynamic file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = await _authService.uploadAvatar(file);
      if (url != null) {
        _currentAvatarUrl = url;
        notifyListeners();
      }
      return url;
    } catch (e) {
      debugPrint('[AuthController] Gagal upload avatar: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) async {
    return _run(() async {
      if (_authService.isAuthenticated) {
        try {
          await _authService.updateProfile(
            fullName: name,
            username: username,
            bio: bio,
            phone: phone,
            avatarUrl: avatarUrl,
          );
        } catch (e) {
          debugPrint('[AuthController] Update profile Supabase gagal: $e');
          rethrow;
        }
      }
      if (name != null) _currentName = name;
      if (username != null) _currentUsername = username;
      if (bio != null) _currentBio = bio;
      if (phone != null) _currentPhone = phone;
      if (avatarUrl != null) _currentAvatarUrl = avatarUrl;
    });
  }

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() async {
      final res = await _authService.login(email: email, password: password);
      final user = res.user;
      _isLoggedIn = true;
      _currentEmail = user?.email ?? email.trim();

      final metaName = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _currentName = metaName;
      } else {
        _currentName = _currentEmail.contains('@')
            ? _currentEmail.split('@').first
            : _currentEmail;
      }
      _isAdmin = await _authService.fetchRole() == 'admin';
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    return _run(() async {
      final res = await _authService.register(
        email: email,
        password: password,
        name: name,
        username: username,
      );
      final user = res.user;

      // Jika project Supabase mewajibkan konfirmasi email, session masih null.
      _isLoggedIn = res.session != null;
      _currentEmail = user?.email ?? email.trim();

      final metaName = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _currentName = metaName;
      } else if (name != null && name.trim().isNotEmpty) {
        _currentName = name.trim();
      } else {
        _currentName = _currentEmail.contains('@')
            ? _currentEmail.split('@').first
            : _currentEmail;
      }
    });
  }

  Future<bool> sendResetLink(String email) async {
    return await _run(() => _authService.sendResetLink(email));
  }

  Future<bool> resetPassword({required String password, required String confirmation}) async {
    return await _run(() => _authService.resetPassword(password: password, confirmation: confirmation));
  }

  Future<void> logout() async {
    await _run(() => _authService.logout());
    _isLoggedIn = false;
    _isAdmin = false;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
