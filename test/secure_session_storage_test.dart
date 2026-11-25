// Uji penyimpanan sesi terenkripsi ("save login" ala Instagram).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sign_l/services/secure_session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sesi = '{"access_token":"abc","refresh_token":"def"}';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('Sesi disimpan dan dibaca kembali dari penyimpanan terenkripsi',
      () async {
    final storage = SecureSessionStorage();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);

    await storage.persistSession(sesi);

    expect(await storage.accessToken(), sesi);
    expect(await storage.hasAccessToken(), isTrue);

    // Membuat instance baru meniru aplikasi yang dibuka ulang.
    expect(await SecureSessionStorage().accessToken(), sesi);

    await storage.removePersistedSession();
    expect(await storage.accessToken(), isNull);
  });

  test('Sesi lama di SharedPreferences dipindah sekali ke penyimpanan aman',
      () async {
    SharedPreferences.setMockInitialValues({'sb-lama-auth-token': sesi});
    final storage = SecureSessionStorage(legacyKey: 'sb-lama-auth-token');

    await storage.initialize();

    expect(await storage.accessToken(), sesi);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sb-lama-auth-token'), isNull);

    // Sesi aman yang sudah ada tidak ditimpa sesi lama.
    await storage.removePersistedSession();
    await storage.persistSession('sesi-baru');
    await SharedPreferences.getInstance().then(
      (p) => p.setString('sb-lama-auth-token', sesi),
    );
    await storage.initialize();
    expect(await storage.accessToken(), 'sesi-baru');
  });
}
