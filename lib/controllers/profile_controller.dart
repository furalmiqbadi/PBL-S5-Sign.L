import 'package:flutter/foundation.dart';

import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

/// Menyimpan state profil pengguna yang sedang login.
///
/// Sama seperti controller lain: tidak mengakses Supabase langsung,
/// semua lewat [ProfileService] agar mudah diuji dengan data in-memory.
class ProfileController extends ChangeNotifier {
  ProfileController({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;

  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Memuat profil dari server. Diabaikan bila profil sudah ada dan
  /// [force] bernilai `false`.
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_profile != null && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.fetchMyProfile();
    } catch (e) {
      debugPrint('[Profile] Gagal memuat profil: $e');
      _errorMessage = mapProfileError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    String? fullName,
    String? username,
    String? bio,
    String? phone,
    int? level,
    String? avatarUrl,
    List<String>? featuredBadges,
    List<String>? motivations,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.updateMyProfile(
        fullName: fullName,
        username: username,
        bio: bio,
        phone: phone,
        level: level,
        avatarUrl: avatarUrl,
        featuredBadges: featuredBadges,
        motivations: motivations,
      );
      return true;
    } catch (e) {
      debugPrint('[Profile] Gagal menyimpan profil: $e');
      _errorMessage = mapProfileError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Mengunggah foto profil dan mengembalikan URL publiknya.
  /// `null` berarti gagal; pesan ada di [errorMessage].
  Future<String?> uploadAvatar(String filePath) async {
    _errorMessage = null;
    try {
      return await _service.uploadAvatar(filePath);
    } catch (e) {
      debugPrint('[Profile] Gagal mengunggah avatar: $e');
      _errorMessage = mapProfileError(e);
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Dipanggil saat logout agar data pengguna sebelumnya tidak tersisa.
  void reset() {
    _profile = null;
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }
}
