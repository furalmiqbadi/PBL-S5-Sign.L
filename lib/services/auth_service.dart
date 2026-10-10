/// Service layer untuk alur autentikasi.
/// Implementasi ini masih lokal/mock sampai Firebase diaktifkan.
class AuthService {
  Future<void> login({required String email, required String password}) async => _wait();
  Future<void> register({required String email, required String password}) async => _wait();
  Future<void> sendResetLink(String email) async => _wait();
  Future<void> resetPassword({required String password, required String confirmation}) async => _wait();

  Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 350));
}
