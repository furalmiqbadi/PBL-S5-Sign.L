import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Thin controller: hanya menyimpan state tampilan dan menjembatani View
/// dengan AuthService sesuai panduan arsitektur Sign.L.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  String _currentEmail = 'budi@gmail.com';
  String _currentName = 'Budi Pratama';

  AuthController({AuthService? authService}) : _authService = authService ?? AuthService();

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
    final ok = await _run(() => _authService.login(email: email, password: password));
    if (ok) {
      _isLoggedIn = true;
      if (email.trim().isNotEmpty) {
        _currentEmail = email.trim();
        _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
      }
      notifyListeners();
    }
    return ok;
  }

  Future<bool> register({required String email, required String password, String? name}) async {
    final ok = await _run(() => _authService.register(email: email, password: password));
    if (ok) {
      _isLoggedIn = true;
      if (email.trim().isNotEmpty) _currentEmail = email.trim();
      if (name != null && name.trim().isNotEmpty) {
        _currentName = name.trim();
      } else if (email.trim().isNotEmpty) {
        _currentName = _currentEmail.contains('@') ? _currentEmail.split('@').first : _currentEmail;
      }
      notifyListeners();
    }
    return ok;
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
