import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Thin controller: hanya menyimpan state tampilan dan menjembatani View
/// dengan AuthService. Integrasi Firebase dapat ditambahkan tanpa mengubah UI.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  AuthController({AuthService? authService}) : _authService = authService ?? AuthService();

  bool get isLoading => _isLoading;
  bool get showPassword => _showPassword;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _run(() => _authService.login(email: email, password: password));
  }

  Future<void> register({required String email, required String password}) async {
    await _run(() => _authService.register(email: email, password: password));
  }

  Future<void> sendResetLink(String email) async {
    await _run(() => _authService.sendResetLink(email));
  }

  Future<void> resetPassword({required String password, required String confirmation}) async {
    await _run(() => _authService.resetPassword(password: password, confirmation: confirmation));
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await action();
    _isLoading = false;
    notifyListeners();
  }
}
