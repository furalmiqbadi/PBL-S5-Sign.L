import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart'; // BARU
// import 'views/auth/auth_views.dart'; // [Kode Asli Tim-mu] Di-comment sementara selama DEV MODE preview Profil
import 'views/main_shell.dart';

// DIUBAH: provider dipindah ke dalam SignLApp (lihat di bawah).
void main() => runApp(const SignLApp());

class SignLApp extends StatelessWidget {
  const SignLApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFC40083);

    // BARU: MultiProvider membungkus MaterialApp agar semua halaman
    // (termasuk yang di-push via Navigator) bisa akses controller.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // ..load() membaca preferensi tersimpan saat app dibuka
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sign.L',

        // BARU: ukuran teks dari Pengaturan diterapkan ke seluruh aplikasi.
        builder: (context, child) {
          final scale = context.select<SettingsController, double>(
              (c) => c.settings.textSize.scale);
          final base = MediaQuery.textScalerOf(context).scale(1);
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(base * scale)),
            child: child!,
          );
        },

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          scaffoldBackgroundColor: const Color(0xFFFFF7FC),
          textTheme: GoogleFonts.nunitoTextTheme(),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFF0FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFF6D5EC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: primary, width: 1.3)),
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFB9A8B7)),
          ),
        ),
        // [DEV MODE] Sementara langsung buka MainShell (yang akan di set default ke Profil)
        home: const MainShell(),
      ),
    );
  }
}

// Backward-compatible name for the default Flutter widget test.
class MyApp extends SignLApp {
  const MyApp({super.key});
}