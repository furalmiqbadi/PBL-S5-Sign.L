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
  String _currentEmail = 'budi@gmail.com';
  String _currentName = 'Budi Pratama';

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _syncUserFromSession();
  }

  void _syncUserFromSession() {
    final user = _authService.currentUser;
    if (user != null) {
      _isLoggedIn = true;
      _currentEmail = user.email ?? _currentEmail;
      final metaName = user.userMetadata?['full_name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _currentName = metaName;
      } else if (user.email != null && user.email!.contains('@')) {
        _currentName = user.email!.split('@').first;
      }
    }
  }

  bool get isLoading => _isLoading;
  bool get showPassword => _showPassword;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String get currentEmail => _currentEmail;
  String get currentName => _currentName;

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    final ok = await _run(() async {
      final res = await _authService.login(email: email, password: password);
      _isLoggedIn = true;
      if (res?.user != null) {
        _currentEmail = res!.user!.email ?? email.trim();
        final metaName = res.user!.userMetadata?['full_name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          _currentName = metaName;
        } else {
          _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
        }
      } else {
        if (email.trim().isNotEmpty) {
          _currentEmail = email.trim();
          _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
        }
      }
    });
    return ok;
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
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
    String? username,
  }) async {
    final ok = await _run(() async {
    return _run(() async {
      final res = await _authService.register(
        email: email,
        password: password,
        name: name,
        username: username,
      );
      _isLoggedIn = true;
      if (res?.user != null) {
        _currentEmail = res!.user!.email ?? email.trim();
        if (name != null && name.trim().isNotEmpty) {
          _currentName = name.trim();
        } else {
          _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
        }
      } else {
        if (email.trim().isNotEmpty) _currentEmail = email.trim();
        if (name != null && name.trim().isNotEmpty) {
          _currentName = name.trim();
        } else if (email.trim().isNotEmpty) {
          _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
        }
      }
    });
    return ok;
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
