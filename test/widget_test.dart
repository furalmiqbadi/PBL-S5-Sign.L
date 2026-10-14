// Smoke test untuk kerangka aplikasi Sign.L, alur otentikasi, dan bottom navbar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sign_l/controllers/auth_controller.dart';
import 'package:sign_l/main.dart';
import 'package:sign_l/views/auth/auth_views.dart';
import 'package:sign_l/views/main_shell.dart';
import 'package:sign_l/views/widgets/app_bottom_nav_bar.dart';

Widget _createTestApp({Widget? home}) {
  return ChangeNotifierProvider(
    create: (_) => AuthController(),
    child: SignLApp(home: home),
  );
}

void main() {
  testWidgets('Halaman Login tampil secara default dengan input dan tombol',
      (WidgetTester tester) async {
    await tester.pumpWidget(_createTestApp());

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


  testWidgets('Navbar tampil dan berpindah tab saat item ditekan',
      (WidgetTester tester) async {
    await tester.pumpWidget(_createTestApp(home: const MainShell()));

    // Navbar dengan 4 item + tombol tengah harus dirender.
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    // Beranda aktif sejak awal: judul AppBar menampilkan "Beranda".
    expect(find.text('Beranda'), findsWidgets);

    // Label hanya muncul saat aktif, jadi tab Kuis ditekan lewat ikonnya.
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Kuis'), findsWidgets);
  });

  testWidgets('Label tombol tengah muncul saat aktif atau ditekan',
      (WidgetTester tester) async {
    await tester.pumpWidget(_createTestApp(home: const MainShell()));

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
    await tester.pumpWidget(_createTestApp(home: const MainShell()));

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
