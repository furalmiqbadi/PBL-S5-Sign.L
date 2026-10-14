import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/settings_controller.dart';
import 'views/auth/auth_views.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const SignLApp());
}

/// Root aplikasi Sign.L.
///
/// Menyediakan controller aplikasi lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal. Setelah autentikasi (masih mock, belum
/// terhubung database) user diarahkan ke kerangka utama `MainShell`.
class SignLApp extends StatelessWidget {
  final Widget? home;

  const SignLApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        // ..load() membaca preferensi tersimpan saat app dibuka
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sign.L',

        // Ukuran teks dari Pengaturan diterapkan ke seluruh aplikasi.
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

        theme: AppTheme.light,
        home: home ?? const LoginPage(),
      ),
    );
  }
}

// Backward-compatible name for default Flutter widget test runner.
class MyApp extends SignLApp {
  const MyApp({super.key, super.home});
}
