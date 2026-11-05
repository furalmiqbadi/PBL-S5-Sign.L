// Smoke test untuk kerangka aplikasi Sign.L dan perilaku bottom navbar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sign_l/main.dart';
import 'package:sign_l/views/widgets/app_bottom_nav_bar.dart';

void main() {
  // Cegah pengunduhan font saat pengujian.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Aplikasi mulai di halaman login. Tekan "Masuk" untuk masuk ke kerangka
  // utama; autentikasi masih mock sehingga kredensial apa pun diterima.
  Future<void> masukKeAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(const SignLApp());
    expect(find.text('Masuk  →'), findsOneWidget);
    await tester.tap(find.text('Masuk  →'));
    await tester.pumpAndSettle();
  }

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
