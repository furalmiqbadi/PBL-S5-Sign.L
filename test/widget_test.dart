// Smoke test untuk kerangka aplikasi Sign.L, alur otentikasi, dan bottom navbar.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sign_l/main.dart';
import 'package:sign_l/views/auth/auth_views.dart';
import 'package:sign_l/views/widgets/app_bottom_nav_bar.dart';

void main() {
  setUpAll(() {
    // Cegah pengunduhan font saat pengujian.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Mock HTTP client untuk gambar jaringan agar pengujian tidak gagal saat fetch avatar.
    HttpOverrides.global = _MockHttpOverrides();
  });

  // Aplikasi mulai di halaman login. Tekan "Masuk" untuk masuk ke kerangka
  // utama; autentikasi masih mock sehingga kredensial apa pun diterima.
  Future<void> masukKeAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(const SignLApp());
    expect(find.text('Masuk  →'), findsOneWidget);
    await tester.tap(find.text('Masuk  →'));
    await tester.pumpAndSettle();
  }

  testWidgets('Halaman Login tampil secara default dengan input dan tombol',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SignLApp());

    // Memastikan halaman Login dirender
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Selamat Datang Kembali! 👋'), findsOneWidget);
    expect(find.text('Masuk  →'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);

    // Navigasi ke halaman Register dengan memastikan widget terlihat di layar uji
    await tester.ensureVisible(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('Login tampil di awal dan membuka kerangka utama',
      (WidgetTester tester) async {
    await masukKeAplikasi(tester);

    // Navbar dengan 4 item + tombol tengah harus dirender.
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    // Beranda aktif sejak awal: judul AppBar menampilkan "Beranda".
    expect(find.text('Beranda'), findsWidgets);
  });

  testWidgets('Navbar berpindah tab saat item ditekan',
      (WidgetTester tester) async {
    await masukKeAplikasi(tester);

    // Label hanya muncul saat aktif, jadi tab Kuis ditekan lewat ikonnya.
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Kuis'), findsWidgets);
  });

  testWidgets('Label tombol tengah muncul saat aktif atau ditekan',
      (WidgetTester tester) async {
    await masukKeAplikasi(tester);

    // Beranda aktif -> tab tengah (Materi) tidak berlabel.
    expect(find.text('Materi'), findsNothing);

    // Tekan dan tahan tombol tengah -> label muncul.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.menu_book_rounded)),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Materi'), findsWidgets);

    // Batalkan tekanan (tanpa mengetuk) -> label kembali hilang.
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.text('Materi'), findsNothing);

    // Ketuk tombol tengah -> tab Materi aktif dan labelnya tampil menetap.
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Materi'), findsWidgets);
  });

  testWidgets('Item foto profil tidak menampilkan label',
      (WidgetTester tester) async {
    await masukKeAplikasi(tester);

    // Tab Profil di navbar memakai avatar, bukan ikon berlabel.
    expect(
      find.descendant(
        of: find.byType(AppBottomNavBar),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(find.text('Profil'), findsNothing); // tanpa label di navbar
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);
